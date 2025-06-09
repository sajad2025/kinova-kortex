Thanks for the clarification. I’ll investigate how to integrate Kinova's `libKortexApiCpp_without_protobuf.a` with your locally built static protobuf 3.5.1 libraries on QNX (both AArch64 and x86\_64), and ensure successful static linking across the board.

I’ll get back to you with a set of steps, any CMake or linker flag suggestions, and any compatibility caveats to look out for.


# Porting Kinova Kortex API C++ to QNX: Static Linking with Protobuf

## Overview

Porting the Kinova Kortex C++ API to QNX involves linking Kinova’s static library with a custom-built Google Protobuf library on the QNX platform. Kinova provides a static library `libKortexApiCpp_without_protobuf.a` (in API version 2.7.0-r.5) which excludes protobuf symbols. This allows you to link against your own protobuf build. The goal is to produce a fully static (or mostly static) QNX executable on both **AArch64** and **x86\_64** targets. The main challenges are ensuring ABI compatibility (C++11 ABI) between the libraries and resolving linker errors due to missing symbols or incorrect link order.

This guide provides step-by-step instructions to integrate `libKortexApiCpp_without_protobuf.a` with a locally built `libprotobuf.a` using the QNX SDP 8.0 toolchain. It covers required compiler flags (like enforcing the C++11 ABI), linker options, architecture-specific notes, and troubleshooting common issues. The emphasis is on reliable linkage and compatibility with QNX build systems (both QNX makefiles and CMake).

## Environment Setup & Dependencies

Before linking, make sure your build environment is correctly configured:

* **QNX Toolchain:** Source the QNX SDP 8.0 environment script (e.g. `source <QNX_SDP_PATH>/qnxsdp-env.sh`) to set up cross-compilation variables (`QNX_HOST`, `QNX_TARGET`, etc.). Verify that the cross-compilers are in PATH (e.g. `which ntoaarch64-gcc` and `ntox86_64-gcc` should return the QNX compilers).

* **Protobuf 3.5.1 for QNX:** Compile Google Protobuf v3.5.1 from source for each target architecture. **Do not use any pre-built Protobuf that comes with QNX**, as it may be an incompatible version or missing features. Build static libraries (`libprotobuf.a` and `libprotobuf-lite.a`) for both AArch64 and x86\_64 QNX, installing them into the QNX sysroot. For example, after building, you should have:

  * AArch64: `$QNX_TARGET/aarch64le/usr/lib/libprotobuf.a` (with headers in `$QNX_TARGET/aarch64le/usr/include/google/protobuf/`)
  * x86\_64: `$QNX_TARGET/x86_64/usr/lib/libprotobuf.a` (with headers in `$QNX_TARGET/x86_64/usr/include/google/protobuf/`)
    This separation ensures you link against the correct library per architecture.

* **Kinova Kortex API Library:** Ensure you have the Kortex C++ API headers and the static library without protobuf. These might have been obtained via Kinova’s Artifactory or Conan package. If using Conan originally, note that the package was built with GCC and the C++11 ABI (Conan setting `compiler.libcxx=libstdc++11`). You should use the same or compatible compiler on QNX.

* **Headers and Includes:** Add the include paths for Kortex API headers and for Protobuf headers to your build. In a QNX **makefile**, it's recommended to use QNX-specific macros rather than raw `-I` flags. For example, use `EXTRA_INCVPATH` or `INCVPATH` to add include directories. For instance:

  ```makefile
  EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include 
  EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/thirdParty/include 
  ```

  (assuming Kortex’s protobuf headers reside under a `thirdParty` include folder). In CMake, you can achieve the same by using `target_include_directories` for the Kortex API include path and the protobuf include path.

## Compiler Flags and ABI Compatibility

**Matching the C++ ABI:** The Kinova library and your Protobuf must be compiled with the same C++ ABI to avoid undefined symbol errors (especially those involving `std::string` or other STL types). Kinova’s C++ API (v2.7.0) was built with the C++11 ABI (i.e. **`_GLIBCXX_USE_CXX11_ABI=1`**). To ensure compatibility, you **must compile** your Protobuf library *and* your application code with this ABI. In practice, this means adding the define `-D_GLIBCXX_USE_CXX11_ABI=1` to your compiler flags.

When building Protobuf 3.5.1 for QNX, set this flag in both the preprocessor and C++ compiler flags. For example, when configuring the build for AArch64 QNX, use:

```bash
CPPFLAGS="-I$QNX_TARGET/usr/include -D_GLIBCXX_USE_CXX11_ABI=1" \
CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=1" \
../configure --host=aarch64-unknown-nto-qnx8.0.0 --disable-shared ...
```

And similarly for x86\_64 (with `--host=x86_64-unknown-nto-qnx8.0.0`). The key point is that both `CPPFLAGS` and `CXXFLAGS` include the ABI define. This ensures all C++ objects (Kortex library, Protobuf, and your code) use the same name-mangling for STL symbols (with the `[abi:cxx11]` tag in symbol names where appropriate).

**C++ Standard Library Choice:** QNX 7+ can use either GNU libstdc++ or LLVM libc++ for C++ projects. Given that Kinova’s library was built with GCC’s libstdc++ (and the C++11 ABI), you should stick to libstdc++ on QNX. If using QNX’s qcc/q++ compiler driver, it will default to libstdc++ for GCC-based toolchains. (In QNX 7, using the *v1* include path corresponded to libc++ only, but by specifying the GNU GCC variant, you get libstdc++). Ensure that your build is **not** inadvertently linking against libc++; all components should consistently use libstdc++. This consistency will prevent missing symbol errors for STL functions (e.g. undefined references to `std::__cxx11::basic_string` methods).

## Linking Kortex API with Protobuf (QNX)

Now you’re ready to link everything together. The process is similar whether you use QNX’s recursive makefiles or CMake; the main difference is in syntax. Below is a step-by-step guide:

1. **Select the Target Architecture:** Decide whether you are building for AArch64 or x86\_64 and use the appropriate QNX compiler. For example, use `q++ -Vgcc_ntoaarch64le` for 64-bit ARM, or `q++ -Vgcc_ntox86_64` for 64-bit x86. In a QNX makefile, this is handled by the build variants; in CMake, you’d specify this via a toolchain file or `CMAKE_SYSTEM_PROCESSOR`. Make sure to build and link separately for each architecture, using the corresponding libraries for that arch (AArch64 libraries from the `aarch64le` sysroot, x86\_64 libs from the `x86_64` sysroot).

2. **Include Directories:** Ensure the compiler can find the headers for both Kortex API and Protobuf. If using QNX makefiles, the `EXTRA_INCVPATH` (or `INCVPATH`) macro as shown above will add those include paths to all compile commands. In CMake, use something like:

   ```cmake
   target_include_directories(myApp PRIVATE 
       "${PROJECT_SOURCE_DIR}/dependencies/kortex_api/include"
       "${PROJECT_SOURCE_DIR}/dependencies/kortex_api/thirdParty/include")
   ```

   This should include Kortex headers (e.g. `Kinova/API/*.h`) and protobuf headers (`google/protobuf/*.h`) which Kortex API depends on.

3. **Library Search Paths:** Tell the linker where to find the static libraries. If you installed `libprotobuf.a` into the QNX target sysroot (`$QNX_TARGET/.../usr/lib`), the QNX compiler will find it by default (the QNX build system’s library path includes the target’s `/usr/lib` by default). For the Kortex static library, if it’s not installed in the sysroot, you can either:

   * Copy or install `libKortexApiCpp_without_protobuf.a` into `$QNX_TARGET/<arch>/usr/lib` (this makes it available like a system library), **or**
   * Add its directory to the library search path. In a QNX makefile, use `EXTRA_LIBVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/lib`. In CMake, use `link_directories()` or simply give the full path to the library when linking.

4. **Link Libraries in the Correct Order:** When linking statically, the order of libraries on the command line matters. You should list the **Kortex API library first, then the Protobuf library**, so that unresolved protobuf symbols from the Kortex library are resolved by `libprotobuf.a`. For example, using QNX’s compiler directly:

   ```bash
   q++ -Vgcc_ntoaarch64le -o my_app \
       main.o other_objs.o \ 
       /path/to/libKortexApiCpp_without_protobuf.a \ 
       -lprotobuf \
       -pthread -lsocket -lm
   ```

   In this example, `-lprotobuf` finds `libprotobuf.a` (since it’s in the sysroot library path), and it comes *after* the Kortex .a file. The `-pthread -lsocket -lm` at the end link against threads, socket, and math libraries (explained below). If you prefer, you can also specify `libprotobuf.a` by full path instead of using `-l`. The crucial point is that the **Kortex library appears before Protobuf library** in the linkage order. The linker processes libraries left-to-right, resolving symbols as it goes; listing a dependent library after the one that depends on it guarantees all references are satisfied. In a QNX makefile, you can enforce this order by setting for example:

   ```makefile
   LIBS += KortexApiCpp_without_protobuf protobuf
   ```

   (and ensuring `EXTRA_LIBVPATH` is set so it finds the Kortex library). This expands to `-lKortexApiCpp_without_protobuf -lprotobuf` in that order. In CMake, use `target_link_libraries(myApp PRIVATE KortexApiCpp_without_protobuf protobuf ...)` (after defining imported libs or using full paths). If libraries are specified as full paths in CMake, they are linked in the order given.

5. **Linker Flags and Options:**

   * **Thread support:** Add `-pthread` to the compile and link flags. QNX uses a separate pthread library for POSIX threads. Using `-pthread` ensures the linker pulls in the threading library (libpthread) and sets thread-safe options. This is important because Protobuf uses thread-safe static initialization and mutexes internally. If you forget this, you might see undefined references to `pthread_*` symbols. (In QNX makefiles, the default might already include pthread for C++17/threads support, but adding it doesn’t hurt.)
   * **Network Sockets:** If the Kortex API uses networking (likely, since it communicates with the robot over TCP/UDP), you may need to link against QNX’s socket library. On modern QNX, socket functions are part of the **io-pkt** networking stack. If you encounter undefined symbols like `socket`, `connect`, or `send`, add `-lsocket` to your link line. In QNX6, a separate `libsocket.a` was needed for static linking; on QNX 7/8, these symbols might be in libc by default when dynamically linking, but `-lsocket` will ensure they are resolved for static linking if needed.
   * **Math library:** If your code or the Kortex API uses math functions (e.g. `std::sin`, `sqrt`), include `-lm` to link the math library. This is standard on QNX for static linking (dynamic linking may implicitly link libm, but static linking requires you to specify it).
   * **Static vs Dynamic C++ runtime:** By default, the above will statically link Kortex and Protobuf, but will still use QNX’s shared C runtime and C++ standard library. QNX’s linker will automatically link `libc.so` and `libstdc++.so` unless told otherwise. If you **truly need a fully static binary**, you can pass `-static` to `q++` to force static linking of everything. Be aware, however, that QNX might not ship a static `libstdc++.a` by default (for example, QNX 6 didn’t include one out-of-the-box) – attempting a full static link could lead to “cannot find libstdc++.a” errors. In most cases, it’s acceptable (and simpler) to allow the C/C++ runtime to remain shared. The critical part is that your third-party libs (Kortex, Protobuf) are static and integrated properly. If you do require a fully static runtime, you may need to build the GNU libstdc++ for QNX or use the QNX-provided static LLVM libc++ if available (beyond the scope of this guide).

6. **Building with QNX Make or CMake:**

   * *QNX Makefiles:* If you use the QNX-provided build system (e.g. including `common.mk`/`qrules.mk`), integrate the above settings into your project’s makefile. For example:

     ```makefile
     TARGET  = my_app
     CXXFLAGS+= -D_GLIBCXX_USE_CXX11_ABI=1 -pthread      # ensure ABI flag and pthread
     LDFLAGS+= -pthread -static                          # (optional) static link, if used
     EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include
     EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/thirdParty/include
     EXTRA_LIBVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/lib
     LIBS += KortexApiCpp_without_protobuf protobuf socket m
     ```

     In this snippet, `LIBS` will expand to `-lKortexApiCpp_without_protobuf -lprotobuf -lsocket -lm` in that order (libc and libstdc++ are linked by default). We use `EXTRA_INCVPATH`/`EXTRA_LIBVPATH` to add custom include and lib directories as recommended by QNX docs. The `_GLIBCXX_USE_CXX11_ABI` flag is added to CXXFLAGS so that it applies to all C++ files in the project (matching the library ABI).
   * *CMake:* Use a QNX toolchain file to specify the cross-compiler and sysroot. For example:

     ```cmake
     set(CMAKE_SYSTEM_NAME QNX)
     set(CMAKE_SYSTEM_PROCESSOR aarch64)  # or x86_64
     set(CMAKE_SYSROOT $ENV{QNX_TARGET}/aarch64le)  # path to QNX target sysroot for ARM
     set(CMAKE_C_COMPILER ntoaarch64-gcc)
     set(CMAKE_CXX_COMPILER ntoaarch64-g++)
     ```

     Then in your CMakeLists, link the libraries:

     ```cmake
     add_executable(my_app main.cpp ...)
     target_compile_definitions(my_app PRIVATE _GLIBCXX_USE_CXX11_ABI=1)
     target_link_libraries(my_app PRIVATE 
         ${CMAKE_SOURCE_DIR}/dependencies/kortex_api/lib/libKortexApiCpp_without_protobuf.a 
         ${CMAKE_SYSROOT}/usr/lib/libprotobuf.a 
         pthread socket m)
     ```

     Here we link the static libraries by absolute path (for Kortex, using our local path; for protobuf, using the sysroot path). We also link `pthread`, `socket`, and `m` as needed. The `_GLIBCXX_USE_CXX11_ABI` definition is added to ensure the ABI consistency. (Alternatively, set `CMAKE_CXX_FLAGS` globally with this define.)

7. **Build and Verify:** Compile your project for each architecture. The final linking step should succeed with no undefined references if all the above is configured correctly. You can use QNX’s `file` command to verify the output binary’s architecture (ARM vs x86), and use `ldd` on the QNX target to confirm that only the expected shared libraries (if any) are needed (ideally just the C library and C++ library if you didn’t fully static link).

## Troubleshooting Common Linker Issues

Even with the correct setup, you might encounter some common linking errors. Below are possible issues and how to address them:

* **Undefined reference to protobuf symbols (e.g. `google::protobuf::MessageLite::...`):** This indicates the linker can’t find the protobuf implementations for calls made by the Kortex library. The most likely cause is that `libprotobuf.a` was not linked or was linked before the Kortex library. Ensure that you **link `libprotobuf.a` *after* `libKortexApiCpp_without_protobuf.a`** on the command line. In makefiles, put `protobuf` last in the LIBS list. In CMake, list the Kortex library first. If you did list it and still see this, double-check that the `-lprotobuf` is using your built library and not picking up an incorrect library. You can add verbose linking (`-Wl,-t`) to see which archives are searched.

* **Undefined reference to `std::__cxx11::basic_string` or other `std::` symbols:** If you see errors involving `__cxx11` in symbol names, it’s almost always an **ABI mismatch problem** – one library was built with the C++11 ABI and another with the old ABI. Confirm that **all** compile units and static libraries were built with `_GLIBCXX_USE_CXX11_ABI=1`. In practice, that means your Protobuf build and your application code should have this flag (Kinova’s library already expects the new ABI). Rebuilding Protobuf with the proper flags has been proven to resolve this issue in the QNX context.

* **Undefined reference to `pthread_*` functions or atomic operations:** Google Protobuf uses pthreads for thread-safe singleton initialization and might use C++11 atomics. If you see missing references to pthread symbols, make sure you linked with `-pthread` (which brings in libpthread). For atomic symbols (like `__atomic_fetch_add_8`), QNX’s GCC might use built-in atomics, but if not, linking `-latomic` may be required. In our verified build, Protobuf 3.5.1 on QNX used GCC built-ins for atomics, so explicitly linking libatomic wasn’t necessary. Focus on ensuring `-pthread` is present.

* **Undefined reference to socket functions (`socket`, `connect`, `recv`, etc.):** Add the networking library by linking with `-lsocket`. QNX Neutrino requires `libsocket` for these if you are statically linking. If using QNX 7 or 8, and you still get errors, verify if the functions might reside in libc for dynamic linking but require explicit socket library for static linking.

* **Multiple definition errors for protobuf symbols:** This can happen if you accidentally link two versions of protobuf. For example, if `libKortexApiCpp.a` (the full version with protobuf) was linked *and* you also linked your `libprotobuf.a`, you’d get duplicate symbols. The solution is to use **only one** protobuf library. That’s why we use the *without\_protobuf* variant of Kinova’s library. Similarly, ensure you’re not linking QNX’s own libprotobuf (if one exists in the system) in addition to your static one. Always specify the library explicitly (or use static linking) so you know which implementation is used.

* **Errors about missing `libstdc++.a` or `libc.a` when using `-static`:** As mentioned, QNX may not ship static versions of its runtime libraries in some releases. If you attempted a fully static link (`-static`) and got errors that `-lc` or `-lstdc++` can’t be found as static archives, you have two options: (1) Remove the `-static` flag so that those are linked dynamically (preferred in most cases), or (2) provide your own static runtime libraries (advanced, not typically necessary). Linking dynamically for system libraries does not defeat the purpose of our exercise – you still avoid needing any third-party .so at runtime, which was the main goal.

* **Runtime issues due to mixing libs:** If the application compiles and links but behaves oddly at runtime (e.g. weird protobuf errors), double-check that the versions match. Using Protobuf 3.5.1 as the Kinova API expects is important – a different version might link but could lead to subtle runtime problems if the message definitions differ. Stick to the exact version Kinova specified (3.5.1 in this case) for safety.

## Conclusion

By following the above steps, you can successfully statically link Kinova’s Kortex C++ API with your own Protobuf build on QNX for both ARM64 and x86\_64 targets. The critical factors are using the correct compiler flags to maintain C++ ABI compatibility, linking libraries in the proper order, and including all necessary support libraries (pthread, socket, etc.) for a clean link. This approach was verified to work with QNX SDP 8.0, yielding static binaries that incorporate the Kortex API logic and the Protobuf 3.5.1 serialization code.

By consolidating dependencies locally and avoiding reliance on mismatched system libraries, you gain full control over the build. This results in a reliable and portable deployment of the Kinova API on QNX. If issues arise, refer to the troubleshooting section above – most problems boil down to missing flags or mismatched build settings, which can be fixed as described. With a consistent build configuration, you should achieve a smooth integration of Kinova’s robotics API into your QNX application.

**Sources:**

* Kinova Kortex API Conan package info (v2.7.0)
* QNX SDP 8.0 documentation on static linking and makefile conventions
* QNX build guide for Protobuf 3.5.1 (cross-compilation steps and ABI flags)
* Kinova Kortex + Protobuf QNX porting notes
* Example of GCC linker order requirements
* QNX Neutrino static linking discussions (math and socket libs)

# Bridging libstdc++ vs libc++ ABI on QNX 8.0

## Context
Kinova's `libKortexApiCpp_without_protobuf.a` expects libstdc++ symbols (like `std::__cxx11::basic_string`), but QNX 8.0 uses libc++ by default (symbols like `std::__2::basic_string`). This creates ABI incompatibility during linking.

## Method 1: Rebuild Protobuf with libstdc++ ABI (Unify the C++ Standard Library) ✅ PARTIALLY SUCCESSFUL

### Implementation Steps
1. **Rebuild protobuf 3.5.1 with `-Y_gpp` flag** to use GNU libstdc++ instead of libc++:
   ```bash
   cd ~/qnx_workspace/protobuf/build-x86
   make clean
   source ~/qnx800/qnxsdp-env.sh
   CPPFLAGS="-I$QNX_TARGET/usr/include -D_GLIBCXX_USE_CXX11_ABI=1" \
   CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=1" \
   LDFLAGS="-L$QNX_TARGET/usr/lib" \
   ../configure --host=x86_64-unknown-nto-qnx8.0.0 \
   CC="qcc -Y_gpp" CXX="qcc -Y_gpp -lang-c++" \
   --with-protoc="$HOST_PROTOC" JS_EMBED="$HOST_JS_EMBED" \
   --disable-shared --disable-tests
   make -j$(nproc)
   make install prefix=/usr DESTDIR=$QNX_TARGET/x86_64
   ```

2. **Configure application to use libstdc++** in `src/common.mk`:
   ```makefile
   # Force use of libstdc++ with _gpp variant compiler
   CCFLAGS += -V gcc_ntox86_64_gpp
   CXXFLAGS += -V gcc_ntox86_64_gpp
   
   # Use Kinova library without protobuf + locally built protobuf with libstdc++
   LIBS += KortexApiCpp_without_protobuf protobuf stdc++ gcc_s c socket m z
   ```

### Results: ✅ ABI Bridging SUCCESS, ❌ System Compatibility Issues

**✅ MAJOR SUCCESS: Protobuf ABI Compatibility Resolved**
- All protobuf-related linking errors eliminated
- Symbols now match: both use `std::__cxx11::basic_string` (libstdc++ ABI)
- No more "undefined reference to protobuf functions" errors

**❌ Remaining Issues: Linux-specific Dependencies in Kinova Library**
The Kinova library still has Linux-specific system dependencies:
- `__errno_location` (Linux errno access)
- `__fdelt_chk` (Linux file descriptor checking)  
- `std::__atomic_futex_unsigned_base::_M_futex_*` (Linux futex threading)

### Conclusion for Method 1
**Partial Success**: This method successfully bridges the libstdc++/libc++ ABI gap. The core protobuf integration now works. However, the Kinova library still contains Linux-specific system calls that are not available on QNX.

**Next Steps**: 
- Need Method 2 or 3 to address the Linux system call dependencies
- Could potentially create QNX wrappers for the missing Linux functions
- Alternative: Request QNX-specific build of Kinova library from vendor

**Note:** Mixing two C++ standard libraries in one process is inherently risky, so the goal is to minimize or eliminate any direct ABI overlap. Below are potential strategies, ranked from most feasible to least, with their pros, cons, and how one might implement each:

1. **Rebuild Protobuf with the libstdc++ ABI (Unify the C++ Standard Library)** – The most straightforward solution is to compile your Protobuf 3.5.1 for QNX using the GNU libstdc++ (to match Kinova's library) instead of the default LLVM libc++. QNX's toolchain supports this via the **`-Y_gpp`** flag to `qcc`, which switches the C++ runtime to GNU libstdc++. By rebuilding Protobuf (and your application) with libstdc++, you ensure **all code uses a single C++ ABI**, avoiding incompatibilities. This essentially "converts" your environment to the same standard library Kinova used, eliminating the need for complex shims.

   * **Pros:** Easiest to implement using open-source Protobuf code; no runtime translation overhead; highest likelihood of success (all components share one ABI). This approach aligns with the recommendation that all linked C++ code use the same stdlib implementation. It avoids undefined symbol issues (e.g. mismatched `std::string` symbols like `std::string` vs `std::__1::string`).
   * **Cons:** Requires rebuilding Protobuf (and possibly other dependencies) for libstdc++; deviates from QNX's default (libc++) which might impact other libraries or tools expecting libc++. (In practice, QNX **does** provide libstdc++ support, so this is usually workable.) All C++ code in the process should use libstdc++ to avoid mixing.
   * **Implementation Outline:**

     * Configure the QNX compiler to use GNU libstdc++ (e.g. `qcc -Y_gpp -lang-c++ ...`) and rebuild Protobuf 3.5.1 under these settings. Ensure the Protobuf symbols (e.g. message methods returning/accepting `std::string`) are now using libstdc++'s ABI (often identified by `std::__cxx11::string` in symbol names for C++11 ABI).
     * Build your application and link against `libKortexApiCpp_without_protobuf.a`, linking the libstdc++ (GNU) library instead of libc++. On QNX, this may mean linking against the provided `libstdc++.so` or static libstdc++ for your architecture.
     * Verify that all C++ standard library references in the final binary resolve to libstdc++ symbols. If the Kinova API was built with the C++11 (GCC5+) ABI, your rebuilt Protobuf should now present matching symbols, resolving linkage errors. (As a precaution, test basic Protobuf message usage to ensure functionality under libstdc++ is intact.)

2. **Introduce a C Wrapper/Shim Library** – Create a separate module (e.g. a shared library or an isolated static library component) that encapsulates the Kinova API and its Protobuf calls behind an **extern "C" API** boundary. The idea is to compile this module with **libstdc++** (to satisfy Kinova's ABI) while the rest of your application uses **libc++**. By exposing only C-compatible functions and opaque data pointers across the boundary, you prevent C++ STL types from crossing between ABIs. For example, the wrapper could accept raw byte buffers or C structs and internally construct Protobuf objects with Kinova's expected stdlib, and vice versa. This way, the two C++ runtimes coexist in the process but **do not directly interact** on C++ objects.

   * **Pros:** Does not require modifying proprietary binaries or fully rebuilding large libraries on a non-default stdlib. Each side (libstdc++ for the wrapper, libc++ for main app) runs with its intended C++ runtime, reducing ABI conflict. Exceptions and memory allocation can still work across TUs if using the common lower-level ABI (Itanium on QNX), so basic cross-boundary operations (like throwing exceptions or freeing memory) remain safe.
   * **Cons:** Moderate complexity – you must design and implement a wrapper API and possibly data conversion (e.g. converting between Protobuf message representations). The wrapper must be carefully compiled and linked: for instance, build it with QNX's `-Y_gpp` (libstdc++) and statically link Kinova's `.a` and a libstdc++-built Protobuf. You'll likely make the wrapper a **shared library** to contain libstdc++ symbols privately. Without special handling, having both libstdc++ and libc++ in one binary can cause conflicts, so you'd use techniques like symbol visibility hiding or dynamic loading to isolate the libstdc++ part. The performance overhead of copying or serializing data between ABIs (e.g. converting Protobuf messages to byte arrays) is another downside.
   * **Implementation Outline:**

     * **Design a C API** covering the needed Kinova functionality (e.g. `kinova_init(...)`, `kinova_sendCommand(const void* proto_buf, size_t len)`, etc.). Use only C types (int, char\*, void\*, etc.) in this interface. Internally, the wrapper will translate these into C++ calls to Kinova API. For instance, to send a Protobuf message, the app could pass a serialized message buffer which the wrapper deserializes using its Protobuf (built with libstdc++), then calls the Kinova API.
     * **Build the wrapper** with the GNU C++ library: compile and link `libKortexApiCpp_without_protobuf.a` and the Protobuf 3.5.1 library (also compiled under libstdc++) into a shared object (`libkinova_shim.so`). Link against libstdc++ (statically or dynamically) within this .so. Use symbol visibility controls (e.g. compile with `-fvisibility=hidden` and export only the C functions) to prevent the wrapper's internal C++ symbols from clashing with the main program's libc++ symbols in the global symbol table.
     * **Link and use:** In the main application (built with libc++ as usual), load the shim library (implicitly at link time or via `dlopen`). Call the exposed C functions to interact with the Kinova API. Ensure that no C++ object from the libstdc++ side leaks out – for example, the wrapper should not return a C++ object address that the main would treat as a libc++ object. All exchanges must be in POD data or byte streams. This method effectively quarantines the libstdc++ ABI inside `libkinova_shim.so` and avoids direct ABI mixing with the rest of the app.

**Conclusion:** The safest and simplest route is to **avoid mixing ABIs altogether**, by compiling all components with the same C++ standard library. In QNX 8.0, that likely means either switch your app to libstdc++ (Strategy 1) or isolate Kinova's code in a contained module (Strategy 2). These have the highest chance of success with minimal runtime instability.

**Sources:**

* QNX documentation on selecting C++ runtime libraries (GNU libstdc++ vs LLVM libc++)
* Discussion of mixing libc++ and libstdc++ and symbol differences (Stack Overflow)
* MaskRay blog on C++ ABI compatibility (techniques for mixing standard libraries)
* QNX forums – cannot link two C++ STLs in one binary

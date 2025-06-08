# Dependencies

## Primary Dependencies (Conan-managed)

**Location**: `/home/factiondev/.conan/data/kortex_api_cpp/2.7.0-r.5/kortex/stable/package/c023db9fc677d4d0b3bd0c20f71385e4cf8a1220/`

- **`include/`** - Kortex API C++ headers (client, client_stubs, common, messages, server, server_stubs)
- **`lib/`** - Static libraries
  - `libKortexApiCpp.a` (25MB - with protobuf)
  - `libKortexApiCpp_without_protobuf.a` (17MB - without protobuf)
- **`thirdParty/include/google/protobuf/`** - Protobuf 3.5.1 headers
- **`cmake/`** - CMake configuration files

## Local Project Dependencies

**Location**: `api_cpp/examples/thirdParty/`

- **`conan.cmake`** - Conan integration helper for CMake
- **`cxxopts/`** - Command-line argument parsing library

## Build Configuration Files

**Location**: `api_cpp/examples/build-gcc-release/` (build directory)

- **`conanfile.txt`** - Conan dependency specification
- **`conaninfo.txt`** - Resolved dependency information
- **`conanbuildinfo.cmake`** - CMake integration file
- **`conan.lock`** - Dependency lock file

## System-wide Conan Cache

**Location**: `/home/factiondev/.conan/`

- Downloaded packages and metadata
- Package: `kortex_api_cpp/2.7.0-r.5@kortex/stable`
- Protobuf version: 3.5.1 (bundled) 
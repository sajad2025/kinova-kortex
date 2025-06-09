# Consolidated Kinova Kortex C++ Dependencies (no need for Conan) 

## New Approach - Consolidated Local Dependencies

### Local Dependencies (Current Setup)

| Component | Version | Size | Location | Description |
|-----------|---------|------|----------|-------------|
| **Kortex API C++** | 2.7.0-r.5 | ~41MB | `dependencies/kortex_api/` | Complete Kinova API |
| **Protobuf Headers** | 3.5.1 | ~2MB | `dependencies/kortex_api/thirdParty/` | Message serialization |
| **cxxopts** | Latest | ~50KB | `dependencies/cxxopts/` | Command-line parsing |

### Libraries Included
- `libKortexApiCpp.a` (25MB) - Full API with protobuf
- `libKortexApiCpp_without_protobuf.a` (17MB) - API without protobuf

## Legacy - Conan Managed Integration

### Legacy - Conan Integration Details
```cmake
# Original Conan configuration
conan_cmake_run(REQUIRES kortex_api_cpp/2.7.0-r.5@kortex/stable
                SETTINGS kortex_api_cpp:compiler=gcc
                SETTINGS kortex_api_cpp:compiler.version=5
                SETTINGS compiler.libcxx=libstdc++11
                PROFILE_AUTO build_type
                BASIC_SETUP
                UPDATE)
```

### Legacy - Original Conan Dependencies
When using Conan, dependencies were managed from:
- **Conan cache location**: `/home/factiondev/.conan/data/kortex_api_cpp/2.7.0-r.5/kortex/stable/package/c023db9fc677d4d0b3bd0c20f71385e4cf8a1220/`
- **Artifactory server**: [Kinova Artifactory](https://artifactory.kinovaapps.com/ui/repos/tree/General/generic-public/kortex/API/2.6.0/)

**Location**: `/home/factiondev/.conan/data/kortex_api_cpp/2.7.0-r.5/kortex/stable/package/c023db9fc677d4d0b3bd0c20f71385e4cf8a1220/`

- **`include/`** - Kortex API C++ headers (client, client_stubs, common, messages, server, server_stubs)
- **`lib/`** - Static libraries
  - `libKortexApiCpp.a` (25MB - with protobuf)
  - `libKortexApiCpp_without_protobuf.a` (17MB - without protobuf)
- **`thirdParty/include/google/protobuf/`** - Protobuf 3.5.1 headers
- **`cmake/`** - CMake configuration files

### Legacy - Local Project Dependencies

**Location**: `api_cpp/examples/thirdParty/`

- **`conan.cmake`** - Conan integration helper for CMake
- **`cxxopts/`** - Command-line argument parsing library

### Legacy - Build Configuration Files

**Location**: `api_cpp/examples/build-gcc-release/` (build directory)

- **`conanfile.txt`** - Conan dependency specification
- **`conaninfo.txt`** - Resolved dependency information
- **`conanbuildinfo.cmake`** - CMake integration file
- **`conan.lock`** - Dependency lock file

## Reference

| Resource | URL |
|----------|-----|
| **Google Protobuf C++ Reference** | https://developers.google.com/protocol-buffers/docs/reference/cpp-generated |
| **Conan Installation** | https://docs.conan.io/en/latest/installation.html |
| **Kinova Artifactory** | https://artifactory.kinovaapps.com/ui/repos/tree/General/generic-public/kortex/API/2.6.0/ |
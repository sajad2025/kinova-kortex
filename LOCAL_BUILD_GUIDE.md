# Building Kinova Kortex with Local Dependencies

This guide explains how to build the Kinova Kortex C++ examples using consolidated local dependencies in the `dependencies` folder, without requiring Conan or external package management.

## Overview

The project has been configured to use local dependencies stored in `dependencies/kortex_api/` instead of fetching them through Conan. This approach provides:

- **No external dependencies**: Everything needed is included locally
- **Offline builds**: No internet connection required after initial setup
- **Version consistency**: Exact control over library versions
- **Simplified deployment**: Easy to package and distribute

## Directory Structure

```
kinova-kortex/
├── dependencies/                     # All dependencies (local)
│   ├── conan.cmake                   # CMake helper (existing)
│   ├── cxxopts/                     # Command-line parsing (existing) 
│   └── kortex_api/                  # Kortex API (copied from Conan)
│       ├── include/                 # Kortex API headers
│       │   ├── client/
│       │   ├── client_stubs/
│       │   ├── common/
│       │   ├── messages/
│       │   └── server_stubs/
│       ├── lib/                     # Static libraries
│       │   ├── libKortexApiCpp.a
│       │   └── libKortexApiCpp_without_protobuf.a
│       ├── thirdParty/              # Protobuf headers
│       │   └── include/
│       │       └── google/
│       │           └── protobuf/
│       └── cmake/                   # CMake configuration files
├── src/                             # All source files
│   ├── utilities.h                  # Utility functions
│   ├── utilities.cpp                # Utility functions implementation
│   ├── 01-api_creation.cpp         # Example source files
│   ├── 02-protobuf_object...cpp
│   └── ...                         # All other example .cpp files
├── CMakeLists.txt                   # Modified to use local dependencies
├── build-local.sh                   # Build script for local dependencies
└── ...
```

## Setup Instructions

### 1. Copy Dependencies (Already Done)

The required dependencies have been copied from the Conan cache to `dependencies/kortex_api/`:

```bash
# This was already executed:
cp -r /home/factiondev/.conan/data/kortex_api_cpp/2.7.0-r.5/kortex/stable/package/c023db9fc677d4d0b3bd0c20f71385e4cf8a1220/* dependencies/kortex_api/
```

### 2. CMakeLists.txt Configuration

The `CMakeLists.txt` has been modified to:
- Set `USE_CONAN=OFF` by default
- Point to `dependencies/kortex_api/` instead of `kortex_api/`
- Look for source files in `src/` directory
- Include utilities from `src/` directory
- Skip automatic downloads

Key changes:
```cmake
# Include paths updated to use dependencies folder
include_directories(${PROJECT_SOURCE_DIR}/dependencies/cxxopts/)
include_directories(${PROJECT_SOURCE_DIR}/src/)

# Use dependencies directory for conan.cmake
include(${PROJECT_SOURCE_DIR}/dependencies/conan.cmake)

# Look for examples in src directory
file(GLOB EXE_LIST RELATIVE ${PROJECT_SOURCE_DIR}/src "[0-9]*.cpp")

# Build with utilities from src directory
add_executable(${TARGET_EXE_NAME} src/${SRC_FILE} src/utilities.cpp)
```

## Building

### Option 1: Using the Build Script (Recommended)

```bash
# Build in Release mode (default)
./build-local.sh

# Build in Debug mode
./build-local.sh Debug
```

### Option 2: Manual Build

```bash
# Create build directory
mkdir build-local-release
cd build-local-release

# Configure with CMake
cmake .. -DCMAKE_BUILD_TYPE=Release -DUSE_CONAN=OFF -DDOWNLOAD_API=OFF

# Build all examples
make -j$(nproc)

# Or build a specific example
make 000-Getting_started_01-api_creation
```

## Running Examples

After building, executables are located in the build directory:

```bash
cd build-local-release
./000-Getting_started_01-api_creation
```

## Advantages of This Approach

1. **Self-contained**: No external dependencies or package managers required
2. **Consistent**: Same library versions across all builds
3. **Portable**: Easy to package and distribute the entire project
4. **Offline-capable**: No internet connection needed for builds
5. **Faster builds**: No dependency resolution or downloading time
6. **Version control friendly**: All dependencies can be committed to git if desired

## Dependencies Included

- **Kortex API C++ 2.7.0-r.5**: Complete API with headers and static libraries
- **Protobuf 3.5.1**: Headers included for message serialization
- **cxxopts**: Command-line argument parsing (already present)

## Troubleshooting

### Build Fails with Missing Headers
Ensure all directories are copied correctly:
```bash
ls -la dependencies/kortex_api/
# Should show: include/, lib/, thirdParty/, cmake/
```

### Linking Errors
Check that the static libraries are presente:
```bash
ls -la dependencies/kortex_api/lib/
# Should show: libKortexApiCpp.a, libKortexApiCpp_without_protobuf.a
```

### CMake Configuration Issues
Verify CMake is using local dependencies:
```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DUSE_CONAN=OFF -DDOWNLOAD_API=OFF
# Should show paths pointing to dependencies/kortex_api/
```

## Migration from Conan

If you want to revert to using Conan:

```bash
cmake .. -DCMAKE_BUILD_TYPE=Release -DUSE_CONAN=ON
```

The CMakeLists.txt still supports both approaches. 
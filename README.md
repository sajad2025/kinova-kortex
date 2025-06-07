# Kinova Kortex API C++ Examples

This repository contains C++ examples for the Kinova Kortex API with multi-architecture protobuf support.

## Project Structure

```
.
├── install_protobuf.sh  # Script to install protobuf from QNX builds
├── build.sh             # Script to build the examples
├── CMakeLists.txt       # CMake configuration
├── examples/            # Example code
└── thirdParty/          # Third-party dependencies
    ├── protobuf/        # Multi-architecture protobuf installation
    │   ├── include/     # Protobuf headers (shared)
    │   ├── host/        # Host libraries and tools
    │   ├── x86/         # x86 target libraries
    │   └── aarch64/     # aarch64 target libraries
    └── kortex_api/      # Kortex API
```

## Protobuf Architecture Support

This project supports multiple target architectures:
- **host**: For development and testing on your local machine
- **x86**: For x86 target deployments
- **aarch64**: For ARM64 target deployments

The protobuf libraries are automatically selected based on your target architecture.

## Build Instructions

### Step 1: Install Required Tools
```bash
sudo apt-get install autoconf automake libtool curl make g++ unzip cmake
```

### Step 2: Install Protobuf Dependencies
```bash
# Install protobuf from pre-built QNX workspace
./install_protobuf.sh
```

This script copies pre-built protobuf libraries from your QNX workspace at:
- `/home/factiondev/qnx_workspace/protobuf/build-host/`
- `/home/factiondev/qnx_workspace/protobuf/build-x86/`
- `/home/factiondev/qnx_workspace/protobuf/build-aarch64/`

### Step 3: Build the Examples

#### Simple Build (auto-detect architecture)
```bash
./build.sh
```

#### Build for Specific Architecture
```bash
./build.sh host      # Build for host development
./build.sh x86       # Build for x86 target
./build.sh aarch64   # Build for aarch64 target
```

#### Build with Debug Symbols
```bash
./build.sh host Debug
./build.sh x86 Debug
./build.sh aarch64 Debug
```

### Step 4: Run Examples
```bash
# After building, executables are in architecture-specific directories:
cd build-host       # or build-x86, build-aarch64
./00-general_001-api_creation
```

## Notes

- The `thirdParty/protobuf/` directory contains pre-built protobuf libraries for multiple architectures.
- This directory is not tracked in git and should be installed using `./install_protobuf.sh`.
- The build system automatically selects the correct protobuf library based on your target architecture.
- If you get a CMake error about missing protobuf, make sure you've run `./install_protobuf.sh` first.

## Troubleshooting

### CMake Error: Protobuf library not found
```bash
# Run the installation script
./install_protobuf.sh

# Verify installation
ls -la thirdParty/protobuf/
```

### Build Error: Wrong Architecture
```bash
# Check available architectures
ls -la thirdParty/protobuf/
# Should show: host/ x86/ aarch64/

# Build for specific architecture
./build.sh host
```

### Clean Build
```bash
# Remove build directories
rm -rf build-*

# Rebuild
./build.sh
``` 
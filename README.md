## Project Structure

```
.
├── build_protobuf.sh     # Script to build protobuf
├── build.sh             # Script to build the examples
├── CMakeLists.txt       # CMake configuration
├── examples/            # Example code
└── thirdParty/          # Third-party dependencies
    ├── protobuf-3.5.1/  # Protobuf source code
    └── kortex_api/      # Kortex API
```

## Notes

- The `thirdParty/protobuf-3.5.1-local` directory is created during the protobuf build process and contains the compiled protobuf library.
- This directory is not tracked in git and should be rebuilt on each system.
- If you get a CMake error about missing protobuf, make sure you've run `build_protobuf.sh` first. 

# Build Instructions

## Step 1: Install Required Tools
```bash
sudo apt-get install autoconf automake libtool curl make g++ unzip
```

## Step 2: Build Protobuf
```bash
# Make the build script executable
chmod +x build_protobuf.sh

# Build protobuf
./build_protobuf.sh
```

## Step 3: Build the Project
```bash
# Build using the build script
./build.sh
```

The executables will be created in the `build` directory. 
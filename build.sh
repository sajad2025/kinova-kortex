#!/bin/bash

# Simple build script for Kortex API examples (local dependencies only)

# Create build directory if it doesn't exist
mkdir -p build
cd build

# Configure with CMake
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build with Make
make -j$(nproc)

cd ..
echo "Build completed successfully!" 
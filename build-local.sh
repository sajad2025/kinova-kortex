#!/bin/bash

# Simple build script for Kinova Kortex examples

set -e

BUILD_DIR="build"

echo "Building Kinova Kortex examples..."

# Create and enter build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure and build
echo "Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "Building all examples..."
make -j$(nproc)

echo "Build completed successfully!"
echo "Executables are located in: $BUILD_DIR/" 
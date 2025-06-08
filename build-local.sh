#!/bin/bash

# Build script for Kinova Kortex examples using local dependencies
# This script builds the project without requiring Conan or external dependencies

set -e

BUILD_TYPE=${1:-Release}
BUILD_DIR="build-local-${BUILD_TYPE,,}"

echo "Building Kinova Kortex examples with local dependencies..."
echo "Build type: $BUILD_TYPE"
echo "Build directory: $BUILD_DIR"

# Create and enter build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo "Configuring with CMake..."
cmake .. \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DUSE_CONAN=OFF \
    -DDOWNLOAD_API=OFF

# Build all targets
echo "Building all examples..."
make -j$(nproc)

echo "Build completed successfully!"
echo "Executables are located in: $BUILD_DIR/"
echo ""
echo "To run an example:"
echo "  cd $BUILD_DIR"
echo "  ./000-Getting_started_01-api_creation" 
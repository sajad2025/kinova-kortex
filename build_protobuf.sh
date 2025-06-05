#!/bin/bash

# Exit on error
set -e

# Define directories
PROTOBUF_SRC_DIR="thirdParty/protobuf-3.5.1"
PROTOBUF_LOCAL_DIR="thirdParty/protobuf-3.5.1-local"

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$PROTOBUF_LOCAL_DIR"
if [ -d "$PROTOBUF_SRC_DIR" ]; then
    cd "$PROTOBUF_SRC_DIR"
    if [ -f "Makefile" ]; then
        make clean || true
    fi
fi

# Configure and build
echo "Configuring protobuf..."
./configure --prefix="$(pwd)/../protobuf-3.5.1-local" --disable-shared

echo "Building protobuf..."
make -j$(nproc)

echo "Installing protobuf..."
make install

echo "Protobuf build complete!" 
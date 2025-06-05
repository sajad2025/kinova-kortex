#!/bin/bash

# Exit on error
set -e

# Define directories
PROTOBUF_ARCHIVE="thirdParty/protobuf-cpp-3.5.1.tar.gz"
PROTOBUF_SRC_DIR="thirdParty/protobuf-3.5.1"
PROTOBUF_LOCAL_DIR="thirdParty/protobuf-3.5.1-local"

# Check if protobuf archive exists
if [ ! -f "$PROTOBUF_ARCHIVE" ]; then
    echo "Error: $PROTOBUF_ARCHIVE not found!"
    exit 1
fi

# Clean previous build and extract
echo "Cleaning previous build and extracting protobuf..."
rm -rf "$PROTOBUF_SRC_DIR" "$PROTOBUF_LOCAL_DIR"
tar -xzf "$PROTOBUF_ARCHIVE" -C "thirdParty"

# Configure and build
echo "Configuring protobuf..."
cd "$PROTOBUF_SRC_DIR"
./configure --prefix="$(pwd)/../protobuf-3.5.1-local" --disable-shared

echo "Building protobuf..."
make -j$(nproc)

echo "Installing protobuf..."
make install

echo "Protobuf build complete!" 
#!/bin/bash

# Build script for Kortex API examples with multi-architecture protobuf support
# Usage: ./build.sh [ARCHITECTURE] [BUILD_TYPE]
#   ARCHITECTURE: host, x86, aarch64 (default: auto-detect)
#   BUILD_TYPE: Release, Debug (default: Release)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Kortex API Examples Build Script ===${NC}"

# Parse command line arguments
TARGET_ARCH=${1:-"auto"}
BUILD_TYPE=${2:-"Release"}

# Auto-detect architecture if not specified
if [ "$TARGET_ARCH" = "auto" ]; then
    case "$(uname -m)" in
        x86_64|AMD64)
            TARGET_ARCH="host"
            ;;
        i386|i686)
            TARGET_ARCH="x86"
            ;;
        aarch64|arm64)
            TARGET_ARCH="aarch64"
            ;;
        *)
            TARGET_ARCH="host"
            echo -e "${YELLOW}Warning: Unknown architecture $(uname -m), defaulting to host${NC}"
            ;;
    esac
fi

echo -e "${BLUE}Target Architecture: ${TARGET_ARCH}${NC}"
echo -e "${BLUE}Build Type: ${BUILD_TYPE}${NC}"

# Verify protobuf installation
PROTOBUF_DIR="thirdParty/protobuf"
PROTOBUF_LIB="${PROTOBUF_DIR}/${TARGET_ARCH}/lib/libprotobuf.a"
PROTOBUF_PROTOC="${PROTOBUF_DIR}/host/bin/protoc"

if [ ! -f "$PROTOBUF_LIB" ]; then
    echo -e "${RED}Error: Protobuf library not found at $PROTOBUF_LIB${NC}"
    echo -e "${YELLOW}Please run: ./install_protobuf.sh${NC}"
    echo -e "${YELLOW}Available architectures in $PROTOBUF_DIR:${NC}"
    if [ -d "$PROTOBUF_DIR" ]; then
        ls -1 "$PROTOBUF_DIR" | grep -E "^(host|x86|aarch64)$" | sed 's/^/  - /'
    fi
    exit 1
fi

if [ ! -f "$PROTOBUF_PROTOC" ]; then
    echo -e "${RED}Error: Protobuf compiler not found at $PROTOBUF_PROTOC${NC}"
    echo -e "${YELLOW}Please run: ./install_protobuf.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Protobuf installation verified${NC}"
echo -e "  Library: $PROTOBUF_LIB"
echo -e "  Compiler: $PROTOBUF_PROTOC"

# Create build directory
BUILD_DIR="build-${TARGET_ARCH}"
echo -e "${BLUE}Creating build directory: $BUILD_DIR${NC}"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure with CMake
echo -e "${BLUE}Configuring with CMake...${NC}"
cmake .. \
    -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    -DTARGET_ARCH="$TARGET_ARCH" \
    -DCMAKE_VERBOSE_MAKEFILE=ON

# Build with Make
echo -e "${BLUE}Building with Make (using $(nproc) cores)...${NC}"
make -j$(nproc)

# Return to project root
cd ..

echo -e "${GREEN}✓ Build completed successfully!${NC}"
echo -e "${BLUE}Executables built in: $BUILD_DIR/${NC}"
echo -e "${BLUE}To run examples:${NC}"
echo -e "  cd $BUILD_DIR"
echo -e "  ./00-general_001-api_creation"
echo -e "  # ... or any other example executable" 
#!/bin/bash

# install_protobuf.sh - Install protobuf dependencies from QNX workspace builds
# This script copies pre-built protobuf libraries and headers from multiple architectures

# Exit on error
set -e

# Define source directories
QNX_PROTOBUF_ROOT="/home/factiondev/qnx_workspace/protobuf"
PROTOBUF_SRC_DIR="$QNX_PROTOBUF_ROOT/src"
PROTOBUF_HOST_BUILD="$QNX_PROTOBUF_ROOT/build-host"
PROTOBUF_X86_BUILD="$QNX_PROTOBUF_ROOT/build-x86"
PROTOBUF_AARCH64_BUILD="$QNX_PROTOBUF_ROOT/build-aarch64"

# Define target directory
TARGET_DIR="thirdParty/protobuf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Protobuf Installation Script ===${NC}"

# Check if source directories exist
check_source_dirs() {
    local missing=0
    
    echo "Checking source directories..."
    
    if [ ! -d "$PROTOBUF_SRC_DIR" ]; then
        echo -e "${RED}Error: Source directory not found: $PROTOBUF_SRC_DIR${NC}"
        missing=1
    fi
    
    if [ ! -d "$PROTOBUF_HOST_BUILD" ]; then
        echo -e "${RED}Error: Host build directory not found: $PROTOBUF_HOST_BUILD${NC}"
        missing=1
    fi
    
    if [ ! -d "$PROTOBUF_X86_BUILD" ]; then
        echo -e "${RED}Error: x86 build directory not found: $PROTOBUF_X86_BUILD${NC}"
        missing=1
    fi
    
    if [ ! -d "$PROTOBUF_AARCH64_BUILD" ]; then
        echo -e "${RED}Error: aarch64 build directory not found: $PROTOBUF_AARCH64_BUILD${NC}"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        echo -e "${RED}Please ensure all protobuf builds are available in QNX workspace${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All source directories found${NC}"
}

# Create target directory structure
create_target_dirs() {
    echo "Creating target directory structure..."
    
    mkdir -p "$TARGET_DIR"/{include,host/{bin,lib/pkgconfig},x86/lib,aarch64/lib}
    
    echo -e "${GREEN}✓ Target directories created${NC}"
}

# Copy headers
copy_headers() {
    echo "Copying protobuf headers..."
    
    if [ -d "$PROTOBUF_SRC_DIR/google/protobuf" ]; then
        cp -r "$PROTOBUF_SRC_DIR/google" "$TARGET_DIR/include/"
        echo -e "${GREEN}✓ Headers copied to $TARGET_DIR/include/google/${NC}"
    else
        echo -e "${RED}Error: Headers not found in $PROTOBUF_SRC_DIR/google/protobuf${NC}"
        exit 1
    fi
}

# Copy host tools and libraries
copy_host_files() {
    echo "Copying host protoc compiler and libraries..."
    
    # Copy protoc executable
    if [ -f "$PROTOBUF_HOST_BUILD/src/protoc" ]; then
        cp "$PROTOBUF_HOST_BUILD/src/protoc" "$TARGET_DIR/host/bin/"
        chmod +x "$TARGET_DIR/host/bin/protoc"
        echo -e "${GREEN}✓ protoc compiler copied${NC}"
    else
        echo -e "${RED}Error: protoc not found in $PROTOBUF_HOST_BUILD/src/${NC}"
        exit 1
    fi
    
    # Copy host libraries
    if [ -d "$PROTOBUF_HOST_BUILD/src/.libs" ]; then
        cp "$PROTOBUF_HOST_BUILD/src/.libs"/*.a "$TARGET_DIR/host/lib/" 2>/dev/null || true
        echo -e "${GREEN}✓ Host libraries copied${NC}"
    else
        echo -e "${YELLOW}Warning: Host libraries not found in $PROTOBUF_HOST_BUILD/src/.libs${NC}"
    fi
    
    # Copy pkg-config files
    if [ -f "$PROTOBUF_HOST_BUILD/protobuf.pc" ]; then
        cp "$PROTOBUF_HOST_BUILD/protobuf"*.pc "$TARGET_DIR/host/lib/pkgconfig/" 2>/dev/null || true
        echo -e "${GREEN}✓ pkg-config files copied${NC}"
    else
        echo -e "${YELLOW}Warning: pkg-config files not found in $PROTOBUF_HOST_BUILD${NC}"
    fi
}

# Copy x86 libraries
copy_x86_files() {
    echo "Copying x86 libraries..."
    
    if [ -d "$PROTOBUF_X86_BUILD/src/.libs" ]; then
        cp "$PROTOBUF_X86_BUILD/src/.libs"/*.a "$TARGET_DIR/x86/lib/" 2>/dev/null || true
        echo -e "${GREEN}✓ x86 libraries copied${NC}"
    else
        echo -e "${YELLOW}Warning: x86 libraries not found in $PROTOBUF_X86_BUILD/src/.libs${NC}"
    fi
}

# Copy aarch64 libraries
copy_aarch64_files() {
    echo "Copying aarch64 libraries..."
    
    if [ -d "$PROTOBUF_AARCH64_BUILD/src/.libs" ]; then
        cp "$PROTOBUF_AARCH64_BUILD/src/.libs"/*.a "$TARGET_DIR/aarch64/lib/" 2>/dev/null || true
        echo -e "${GREEN}✓ aarch64 libraries copied${NC}"
    else
        echo -e "${YELLOW}Warning: aarch64 libraries not found in $PROTOBUF_AARCH64_BUILD/src/.libs${NC}"
    fi
}

# Display summary
show_summary() {
    echo -e "\n${GREEN}=== Installation Summary ===${NC}"
    echo "Protobuf files installed to: $TARGET_DIR"
    echo
    echo "Directory structure:"
    if command -v tree >/dev/null 2>&1; then
        tree "$TARGET_DIR" -L 3
    else
        find "$TARGET_DIR" -type d | sed 's/^/  /'
    fi
    echo
    echo "Library sizes:"
    find "$TARGET_DIR" -name "*.a" -exec ls -lh {} \; | awk '{print "  " $9 ": " $5}'
    echo
    echo -e "${GREEN}✓ Protobuf installation completed successfully!${NC}"
    echo
    echo "Usage in CMakeLists.txt:"
    echo "  set(PROTOBUF_ROOT \${CMAKE_SOURCE_DIR}/thirdParty/protobuf)"
    echo "  set(PROTOBUF_PROTOC_EXECUTABLE \${PROTOBUF_ROOT}/host/bin/protoc)"
    echo "  For host: -L\${PROTOBUF_ROOT}/host/lib -lprotobuf"
    echo "  For x86:  -L\${PROTOBUF_ROOT}/x86/lib -lprotobuf"
    echo "  For aarch64: -L\${PROTOBUF_ROOT}/aarch64/lib -lprotobuf"
}

# Main execution
main() {
    check_source_dirs
    
    # Clean previous installation
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}Removing existing protobuf installation...${NC}"
        rm -rf "$TARGET_DIR"
    fi
    
    create_target_dirs
    copy_headers
    copy_host_files
    copy_x86_files
    copy_aarch64_files
    show_summary
}

# Run main function
main "$@" 
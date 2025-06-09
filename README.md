# Kinova Kortex API → QNX Integration Project

A QNX 8.0 application integrating the Kinova Kortex API for robotic arm control with low-level velocity commands.

## 🎯 Project Overview

This project demonstrates cross-platform integration challenges when porting Linux-based robotics APIs to real-time operating systems. The main application (`actuator_low_level_velocity_control`) provides precise velocity control for Kinova robotic arms running on QNX.

**Current Status**: ✅ Compilation successful, ✅ Protobuf ABI bridging successful, ❌ Linux system call compatibility blocking

## 📋 Prerequisites

### Required Software
- **QNX SDP 8.0** - Real-time operating system development platform
- **Linux Development Host** - Ubuntu 20.04+ or similar
- **Git** - For project management
- **Build Tools** - Make, GCC (provided by QNX SDP)

### Hardware Requirements
- **Development Host**: Linux x86_64 system
- **Target**: QNX-capable hardware (x86_64 or AArch64)
- **Robot**: Kinova robotic arm (for runtime testing)

## 🚀 Quick Start

### Step 1: Environment Setup

1. **Install QNX SDP 8.0**
   ```bash
   # Download from QNX website (requires license)
   # Install to /home/factiondev/qnx800/
   ```

2. **Clone Project**
   ```bash
   git clone <repository-url> kinova-kortex
   cd kinova-kortex
   ```

3. **Setup QNX Environment**
   ```bash
   source /home/factiondev/qnx800/qnxsdp-env.sh
   ```

4. **Verify QNX Installation**
   ```bash
   # Command used during verification:
   echo $QNX_TARGET
   echo $QNX_HOST
   qcc -V
   ```
   Expected output:
   ```
   /home/factiondev/qnx800/target/qnx
   /home/factiondev/qnx800/host/linux/x86_64
   cc: targets available in /home/factiondev/qnx800/host/linux/x86_64/etc/qcc:
           12.2.0,gcc_ntoaarch64le_cxx
           12.2.0,gcc_ntoaarch64le
           12.2.0,gcc_ntoaarch64le_gpp
           12.2.0,gcc_ntox86_64    (default)
           12.2.0,gcc_ntox86_64_cxx
           12.2.0,gcc_ntox86_64_gpp
   ```

### Step 2: Verify Project Structure

```bash
# Commands used during verification:
tree -L 3 -a
ls -la dependencies/kortex_api/lib/
ls -la dependencies/kortex_api/include/
```

Expected structure:
```
kinova-kortex/
├── src/                              # Application source
├── dependencies/                     # External libraries
│   ├── kortex_api/                  # Kinova API (Linux x86_64)
│   └── cxxopts/                     # Command-line parsing
└── guides/                          # Documentation
```

### Step 3: Verify Dependencies

1. **Check Kinova Libraries**
   ```bash
   # Commands used during verification:
   find . -name "libKortexApiCpp_without_protobuf.a" -type f
   find . -name "libKortexApiCpp.a" -type f
   ```

2. **Analyze Library Symbols (ABI)**
   ```bash
   # Commands used during verification:
   nm ./dependencies/kortex_api/lib/libKortexApiCpp_without_protobuf.a | grep "__cxx11" | wc -l
   nm ./dependencies/kortex_api/lib/libKortexApiCpp_without_protobuf.a | grep "protobuf.*string" | head -5
   ```
   Expected: 910+ `__cxx11` symbols (indicates libstdc++ ABI)

3. **Check QNX Standard Library**
   ```bash
   # Commands used during verification:
   ls -la /home/factiondev/qnx800/target/qnx/x86_64/usr/lib/libc++*
   ls -la /home/factiondev/qnx800/target/qnx/x86_64/usr/lib/libstdc++* 2>/dev/null || echo "libstdc++ not available"
   ```
   Expected: libc++ available, libstdc++ missing (confirms ABI mismatch issue)

## 🔧 Build Process

### Step 4: Build QNX-Compatible Protobuf

**Why needed**: Kinova library expects libstdc++ ABI, QNX provides libc++ ABI

1. **Setup Build Directory**
   ```bash
   mkdir -p ~/qnx_workspace/protobuf
   cd ~/qnx_workspace/protobuf
   # Download protobuf 3.5.1 source and extract
   mkdir build-x86
   cd build-x86
   ```

2. **Configure with QNX Toolchain**
   ```bash
   source /home/factiondev/qnx800/qnxsdp-env.sh
   ../configure --host=x86_64-pc-nto-qnx8.0.0 \
                --prefix=/usr \
                --enable-static \
                --disable-shared \
                CXX="qcc -Y_gpp" \
                CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=1"
   ```

3. **Build and Install**
   ```bash
   make -j$(nproc)
   make install prefix=/usr DESTDIR=$QNX_TARGET/x86_64
   ```

4. **Verify Installation**
   ```bash
   # Commands used during verification:
   ls -la $QNX_TARGET/x86_64/usr/lib/libprotobuf*
   nm $QNX_TARGET/x86_64/usr/lib/libprotobuf.a | grep "ParseFromString.*__cxx11" | head -3
   ```
   Expected: libprotobuf.a with `__cxx11` symbols matching Kinova library

### Step 5: Configure Application Build

1. **Navigate to Source Directory**
   ```bash
   cd /home/factiondev/projects/kinova-kortex/src
   ```

2. **Verify Build Configuration**
   ```bash
   # Commands used during verification:
   find . -name "common.mk" -type f
   cat common.mk | grep -E "(CC|CXX|CPULIST|_GLIBCXX_USE_CXX11_ABI)" | head -10
   ```

3. **Key Configuration Points in `common.mk`**:
   ```makefile
   # Force x86_64 architecture (Kinova constraint)
   CPULIST = x86_64
   
   # Use libstdc++ variant for ABI compatibility
   CC = qcc -V gcc_ntox86_64_gpp
   CXX = qcc -V gcc_ntox86_64_gpp
   
   # ABI compatibility flag
   CCFLAGS += -D_GLIBCXX_USE_CXX11_ABI=1
   CXXFLAGS += -D_GLIBCXX_USE_CXX11_ABI=1
   
   # Library linking order (critical)
   LIBS += KortexApiCpp_without_protobuf protobuf stdc++ gcc_s c socket m z
   ```

### Step 6: Build and Test

1. **Clean Previous Builds**
   ```bash
   # Commands used during verification:
   source /home/factiondev/qnx800/qnxsdp-env.sh
   cd src
   make clean
   ```

2. **Build Application**
   ```bash
   # Commands used during verification:
   make CPULIST=x86_64 2>&1
   ```

3. **Expected Build Results**:
   - ✅ **Compilation**: All source files compile successfully
   - ✅ **Protobuf Linking**: No protobuf symbol errors (ABI bridging successful)
   - ❌ **System Calls**: Linux-specific system call errors at final linking

## 🔍 Verification Commands

### Comprehensive System Verification

All commands used during document verification process:

1. **QNX Environment Check**
   ```bash
   ls -la /home/factiondev/qnx800/
   source /home/factiondev/qnx800/qnxsdp-env.sh && echo $QNX_TARGET
   qcc -V gcc_ntox86_64_gpp -v 2>&1 | head -10
   ```

2. **Project Structure Verification**
   ```bash
   tree -L 3 -a
   ls -la dependencies/kortex_api/
   ls -la dependencies/kortex_api/lib/ && echo "---" && ls -la dependencies/kortex_api/include/
   ls -la src/*.cpp src/*.h
   ```

3. **Symbol Analysis**
   ```bash
   # Verify Kinova library ABI
   nm ./dependencies/kortex_api/lib/libKortexApiCpp_without_protobuf.a | grep "__cxx11" | wc -l
   objdump -t ./dependencies/kortex_api/lib/libKortexApiCpp_without_protobuf.a | grep "ParseFromString.*__cxx11" | head -3
   
   # Verify QNX protobuf ABI compatibility
   nm $QNX_TARGET/x86_64/usr/lib/libprotobuf.a | grep "ParseFromString.*__cxx11" | head -3
   
   # Check for Linux system dependencies
   nm ./dependencies/kortex_api/lib/libKortexApiCpp_without_protobuf.a | grep "__errno_location\|__fdelt_chk\|futex" | head -5
   ```

4. **Build Configuration Check**
   ```bash
   find . -name "common.mk" -type f
   find . -name "guide_bridging_libstd_libc_ABI_QNX.md" -type f
   ```

5. **Standard Library Verification**
   ```bash
   ls -la /home/factiondev/qnx800/target/qnx/x86_64/usr/lib/libc++*
   ls -la /home/factiondev/qnx800/target/qnx/x86_64/usr/lib/libstdc++* 2>/dev/null || echo "libstdc++ not found"
   ```

6. **Protobuf Build Verification**
   ```bash
   ls -la ~/qnx_workspace/protobuf/build-x86/
   ls -la $QNX_TARGET/x86_64/usr/lib/libprotobuf*
   ```

## 🐛 Current Issues & Solutions

### ✅ RESOLVED: Protobuf ABI Compatibility
**Issue**: Kinova library uses libstdc++ ABI, QNX provides libc++ ABI
**Solution**: Rebuilt protobuf 3.5.1 with libstdc++ using `qcc -Y_gpp` flag
**Verification**: No protobuf symbol errors in build output

### ❌ ACTIVE: Linux System Call Dependencies
**Issue**: Kinova library contains Linux-specific system calls:
- `__errno_location` - Linux errno access mechanism
- `__fdelt_chk` - Linux file descriptor validation
- `std::__atomic_futex_*` - Linux futex threading primitives

**Current Status**: Build progresses past protobuf issues but fails at system call level

**Next Steps**:
1. **Contact Kinova**: Request QNX-native library build
2. **System Call Wrappers**: Create QNX compatibility shims
3. **Alternative Architecture**: C wrapper library to isolate Linux dependencies

## 📁 File Structure Details

```
kinova-kortex/
├── README.md                         # This file
├── src/
│   ├── actuator_low_level_velocity_control.cpp  # Main application (10KB)
│   ├── utilities.cpp/.h              # Helper functions
│   ├── common.mk                     # QNX build configuration (CRITICAL)
│   └── Makefile                      # QNX build entry point
├── dependencies/
│   ├── kortex_api/                   # Kinova Kortex API
│   │   ├── lib/
│   │   │   ├── libKortexApiCpp.a                    # Full API (25MB)
│   │   │   └── libKortexApiCpp_without_protobuf.a   # API only (18MB)
│   │   └── include/                  # API headers
│   └── cxxopts/cxxopts.hpp          # Command-line parsing
└── guides/
    ├── guide_build_master_agent2.md  # Detailed technical analysis
    └── guide_bridging_libstd_libc_ABI_QNX.md  # ABI bridging documentation
```

## 🎯 Development Workflow

### For New Developers

1. **Start Here**: Read this README completely
2. **Environment**: Set up QNX SDP 8.0 development environment
3. **Dependencies**: Follow protobuf rebuild process
4. **Build**: Use provided verification commands
5. **Issues**: Check current issues section for known problems

### For Continuing Development

1. **Current State**: Protobuf ABI bridging completed successfully
2. **Next Focus**: Linux system call compatibility layer
3. **Build Test**: `cd src && make clean && make CPULIST=x86_64`
4. **Documentation**: Update guides when making changes

## 📞 Support & References

- **QNX Documentation**: QNX SDP 8.0 development guides
- **Kinova API**: Kortex API documentation and examples
- **Technical Details**: See `guide_build_master_agent2.md` for comprehensive analysis
- **ABI Bridging**: See `guide_bridging_libstd_libc_ABI_QNX.md` for implementation details

---

**Last Updated**: December 2024  
**QNX Version**: 8.0  
**Kinova API**: Latest (December 2024)  
**Build Status**: Partial success (protobuf compatible, system calls blocked) 
ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

# Force x86_64 architecture (Kinova library is x86_64 only)
CPULIST = x86_64

# Target executable name
NAME = actuator_low_level_velocity_control

# Source files (relative to project root, not build directory)
SRCS = actuator_low_level_velocity_control.cpp utilities.cpp

# CRITICAL: Force use of libstdc++ with _gpp variant compiler for x86_64
# Set compiler variant BEFORE any flags to avoid conflicts
CC = qcc -V gcc_ntox86_64_gpp
CXX = qcc -V gcc_ntox86_64_gpp

# CRITICAL: C++11 ABI compatibility flag to match Kinova library and protobuf
CCFLAGS += -D_GLIBCXX_USE_CXX11_ABI=1
CXXFLAGS += -D_GLIBCXX_USE_CXX11_ABI=1

# Enable threading support (required for protobuf and Kortex API)
CCFLAGS += -pthread
CXXFLAGS += -pthread

# C++ standard (Kortex API likely needs C++11 or later)
CXXFLAGS += -std=c++11

# Use absolute paths to avoid QNX build system path resolution issues
PROJECT_ROOT = /home/factiondev/projects/kinova-kortex

# Include paths (QNX-specific EXTRA_INCVPATH) - PRIORITY ORDER MATTERS!
# 1. FIRST: Our locally built protobuf headers (x86_64 specific)
EXTRA_INCVPATH += $(QNX_TARGET)/x86_64/usr/include

# 2. Kortex API headers (but NOT thirdParty to avoid conflicting protobuf)
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include/common
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include/client
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include/client_stubs
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include/server
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include/server_stubs
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/include/messages
# 3. cxxopts
EXTRA_INCVPATH += $(PROJECT_ROOT)/dependencies/cxxopts
# 4. Source directory
EXTRA_INCVPATH += $(PROJECT_ROOT)/src

# Library search paths
EXTRA_LIBVPATH += $(PROJECT_ROOT)/dependencies/kortex_api/lib

# CRITICAL: Use Kinova library without protobuf + locally built protobuf with libstdc++
# This bridges the ABI gap by using compatible protobuf library (x86_64 specific)
EXTRA_LIBVPATH += $(QNX_TARGET)/x86_64/usr/lib

# Library linking order - protobuf-compatible Kinova library first, then protobuf
LIBS += KortexApiCpp_without_protobuf protobuf stdc++ gcc_s c socket m z

# Threading support for linker
LDFLAGS += -pthread

# Tell build system where source files are
VPATH += $(PROJECT_ROOT)/src

include $(MKFILES_ROOT)/qtargets.mk 
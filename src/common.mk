ifndef QCONFIG
QCONFIG=qconfig.mk
endif
include $(QCONFIG)

# Target executable name
NAME = actuator_low_level_velocity_control

# Source files (relative to project root, not build directory)
SRCS = actuator_low_level_velocity_control.cpp utilities.cpp

# CRITICAL: Force use of libstdc++ with _gpp variant compiler
CCFLAGS += -V gcc_ntox86_64_gpp
CXXFLAGS += -V gcc_ntox86_64_gpp

# CRITICAL: C++11 ABI compatibility flag to match Kinova library and protobuf
CCFLAGS += -D_GLIBCXX_USE_CXX11_ABI=1
CXXFLAGS += -D_GLIBCXX_USE_CXX11_ABI=1

# Enable threading support (required for protobuf and Kortex API)
CCFLAGS += -pthread
CXXFLAGS += -pthread

# C++ standard (Kortex API likely needs C++11 or later)
CXXFLAGS += -std=c++11

# Use absolute paths to avoid QNX build system path resolution issues
PROJECT_ROOT = /home/factiondev/projects/faction-qnx

# Include paths (QNX-specific EXTRA_INCVPATH) - PRIORITY ORDER MATTERS!
# 1. FIRST: Our locally built protobuf headers (architecture-specific)
# Use QNX build system variables to detect architecture
ifeq ($(CPU),aarch64)
EXTRA_INCVPATH += $(QNX_TARGET)/aarch64le/usr/include
else ifeq ($(CPU),x86_64)
EXTRA_INCVPATH += $(QNX_TARGET)/x86_64/usr/include
else
# Fallback - try both
EXTRA_INCVPATH += $(QNX_TARGET)/aarch64le/usr/include
EXTRA_INCVPATH += $(QNX_TARGET)/x86_64/usr/include
endif

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
# This bridges the ABI gap by using compatible protobuf library
ifeq ($(CPU),aarch64)
EXTRA_LIBVPATH += $(QNX_TARGET)/aarch64le/usr/lib
else ifeq ($(CPU),x86_64)  
EXTRA_LIBVPATH += $(QNX_TARGET)/x86_64/usr/lib
else
# Fallback - try both
EXTRA_LIBVPATH += $(QNX_TARGET)/aarch64le/usr/lib
EXTRA_LIBVPATH += $(QNX_TARGET)/x86_64/usr/lib
endif

# Library linking order - protobuf-compatible Kinova library first, then protobuf
LIBS += KortexApiCpp_without_protobuf protobuf stdc++ gcc_s c socket m z

# Threading support for linker
LDFLAGS += -pthread

# Tell build system where source files are
VPATH += $(PROJECT_ROOT)/src

include $(MKFILES_ROOT)/qtargets.mk 
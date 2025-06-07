# ----------------------------------------------------------------------------
#  CMakeLists.txt for C++ Kortex API Examples
#  Copyright © 2018 Kinova Robotics
#
#  Build instructions for the supported platforms (CMake only) : 
#
#  In Linux (x86-64 architecture):
#  From the api_cpp/examples directory, invoke:
#    $ mkdir build
#    $ cd build/
#    $ cmake .. 
#    $ make -j$(nproc)
#
#  In Windows (MinGW) :
#  From the api_cpp/examples directory, invoke:
#    $ mkdir build
#    $ cd build/
#    $ cmake .. -G "MinGW Makefiles"
#    $ mingw32-make -j%NUMBER_OF_PROCESSORS%
#
#  In Windows (MSVC command line) :
#  From the api_cpp/examples directory, invoke:
#    $ call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\vcvars64.bat" [MODIFY THIS PATH FOR YOURS]
#    $ mkdir build
#    $ cd build/
#    $ cmake .. -G "NMake Makefiles"
#    $ nmake
#
# ----------------------------------------------------------------------------
cmake_minimum_required(VERSION 3.5)

project(kortexApiCppExamples VERSION 2.6.0 LANGUAGES CXX)

# Basic CMake settings
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_COLOR_MAKEFILE ON)

# Set default build type
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Detect target architecture
if(NOT DEFINED TARGET_ARCH)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    set(TARGET_ARCH "host")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "i386|i686")
    set(TARGET_ARCH "x86")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
    set(TARGET_ARCH "aarch64")
  else()
    set(TARGET_ARCH "host")  # Default fallback
  endif()
endif()

message(STATUS "Target architecture: ${TARGET_ARCH}")

# Use new multi-architecture protobuf structure
set(PROTOBUF_ROOT "${PROJECT_SOURCE_DIR}/thirdParty/protobuf")
set(PROTOBUF_INCLUDE_DIR "${PROTOBUF_ROOT}/include")
set(PROTOBUF_LIB_DIR "${PROTOBUF_ROOT}/${TARGET_ARCH}/lib")
set(PROTOBUF_LIBRARIES "${PROTOBUF_LIB_DIR}/libprotobuf.a")
set(PROTOBUF_PROTOC_EXECUTABLE "${PROTOBUF_ROOT}/host/bin/protoc")

# Check if protobuf is installed
if(NOT EXISTS "${PROTOBUF_LIBRARIES}")
    message(FATAL_ERROR "
    Protobuf library not found at ${PROTOBUF_LIBRARIES}
    Please install protobuf first by running:
        ./install_protobuf.sh
    
    Available architectures in ${PROTOBUF_ROOT}:
    - host/lib/      (for development/host builds)
    - x86/lib/       (for x86 target builds)  
    - aarch64/lib/   (for aarch64 target builds)
    
    Current target architecture: ${TARGET_ARCH}
    ")
endif()

if(NOT EXISTS "${PROTOBUF_PROTOC_EXECUTABLE}")
    message(FATAL_ERROR "
    Protobuf compiler (protoc) not found at ${PROTOBUF_PROTOC_EXECUTABLE}
    Please install protobuf first by running:
        ./install_protobuf.sh
    ")
endif()

message(STATUS "Using protobuf from: ${PROTOBUF_LIB_DIR}")
message(STATUS "Protobuf library: ${PROTOBUF_LIBRARIES}")
message(STATUS "Protoc compiler: ${PROTOBUF_PROTOC_EXECUTABLE}")

# Compiler flags
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -O3)
  if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(-s)
  endif()
endif()

# Use ccache if available
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

# Platform-specific settings
if(UNIX)
  add_definitions(-D_OS_UNIX)
elseif(WIN32)
  add_definitions(-D_OS_WINDOWS -DNOMINMAX)
  if(MSVC)
     add_compile_options(/bigobj)
  endif()
endif()

# Include directories
include_directories(
  ${PROJECT_SOURCE_DIR}/thirdParty/cxxopts
  ${PROJECT_SOURCE_DIR}/thirdParty/kortex_api/include/client
  ${PROJECT_SOURCE_DIR}/thirdParty/kortex_api/include/client_stubs
  ${PROJECT_SOURCE_DIR}/thirdParty/kortex_api/include/common
  ${PROJECT_SOURCE_DIR}/thirdParty/kortex_api/include/messages
  ${PROJECT_SOURCE_DIR}/examples
  ${PROTOBUF_INCLUDE_DIR}
)

# Find all example source files (excluding utilities.cpp)
file(GLOB_RECURSE EXAMPLE_SOURCES RELATIVE ${PROJECT_SOURCE_DIR} "examples/*/*.cpp")

message(STATUS "Example sources found: ${EXAMPLE_SOURCES}")

# Path to utilities.cpp
set(UTILITIES_CPP examples/utilities.cpp)

# Create executable for each example
foreach(SOURCE ${EXAMPLE_SOURCES})
  get_filename_component(EXAMPLE_NAME_WE ${SOURCE} NAME_WE)
  get_filename_component(EXAMPLE_PATH ${SOURCE} PATH)
  string(REPLACE "/" "_" EXE_SUFFIX ${EXAMPLE_PATH})
  string(REPLACE "examples_" "" EXE_SUFFIX ${EXE_SUFFIX})
  set(EXE_NAME "${EXE_SUFFIX}_${EXAMPLE_NAME_WE}")
  message(STATUS "Creating executable: ${EXE_NAME} from ${SOURCE}")
  add_executable(${EXE_NAME} ${SOURCE} ${UTILITIES_CPP})

  # Link with Kortex API and Protobuf
  if(UNIX)
    target_link_libraries(${EXE_NAME} 
      ${PROJECT_SOURCE_DIR}/thirdParty/kortex_api/lib/libKortexApiCpp.a
      ${PROTOBUF_LIBRARIES}
    )
  elseif(WIN32)
    target_link_libraries(${EXE_NAME} 
      ${PROJECT_SOURCE_DIR}/thirdParty/kortex_api/lib/KortexApiCpp.lib
      ${PROTOBUF_LIBRARIES}
    )
  endif()
endforeach()

# Installation
install(TARGETS ${EXE_NAME}
  RUNTIME DESTINATION bin
)

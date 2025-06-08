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
#    $ make
#
# ----------------------------------------------------------------------------
cmake_minimum_required(VERSION 3.5)

project(kortexApiCppExamples VERSION 2.6.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set build type to Release if not specified
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

# Include directories
include_directories(${PROJECT_SOURCE_DIR}/dependencies/cxxopts/)
include_directories(${PROJECT_SOURCE_DIR}/src/)
include_directories(${PROJECT_SOURCE_DIR}/dependencies/kortex_api/include)
include_directories(${PROJECT_SOURCE_DIR}/dependencies/kortex_api/include/client)
include_directories(${PROJECT_SOURCE_DIR}/dependencies/kortex_api/include/common)
include_directories(${PROJECT_SOURCE_DIR}/dependencies/kortex_api/include/messages)
include_directories(${PROJECT_SOURCE_DIR}/dependencies/kortex_api/include/client_stubs)
include_directories(${PROJECT_SOURCE_DIR}/dependencies/kortex_api/thirdParty/include)

# Compiler flags
add_compile_options(-Wall -Wno-reorder)
add_definitions(-D_OS_UNIX)

# Link libraries
link_libraries(${PROJECT_SOURCE_DIR}/dependencies/kortex_api/lib/libKortexApiCpp.a)
link_libraries(pthread)

# Find all example source files
file(GLOB EXE_LIST "${PROJECT_SOURCE_DIR}/src/[0-9]*.cpp")

# Create executable for each example
foreach(SRC_FILE ${EXE_LIST})
  get_filename_component(SRC_FILENAME ${SRC_FILE} NAME)
  string(REPLACE ".cpp" "" TARGET_EXE_NAME ${SRC_FILENAME})
  
  add_executable(${TARGET_EXE_NAME} ${SRC_FILE} src/utilities.cpp)
endforeach()

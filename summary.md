# Kinova Kortex C++ Examples

## Project Structure

```
kinova-kortex/
├── dependencies/
│   ├── kortex_api/                   # Kortex API C++ 2.7.0-r.5
│   │   ├── include/                  # API headers
│   │   ├── lib/                      # Static libraries
│   │   ├── thirdParty/include/       # Protobuf headers
│   │   └── cmake/                    # CMake target configuration
│   └── cxxopts/                      # Command-line parsing
├── src/                              # Example source files
│   ├── utilities.h
│   ├── utilities.cpp
│   ├── 01_api_creation.cpp
│   ├── 01_compute_kinematics.cpp
│   ├── 01_devices_routing.cpp
│   ├── 01_gripper_command.cpp
│   ├── 01_move_angular_and_cartesian.cpp
│   ├── 01_torque_control_cyclic.cpp
│   ├── 01_vision_intrinsics.cpp
│   ├── 02_sequence.cpp
│   ├── 03_twist_command.cpp
│   ├── 04_error_management.cpp
│   ├── 05_notification.cpp
│   └── ... (26 examples total)
├── CMakeLists.txt
├── build-local.sh
└── .gitignore
```

## Prerequisites

- Linux with GCC
- CMake >= 3.5

## Build

```bash
./build-local.sh
```

Or manually:
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

## Run Examples

```bash
cd build
./01_api_creation
./02_sequence --ip 192.168.1.10
```

## Robot Connection

- Connect via ethernet
- Set computer IP: `192.168.1.11/24`
- Robot default IP: `192.168.1.10`

## Cross-Compilation (aarch64)

For building on aarch64 targets, use the CMake target configuration:

```bash
# Set up cross-compilation toolchain
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++

# Build with CMake target
mkdir build-aarch64 && cd build-aarch64
cmake .. -DCMAKE_TOOLCHAIN_FILE=<toolchain-file> \
         -DCMAKE_BUILD_TYPE=Release \
         -DKortexApiCpp_DIR=../dependencies/kortex_api/cmake/modules

# Replace direct linking in CMakeLists.txt with:
# find_package(KortexApiCpp REQUIRED)
# target_link_libraries(target_name KortexApiCpp)
```

The `dependencies/kortex_api/cmake/` folder contains CMake target definitions that handle include paths and library linking automatically for cross-compilation scenarios.

## Dependencies

- **Kortex API**: Static libraries in `dependencies/kortex_api/lib/`
- **Protobuf**: Headers in `dependencies/kortex_api/thirdParty/include/`
- **cxxopts**: Command-line parsing in `dependencies/cxxopts/`

## Examples

26 example programs covering:
- API creation and connection
- Movement control (angular, cartesian, sequences)
- Advanced control (torque, joint speeds)
- Vision system integration
- Hardware interfaces (GPIO, I2C, UART)
- Gripper control
- Error handling and notifications 
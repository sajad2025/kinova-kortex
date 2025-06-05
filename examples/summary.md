# Kortex API Examples Summary

This document provides a summary of the examples available in this repository, organized by category.

## 000-Getting_started
Fundamental examples to understand the Kortex API basics:

- **01-api_creation**: Demonstrates how to establish a connection to a robot, create a session, and initialize API clients.
- **02-protobuf_object_manipulation**: Shows how to work with Protobuf objects for robot configuration and control.
- **03-api_mechanism**: Explains core API mechanisms including transport, sessions, and client services.
- **04-error_management**: Demonstrates error handling patterns in the Kortex API.
- **05-notification**: Illustrates how to set up and handle notifications from the robot.

## 100-Overview
General overview and configuration examples:

- **01-devices_routing**: Shows how to communicate with various devices in a Kinova robot.
- **02-protection_zones_configuration**: Demonstrates how to define and manage protection zones to restrict robot movement.

## 102-High_level_movement
Examples for various high-level robot movement controls:

- **01-move_angular_and_cartesian**: Demonstrates both angular (joint) and Cartesian space movements.
- **02-sequence**: Shows how to create and execute sequences of robot movements.
- **03-twist_command**: Illustrates robot movement using twist commands (linear and angular velocity).
- **04-send_joint_speeds**: Demonstrates how to control robot joints by setting their speeds.

## 103-Gen3_uart_bridge
UART communication examples:

- **01-uart_bridge**: Shows how to set up and use the UART bridge for external device communication.

## 104-Gen3_gpio_bridge
GPIO control examples:

- **01-gpio_bridge**: Illustrates how to control the General Purpose Input/Output (GPIO) pins on the robot.

## 105-Gen3_i2c_bridge
I2C communication examples:

- **01-i2c_bridge**: Demonstrates using the I2C protocol to communicate with external devices.

## 106-Gripper_command
Examples for controlling the robot gripper:

- **01-gripper_command**: Shows basic gripper control commands like open, close, and position control.

## 107-Gripper_low_level_command
Advanced gripper control:

- **01-gripper_low_level_command**: Demonstrates low-level gripper control for precise manipulation.

## 108-Gen3_torque_control
Torque-based robot control examples:

- **01-torque_control_cyclic**: Shows how to implement cyclic torque control for advanced robot movements.

## 109-Gen3_ethernet_bridge
Ethernet communication examples:

- **01-ethernet_bridge_configuration**: Demonstrates how to configure and use the ethernet bridge.

## 110-Waypoints
Path planning and execution examples:

- **01-send_angular_wapoint_trajectory**: Shows how to create and execute trajectories in joint space.
- **02-send_cartesian_waypoint_trajectory**: Illustrates trajectory planning and execution in Cartesian space.

## 111-Kinematics
Robot kinematics examples:

- **01-compute-kinematics**: Demonstrates forward and inverse kinematics calculations.

## 200-Actuator_low_level_control
Examples for direct actuator control:

- **01-actuator_low_level_velocity_control**: Shows how to control actuators by directly setting velocity.

## 500-Gen3_vision_configuration
Vision system configuration and control:

- **01_vision_intrinsics**: Shows how to configure the intrinsic parameters of the robot's camera.
- **02_vision_extrinsics**: Demonstrates how to set up extrinsic calibration for the vision system.
- **03_vision_sensor_focus_action**: Shows how to control the focus of the vision sensors.
- **04_vision_sensor_options**: Illustrates how to configure various options for the vision sensors.

## Utilities
The `utilities.h` and `utilities.cpp` files provide common utility functions used across multiple examples, including:
- Command-line argument parsing
- Session handling
- Error management
- Basic input/output operations 
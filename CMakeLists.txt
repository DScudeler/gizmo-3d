cmake_minimum_required(VERSION 3.21)

project(gizmo3d VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt configuration
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    Quick3D
    Test
)

# Set Qt6 QML policy QTP0001 after finding Qt
if(COMMAND qt_policy)
    qt_policy(SET QTP0001 NEW)
endif()

# Set QML import path for development
set(QML_IMPORT_PATH
    "${CMAKE_BINARY_DIR}/src"
    CACHE STRING "Qt Creator QML import paths" FORCE
)

# Add subdirectories
add_subdirectory(src)
add_subdirectory(examples)

# Enable testing
enable_testing()
add_subdirectory(tests)

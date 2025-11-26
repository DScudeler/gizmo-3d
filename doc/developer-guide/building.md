# Building Gizmo3D

Complete guide to building Gizmo3D from source.

## Requirements

### Build Tools

- **CMake** 3.21 or later
- **Ninja** build system (recommended)
- **C++20** compatible compiler
  - GCC 14.2+ recommended
  - Clang 15+
  - MSVC 2022+

### Qt Dependencies

Qt 6 with the following modules:

- Qt6::Core
- Qt6::Gui
- Qt6::Qml
- Qt6::Quick
- Qt6::Quick3D
- Qt6::Test
- Qt6::QuickTest

## Quick Build

### Using CMake Presets (Recommended)

```bash
# Complete workflow: configure + build + test
cmake --workflow --preset debug

# Or individual steps
cmake --preset debug              # Configure
cmake --build --preset debug      # Build
ctest --preset debug              # Test
```

### Traditional CMake

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug -G Ninja
cmake --build build
ctest --test-dir build
```

## Available Presets

| Preset | Build Type | Use Case |
|--------|------------|----------|
| `debug` | Debug | Development with full symbols |
| `release` | Release | Production with optimizations |
| `relwithdebinfo` | RelWithDebInfo | Production with debug info |

Each preset configures:
- Build type
- Binary directory (`build/debug`, `build/release`, etc.)
- Environment variables for testing

## Build Outputs

```
build/debug/
├── src/
│   └── Gizmo3D/              # QML module output
│       ├── qmldir
│       └── Gizmo3D.qmltypes
├── libgizmo3d.a              # Static library
├── examples/
│   └── gizmo3d_example       # Example application
└── tests/
    ├── tst_translationgizmo
    ├── tst_rotationgizmo
    ├── tst_scalegizmo
    └── ...
```

## CMake Configuration

### Root CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.21)
project(Gizmo3D LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Qml Quick Quick3D Test QuickTest)

# QML module import path for Qt Creator
set(QML_IMPORT_PATH "${CMAKE_BINARY_DIR}/src" CACHE STRING "" FORCE)

add_subdirectory(src)
add_subdirectory(examples)
add_subdirectory(tests)
```

### Module CMakeLists.txt (src/)

```cmake
add_library(gizmo3d STATIC)

# Mark singletons
set_source_files_properties(
    GizmoMath.qml
    GizmoProjection.qml
    # ...
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(gizmo3d
    URI Gizmo3D
    VERSION 0.1
    STATIC
    NO_PLUGIN
    QML_FILES
        TranslationGizmo.qml
        RotationGizmo.qml
        ScaleGizmo.qml
        GlobalGizmo.qml
        # ...
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/src/Gizmo3D
)

target_link_libraries(gizmo3d PRIVATE
    Qt6::Quick
    Qt6::Quick3D
)
```

## Linking to Gizmo3D

### As Subdirectory

```cmake
# In your project's CMakeLists.txt
add_subdirectory(path/to/gizmo-3d)

target_link_libraries(your_app PRIVATE gizmo3d)
```

### QML Import Path

Ensure your application can find the QML module:

```cmake
# In CMake
set(QML_IMPORT_PATH "${CMAKE_BINARY_DIR}/path/to/gizmo-3d/src" CACHE STRING "")
```

Or at runtime in C++:

```cpp
QQmlApplicationEngine engine;
engine.addImportPath("path/to/gizmo-3d/build/src");
```

## Environment Configuration

### CMakePresets.json

The presets configure environment variables for proper test execution:

```json
{
    "configurePresets": [
        {
            "name": "debug",
            "binaryDir": "${sourceDir}/build/debug",
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Debug"
            }
        }
    ],
    "testPresets": [
        {
            "name": "debug",
            "configurePreset": "debug",
            "environment": {
                "QT_QPA_PLATFORM": "xcb",
                "LD_LIBRARY_PATH": "/usr/lib/x86_64-linux-gnu",
                "GTK_PATH": "",
                "GIO_MODULE_DIR": ""
            }
        }
    ]
}
```

### Snap VSCode Issue (Linux)

VSCode installed via Snap contaminates the environment. The presets clear these variables, but for manual runs:

```bash
# Clear snap contamination
unset GTK_PATH GIO_MODULE_DIR

# Set library path
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

# Run
./build/debug/examples/gizmo3d_example
```

Or use the launcher script:

```bash
./run_example.sh
```

## Build Options

### Debug Symbols

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
```

### Release Optimization

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
```

### Compiler Warnings

The project enables standard warnings. For more:

```bash
cmake -B build -DCMAKE_CXX_FLAGS="-Wall -Wextra -Wpedantic"
```

### Compile Commands (for IDEs)

```bash
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

Creates `compile_commands.json` for IDE integration.

## Running Tests

### All Tests

```bash
ctest --preset debug

# Verbose output
ctest --preset debug --verbose
```

### Specific Test

```bash
ctest --preset debug -R TranslationGizmoTest
```

### Direct Execution

```bash
# Set environment
export QT_QPA_PLATFORM=offscreen
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

# Run test
./build/debug/tests/tst_translationgizmo
```

### QML Tests with Display

QML interaction tests require a display:

```bash
# With X11
export QT_QPA_PLATFORM=xcb
./build/debug/tests/tst_qml_gizmo

# Headless (CI)
xvfb-run -a ./build/debug/tests/tst_qml_gizmo
```

## Running the Example

```bash
# Using launcher script
./run_example.sh

# Direct (with environment)
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
./build/debug/examples/gizmo3d_example
```

## Troubleshooting

### "module Gizmo3D not found"

Ensure QML import path includes the build directory:

```bash
export QML2_IMPORT_PATH=/path/to/build/debug/src
```

### Snap Library Conflicts

Clear snap environment variables:

```bash
unset GTK_PATH GIO_MODULE_DIR
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
```

### Qt Not Found

Ensure Qt 6 is installed and findable:

```bash
# Check Qt installation
qmake6 --version

# Explicitly set Qt path if needed
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/qt6
```

### Ninja Not Found

Install Ninja:

```bash
# Ubuntu/Debian
sudo apt install ninja-build

# Fedora
sudo dnf install ninja-build

# macOS
brew install ninja
```

## See Also

- [Code Organization](code-organization.md) - Project structure
- [Testing](testing.md) - Testing guide
- [Installation](../getting-started/installation.md) - User installation guide

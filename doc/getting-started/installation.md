# Installation Guide

Complete guide to building and installing Gizmo3D.

## Requirements

### Build Dependencies

- **CMake**: 3.21 or later
- **Qt 6**: Core, Gui, Qml, Quick, Quick3D, Test modules
- **C++ Compiler**: C++20 support required
- **Build System**: Ninja (recommended) or Make

### Platform Support

Since this is pure Qml, it should run on any Qt supported platform.

- Linux (tested on Ubuntu 25.10)

## Build from Source

### Clone the Repository

```bash
git clone https://github.com/dscudeler/gizmo-3d.git
cd gizmo-3d
```

### CMake Workflow Method (Recommended)

Use CMake workflow presets for a streamlined build process:

```bash
# Debug build with tests
cmake --workflow --preset debug

# Release build
cmake --workflow --preset release

# Release with debug info
cmake --workflow --preset relwithdebinfo
```

The workflow preset automatically:
1. Configures the project
2. Builds all targets
3. Runs the test suite

### Step-by-Step Build

Alternatively, run each step manually:

```bash
# 1. Configure
cmake --preset debug

# 2. Build
cmake --build --preset debug

# 3. Run tests
ctest --preset debug
```

### Build Configuration Options

Available CMake presets:

| Preset | Configuration | Use Case |
|--------|---------------|----------|
| `debug` | Debug symbols, no optimization | Development |
| `release` | Optimized, no debug symbols | Production |
| `relwithdebinfo` | Optimized + debug symbols | Profiling |

## Running Tests

### All Tests

```bash
# Using CTest (recommended)
ctest --preset debug

# With verbose output
ctest --preset debug --verbose

# Specific test
ctest --preset debug -R tst_translationgizmo
```

## Running the Example Application

### Standard Method

```bash
./build/debug/examples/gizmo3d_example
```

## Integration into Your Project

### CMake Integration

See the example for a full integration of Gizmo3D.

## Next Steps

- [Quick Start Guide](quick-start.md) - First integration tutorial
- [Controller Pattern](../user-guide/controller-pattern.md) - Implement manipulation logic
- [API Reference](../api-reference/translation-gizmo.md) - Complete API documentation

# Gizmo3D - Translation Gizmo for Qt Quick 3D

A QML-based 3D transformation gizmo for Qt Quick 3D applications, featuring Canvas-based 2D rendering of 3D arrows with View3D coordinate mapping.

## Project Structure

```
gizmo-3d/
├── CMakeLists.txt           # Root CMake configuration
├── CMakePresets.json        # CMake presets for Ninja builds
├── src/                     # Gizmo3D QML module library
│   ├── CMakeLists.txt
│   └── TranslationGizmo.qml
├── examples/                # Example application
│   ├── CMakeLists.txt
│   ├── main.cpp
│   └── main.qml
├── tests/                   # Qt Test suite
│   ├── CMakeLists.txt
│   └── tst_translationgizmo.cpp
└── run_example.sh           # Launcher script (fixes snap issues)
```

## Features

- **Translation Gizmo**: 3D arrow handles rendered using 2D Canvas
- **Screen-Space Parameterized**: Gizmo size adapts to screen dimensions
- **View3D Integration**: Uses `mapFromScene`/`mapToScene` for 3D displacement
- **Color-Coded Axes**: X=Red, Y=Green, Z=Blue
- **Mouse Interaction**: Click and drag arrows to translate objects
- **Static QML Module**: Compiled as a reusable library

## Build Requirements

- CMake 3.21+
- Qt 6 (Core, Gui, Qml, Quick, Quick3D, Test)
- Ninja build system
- C++20 compiler (GCC 14.2+ or Clang equivalent)

## Building

### Using CMake Presets (Recommended)

```bash
# Configure
cmake --preset debug

# Build
cmake --build --preset debug

# Test
ctest --preset debug

# Complete workflow (configure + build + test)
cmake --workflow --preset debug
```

### Available Presets

- `debug` - Debug build with full symbols
- `release` - Release build with optimizations
- `relwithdebinfo` - Release with debug symbols

### Traditional CMake

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug -G Ninja
cmake --build build
ctest --test-dir build
```

## Running the Example

### From VSCode (Recommended)

Use the built-in tasks (Ctrl+Shift+P → "Tasks: Run Task"):
- **Run Example** - Launch the application with clean environment
- **Build and Run** - Build then run in one step
- **Run Tests** - Execute the test suite

Or use F5 to debug with proper environment setup.

### Using the Launcher Script

```bash
./run_example.sh
```

This script handles the snap environment contamination issue automatically.

### Direct Execution

```bash
# Unset snap environment variables first
unset GTK_PATH GIO_MODULE_DIR

# Set library path
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

# Then run
./build/debug/examples/gizmo3d_example
```

## Important: Snap VSCode Environment Issue

If you're using VSCode installed via Snap, it contaminates the terminal environment with `GTK_PATH` and `GIO_MODULE_DIR` variables. This causes applications to load incompatible libraries from `/snap/core20/`, resulting in errors like:

```
symbol lookup error: /snap/core20/current/lib/x86_64-linux-gnu/libpthread.so.0:
undefined symbol: __libc_pthread_init, version GLIBC_PRIVATE
```

### Solution: VSCode Settings Fix

Add to your VSCode `settings.json` (Ctrl+Shift+P → "Preferences: Open User Settings (JSON)"):

```json
"terminal.integrated.env.linux": {
    "GTK_PATH": null,
    "GIO_MODULE_DIR": null
}
```

Then restart VSCode.

### Alternative: Shell Profile Fix

Add to `~/.bashrc` or `~/.profile`:

```bash
unset GTK_PATH
unset GIO_MODULE_DIR
```

## Test Results

✅ **100% tests passed** (1/1)
- Component creation test
- Property binding test
- Gizmo size configuration test
- Target node binding test

## Development

### Adding New Gizmo Types

1. Create new QML file in `src/` (e.g., `RotationGizmo.qml`)
2. Add to `src/CMakeLists.txt` QML_FILES list
3. Rebuild and test

### Testing

Tests use Qt Test framework with static plugin imports. The `Q_IMPORT_PLUGIN(Gizmo3DPlugin)` macro is required for static QML modules.

## License

[Your License Here]

## Troubleshooting

### "module Gizmo3D plugin not found"

Ensure `QML2_IMPORT_PATH` points to the build src directory:
```bash
export QML2_IMPORT_PATH=/path/to/build/debug/src
```

### Snap Library Conflicts

Use the provided `run_example.sh` script or unset snap environment variables as documented above.

### Test Failures

Run tests with proper environment:
```bash
ctest --preset debug
```

The test preset automatically sets `LD_LIBRARY_PATH` and `QT_QPA_PLATFORM` for headless testing.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gizmo3D is a Qt Quick 3D transformation gizmo library that uses Canvas-based 2D rendering to draw 3D manipulation handles. The gizmo translates 3D world positions to screen space using View3D's coordinate mapping system.

## Build System

This project uses CMake 3.21+ with presets for consistent builds across configurations.

**Requirements**: CMake 3.21+, Qt 6 (Core, Gui, Qml, Quick, Quick3D, Test), C++20 compiler, Ninja build system

### Common Build Commands

```bash
# Configure, build, and test (recommended)
cmake --workflow --preset debug

# Individual steps
cmake --preset debug              # Configure
cmake --build --preset debug      # Build
ctest --preset debug              # Run tests

# Available presets: debug, release, relwithdebinfo
```

### Running the Example Application

```bash
# From build directory
./build/debug/examples/gizmo3d_example

# Or use the launcher script (handles snap environment issues)
./run_example.sh
```

### Running Tests

```bash
# Run all tests with CTest (preferred)
ctest --preset debug

# Run a specific test executable directly (requires environment setup)
QT_QPA_PLATFORM=offscreen LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu ./build/debug/tests/tst_translationgizmo

# Run with verbose output
ctest --preset debug --verbose
```

## Architecture

### Static QML Module Pattern

The project uses Qt's static QML module system with `qt_add_qml_module()`. This creates:
- `gizmo3d` - Static backing library containing QML runtime
- `gizmo3dplugin` - Static plugin that registers QML types
- **QML Import**: `import Gizmo3D 1.0`

**Critical**: Static QML modules require `Q_IMPORT_PLUGIN(Gizmo3DPlugin)` in C++ applications and tests to register the module before use.

### Coordinate Space Mapping

The gizmo implements a 2D/3D hybrid rendering approach:

1. **World to Screen**: `View3D.mapFrom3DScene(vector3d)` converts 3D positions to 2D canvas coordinates
2. **Screen to World**: `View3D.mapTo3DScene(point)` converts mouse positions back to 3D space
3. **Arrow Rendering**: Canvas draws 2D arrows using screen-space directions derived from 3D unit vectors

This allows the gizmo to maintain consistent screen-space size while operating in 3D space.

### Component Structure

```
TranslationGizmo (QML Item)
├── Canvas - Renders 3D arrows in 2D screen space
│   └── drawArrow() - Draws line + triangular arrowhead
├── MouseArea - Handles click detection and drag operations
│   ├── Axis selection based on proximity to arrows
│   └── Translation constrained to active axis
└── Connections - Triggers repaints on position/camera changes
```

**Key Properties**:
- `view3d: View3D` - Required reference to the View3D containing the 3D scene
- `targetNode: Node` - The 3D object being manipulated (used for visual tracking only)
- `gizmoSize: real` - Screen-space size in pixels (default: 100)
- `activeAxis: int` - Currently dragged axis (0=none, 1=X, 2=Y, 3=Z)

### Signal-Based Manipulation Pattern

The gizmos use a signal-based architecture where manipulation deltas are emitted as signals rather than directly modifying the target node. This decouples the gizmo UI from scene manipulation logic, enabling integration with external frameworks.

#### TranslationGizmo Signals

```qml
// Axis translation (X, Y, or Z)
signal axisTranslationStarted(int axis)
signal axisTranslationDelta(int axis, real delta, bool snapActive)
signal axisTranslationEnded(int axis)

// Planar translation (XY, XZ, or YZ plane)
signal planeTranslationStarted(int plane)
signal planeTranslationDelta(int plane, vector3d delta, bool snapActive)
signal planeTranslationEnded(int plane)
```

**Parameters**:
- `axis/plane`: Which axis (1=X, 2=Y, 3=Z) or plane (1=XY, 2=XZ, 3=YZ) is being dragged
- `delta`: Displacement since drag started (scalar for axis, vector3d for plane)
- `snapActive`: Whether snapping was applied to this delta

#### RotationGizmo Signals

```qml
signal rotationStarted(int axis)
signal rotationDelta(int axis, real angleDegrees, bool snapActive)
signal rotationEnded(int axis)
```

**Parameters**:
- `axis`: Which rotation axis (1=X, 2=Y, 3=Z)
- `angleDegrees`: Angular displacement since drag started in degrees
- `snapActive`: Whether angle snapping was applied

#### Controller Pattern

External code implements a "trivial controller" that:
1. Stores the initial state when manipulation starts
2. Receives delta signals and computes new positions/rotations
3. Updates the target node, which triggers automatic gizmo redraws via Connections

**Example: Translation Controller**
```qml
TranslationGizmo {
    id: gizmo
    targetNode: myObject
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    onAxisTranslationStarted: function(axis) {
        dragStartPos = myObject.position
    }

    onAxisTranslationDelta: function(axis, delta, snapActive) {
        if (axis === 1) {
            myObject.position = Qt.vector3d(dragStartPos.x + delta, dragStartPos.y, dragStartPos.z)
        } else if (axis === 2) {
            myObject.position = Qt.vector3d(dragStartPos.x, dragStartPos.y + delta, dragStartPos.z)
        } else if (axis === 3) {
            myObject.position = Qt.vector3d(dragStartPos.x, dragStartPos.y, dragStartPos.z + delta)
        }
    }

    onPlaneTranslationStarted: function(plane) {
        dragStartPos = myObject.position
    }

    onPlaneTranslationDelta: function(plane, delta, snapActive) {
        myObject.position = Qt.vector3d(
            dragStartPos.x + delta.x,
            dragStartPos.y + delta.y,
            dragStartPos.z + delta.z
        )
    }
}
```

**Example: Rotation Controller**
```qml
RotationGizmo {
    id: rotationGizmo
    targetNode: myObject
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    onRotationStarted: function(axis) {
        dragStartRot = myObject.rotation
    }

    onRotationDelta: function(axis, angleDegrees, snapActive) {
        let axisVec = axis === 1 ? Qt.vector3d(1, 0, 0)
                    : axis === 2 ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)
        let deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
        myObject.rotation = deltaQuat.times(dragStartRot)
    }
}
```

**Key Benefits**:
- **Framework Integration**: Easy to use with external scene managers that only use QtQuick3D for display
- **Validation**: Controllers can reject or modify transformations before applying
- **Undo/Redo**: Deltas from `dragStart` provide natural command pattern support
- **Multi-Object**: Controllers can apply deltas to multiple objects simultaneously
- **Automatic Redraws**: Existing `Connections` to `targetNode.onPositionChanged` handle visual updates

## Environment Configuration

### Snap VSCode Library Contamination

VSCode installed via Snap pollutes the environment with `GTK_PATH` and `GIO_MODULE_DIR`, causing Qt applications to load incompatible libraries from `/snap/core20/`. This manifests as:

```
symbol lookup error: /snap/core20/.../libpthread.so.0: undefined symbol: __libc_pthread_init
```

**Solution**: The CMakePresets.json sets `LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu` in all presets to override snap paths. Tests also set `QT_QPA_PLATFORM=offscreen` for headless execution.

### QML Module Discovery

The build system sets `QML2_IMPORT_PATH` to point to `${CMAKE_BINARY_DIR}/src` where the Gizmo3D module is generated. This is configured in:
- Root CMakeLists.txt: `set(QML_IMPORT_PATH "${CMAKE_BINARY_DIR}/src")`
- Test/Example CMakeLists.txt: Compile definition for Qt Creator integration
- CTest properties: Environment variable for test execution

## Development Workflow

### Adding New Gizmo Components

1. Create QML file in `src/` (e.g., `RotationGizmo.qml`)
2. Add to `src/CMakeLists.txt` in the `QML_FILES` section of `qt_add_qml_module()`
3. Rebuild - CMake will automatically register the new type

### Testing Requirements

Tests must:
- Include `Q_IMPORT_PLUGIN(Gizmo3DPlugin)` to load the static module
- Link against both `gizmo3d` (backing lib) and `gizmo3dplugin` (plugin)
- Set `QML2_IMPORT_PATH` environment variable to find the module
- Use `QT_QPA_PLATFORM=offscreen` for headless CI testing

### Canvas Rendering Pattern

The TranslationGizmo uses manual `canvas.requestPaint()` triggers rather than automatic repainting. Repaint occurs on:
- Target node position changes (via Connections to `targetNode.onPositionChanged`)
- Camera movement (via Connections to `view3d.camera.onPositionChanged/onRotationChanged`)
- Mouse drag operations (during `onPositionChanged` handler)
- Axis activation/deactivation (on mouse press/release)

When modifying rendering logic, ensure all state changes that affect visual output call `canvas.requestPaint()`.

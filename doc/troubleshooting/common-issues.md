# Common Issues and Solutions

Solutions to frequently encountered problems when using Gizmo3D.

## Gizmo Not Visible

### Symptom
Gizmo component doesn't appear on screen.

### Solutions

**1. Check Z-Order**

Ensure the gizmo is above the View3D in the visual hierarchy:

```qml
View3D {
    id: view3d
    // 3D scene...
}

TranslationGizmo {
    id: gizmo
    z: 1000  // Force on top
}
```

**2. Verify Property Bindings**

```qml
TranslationGizmo {
    view3d: myView3D  // Must be set!
    targetNode: myCube  // Must be set!
}
```

**3. Check Target Node Position**

If target node is at (0,0,0) and camera is looking elsewhere, gizmo won't be visible:

```qml
Model {
    position: Qt.vector3d(0, 0, 0)  // Check this is in camera view
}
```

**4. Canvas Rendering Issues**

Force a repaint:

```qml
Component.onCompleted: {
    gizmo.canvas.requestPaint()
}
```

## QML Module Not Found

### Symptom
```
module "Gizmo3D" is not installed
```

### Solutions

**1. Import Static Plugin (C++ Apps)**

```cpp
#include <QtPlugin>
Q_IMPORT_PLUGIN(Gizmo3DPlugin)
```

**2. Set QML Import Path**

CMake:
```cmake
set(QML_IMPORT_PATH "${CMAKE_BINARY_DIR}/gizmo3d/src" CACHE STRING "" FORCE)
```

Environment variable:
```bash
export QML2_IMPORT_PATH=/path/to/gizmo3d/build/src
```

Runtime:
```cpp
engine.addImportPath("/path/to/gizmo3d/build/src");
```

**3. Rebuild After QML Changes**

```bash
cmake --build --preset debug
```

## Manipulation Not Working

### Symptom
Clicking gizmo doesn't manipulate the object.

### Solutions

**1. Verify Signal Connections**

```qml
Connections {
    target: gizmo
    function onAxisTranslationDelta(axis, delta, snapActive) {
        console.log("Signal received!")  // Debug
        // Apply transformation...
    }
}
```

**2. Check Mouse Events**

Ensure no other MouseArea is stealing events:

```qml
TranslationGizmo {
    z: 1000  // Above other mouse areas
}
```

**3. Use SimpleController**

Simplify debugging with SimpleController:

```qml
SimpleController {
    gizmo: gizmo
    targetNode: targetCube
}
```

## Rotation Drift

### Symptom
Rotation becomes incorrect or drifts over time.

### Solution

Always compose with drag start rotation, not current rotation:

```qml
// ✅ CORRECT
property quaternion dragStartRot
onRotationStarted: { dragStartRot = targetNode.rotation }
onRotationDelta: function(axis, angle, snap) {
    var delta = GizmoMath.quaternionFromAxisAngle(axisVec, angle)
    targetNode.rotation = delta.times(dragStartRot)  // Compose with start
}

// ❌ INCORRECT
onRotationDelta: function(axis, angle, snap) {
    var delta = GizmoMath.quaternionFromAxisAngle(axisVec, angle)
    targetNode.rotation = delta.times(targetNode.rotation)  // Drifts!
}
```

## Translation Jumping

### Symptom
Object jumps to unexpected position when dragging starts.

### Solution

Store drag start position and use cumulative deltas:

```qml
// ✅ CORRECT
property vector3d dragStartPos
onAxisTranslationStarted: { dragStartPos = targetNode.position }
onAxisTranslationDelta: function(axis, transformMode, delta, snap) {
    if (axis === GizmoEnums.Axis.X) targetNode.position.x = dragStartPos.x + delta
}

// ❌ INCORRECT (treats delta as absolute position)
onAxisTranslationDelta: function(axis, transformMode, delta, snap) {
    targetNode.position.x = delta  // Jumps!
}
```

## Snap VSCode Library Contamination (Linux)

### Symptom
```
symbol lookup error: /snap/core20/.../libpthread.so.0: undefined symbol
```

### Solution

Set `LD_LIBRARY_PATH` before running:

```bash
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
./gizmo3d_example
```

Or use the provided launcher script:

```bash
./run_example.sh
```

**Root Cause**: VSCode installed via Snap pollutes environment with `GTK_PATH` and `GIO_MODULE_DIR`, causing Qt to load incompatible libraries.

## Tests Fail to Run

### Symptom
Tests crash or can't find Qt platform plugin.

### Solution

Set offscreen platform:

```bash
export QT_QPA_PLATFORM=offscreen
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
ctest --preset debug
```

## Camera Control Disabled

### Symptom
Camera won't move when gizmo is present.

### Solution

Disable camera control when gizmo is active:

```qml
WasdController {
    enabled: gizmo.activeAxis === 0 && rotationGizmo.activeAxis === 0
}
```

## Performance Issues

### Symptom
Frame rate drops when using gizmos.

### Solutions

**1. Reduce Circle Segments** (modify source):

```qml
// In RotationGizmo.qml
var segments = 32  // Instead of 64
```

**2. Use Single Gizmo**

Instead of GlobalGizmo in Both mode, use mode switching:

```qml
GlobalGizmo {
    mode: currentMode  // GizmoEnums.Mode.Translate or Rotate, not Both
}
```

**3. Optimize Repaint Triggers**

Ensure repaints only occur when necessary.

## Build Errors

### CMake Can't Find Qt

```bash
export Qt6_DIR=/path/to/Qt/6.x.x/gcc_64/lib/cmake/Qt6
cmake --preset debug
```

### Static Plugin Not Registered

Ensure `Q_IMPORT_PLUGIN` is in your main.cpp:

```cpp
Q_IMPORT_PLUGIN(Gizmo3DPlugin)
```

And link both libraries:

```cmake
target_link_libraries(your_app PRIVATE gizmo3d gizmo3dplugin)
```

## See Also

- [Installation Guide](../getting-started/installation.md)
- [Architecture Overview](../architecture/overview.md)
- [Platform-Specific Issues](platform-specific.md)

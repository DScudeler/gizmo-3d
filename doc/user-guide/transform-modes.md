# Transform Modes

Guide to world and local coordinate modes in Gizmo3D.

## Overview

Gizmo3D supports two transform modes that control the orientation of manipulation axes:

| Mode | Value | Axes Aligned To | Use Case |
|------|-------|-----------------|----------|
| `GizmoEnums.TransformMode.World` | 0 | Global coordinate system | Scene-relative manipulation |
| `GizmoEnums.TransformMode.Local` | 1 | Object's rotation | Object-relative manipulation |

## Setting Transform Mode

All gizmos accept a `transformMode` property (type: `int`):

```qml
import Gizmo3D 1.0

TranslationGizmo {
    view3d: myView3D
    targetNode: myCube
    transformMode: GizmoEnums.TransformMode.World
}

RotationGizmo {
    view3d: myView3D
    targetNode: myCube
    transformMode: GizmoEnums.TransformMode.Local
}

GlobalGizmo {
    view3d: myView3D
    targetNode: myCube
    transformMode: modeSelector.currentMode  // int value
}
```

## World Mode

In world mode, gizmo axes align with the global coordinate system regardless of object rotation.

```
Global Axes (fixed):
    Y (up)
    │
    │
    └───── X (right)
   /
  Z (toward camera)
```

### Behavior

- **X axis**: Always points in global +X direction
- **Y axis**: Always points in global +Y direction (up)
- **Z axis**: Always points in global +Z direction

### Visual Example

```
Object rotated 45° around Y:

    Y                           Y
    │  ╱                        │
    │ ╱  Object                 │  World Gizmo
    │╱                          │
    └───── X                    └───── X
   ╱                           ╱
  Z                           Z

  Object axes are rotated     Gizmo axes stay aligned
```

### Use Cases

- Moving objects in scene-relative directions
- Aligning objects to scene grid
- Consistent manipulation regardless of object orientation
- Level editing with grid alignment

## Local Mode

In local mode, gizmo axes align with the object's current rotation.

### Behavior

- **X axis**: Points along object's local +X (red arrow direction)
- **Y axis**: Points along object's local +Y (green arrow direction)
- **Z axis**: Points along object's local +Z (blue arrow direction)

### Visual Example

```
Object rotated 45° around Y:

    Y   ╲
    │    ╲  Object
    │     ╲
    └───── X
   ╱
  Z

  Object axes are rotated     Gizmo follows object rotation
    ╲ Y
     ╲│
      ╲
       ╲ X
```

### Use Cases

- Moving objects along their own axes
- "Forward/backward" relative to object facing
- Character controllers
- Vehicle movement in facing direction

## Implementation Details

### Axis Calculation

The gizmo computes axis directions based on transform mode:

```qml
readonly property var currentAxes: {
    if (transformMode === GizmoEnums.TransformMode.Local && targetNode) {
        // Extract axes from target's quaternion rotation
        return GizmoMath.getLocalAxes(targetNode.rotation)
    } else {
        // World axes are fixed
        return {
            x: Qt.vector3d(1, 0, 0),
            y: Qt.vector3d(0, 1, 0),
            z: Qt.vector3d(0, 0, 1)
        }
    }
}
```

### Delta Signal Parameter

The `transformMode` is passed in delta signals so controllers can handle it appropriately:

```qml
// Signal includes transform mode (int value from GizmoEnums.TransformMode)
signal axisTranslationDelta(int axis, int transformMode, real delta, bool snapActive)
```

### Controller Handling

#### World Mode Controller

```qml
onAxisTranslationDelta: function(axis, transformMode, delta, snap) {
    // In world mode, delta is in world coordinates
    var pos = dragStartPos
    if (axis === GizmoEnums.Axis.X) pos.x += delta
    else if (axis === GizmoEnums.Axis.Y) pos.y += delta
    else if (axis === GizmoEnums.Axis.Z) pos.z += delta
    targetNode.position = pos
}
```

#### Local Mode Controller

```qml
onAxisTranslationDelta: function(axis, transformMode, delta, snap) {
    if (transformMode === GizmoEnums.TransformMode.Local) {
        // Get the object's local axis in world space
        var localAxes = GizmoMath.getLocalAxes(targetNode.rotation)
        var axisDir
        if (axis === GizmoEnums.Axis.X) axisDir = localAxes.x
        else if (axis === GizmoEnums.Axis.Y) axisDir = localAxes.y
        else if (axis === GizmoEnums.Axis.Z) axisDir = localAxes.z

        // Apply delta along local axis
        targetNode.position = dragStartPos.plus(axisDir.times(delta))
    } else {
        // World mode - direct application
        var pos = dragStartPos
        if (axis === GizmoEnums.Axis.X) pos.x += delta
        else if (axis === GizmoEnums.Axis.Y) pos.y += delta
        else if (axis === GizmoEnums.Axis.Z) pos.z += delta
        targetNode.position = pos
    }
}
```

## Mode Switching UI

Common pattern for toggling between modes:

```qml
Row {
    RadioButton {
        text: "World"
        checked: gizmo.transformMode === GizmoEnums.TransformMode.World
        onClicked: gizmo.transformMode = GizmoEnums.TransformMode.World
    }
    RadioButton {
        text: "Local"
        checked: gizmo.transformMode === GizmoEnums.TransformMode.Local
        onClicked: gizmo.transformMode = GizmoEnums.TransformMode.Local
    }
}

TranslationGizmo {
    id: gizmo
    // transformMode bound to UI selection
}
```

### Keyboard Shortcut

```qml
Shortcut {
    sequence: "G"  // Common shortcut in 3D software
    onActivated: {
        gizmo.transformMode = gizmo.transformMode === GizmoEnums.TransformMode.World
            ? GizmoEnums.TransformMode.Local
            : GizmoEnums.TransformMode.World
    }
}
```

## Rotation in Local Mode

Local mode is particularly useful for rotation:

```qml
RotationGizmo {
    transformMode: GizmoEnums.TransformMode.Local
    // Rotation circles follow object's orientation
}
```

### Gimbal Lock Consideration

When using local mode for rotation, be aware of gimbal lock:

- Rotating on one axis can align two others
- This makes certain rotations difficult
- Consider providing world mode as fallback
- Or implement quaternion-based rotation UI

## Scale in Local Mode

For scale operations:

- World mode: Scale along scene axes (can cause shearing with rotated objects)
- Local mode: Scale along object's own axes (maintains object proportions)

```qml
ScaleGizmo {
    transformMode: GizmoEnums.TransformMode.Local  // Usually preferred for scaling
}
```

## Visual Feedback

The gizmo automatically repaints when the object rotates (in local mode):

```qml
Connections {
    target: root.targetNode
    enabled: root.transformMode === GizmoEnums.TransformMode.Local
    function onRotationChanged() {
        canvas.requestPaint()
    }
}
```

This ensures the gizmo visually follows the object's orientation.

## Best Practices

1. **Default to World Mode** for general scene editing
2. **Use Local Mode** for character/vehicle control
3. **Provide Easy Switching** via keyboard shortcut or UI toggle
4. **Consider Context** - some tools (like scale) often work better in local mode
5. **Visual Indicator** - show current mode in UI to avoid confusion

## See Also

- [Controller Pattern](controller-pattern.md) - Signal handling patterns
- [TranslationGizmo API](../api-reference/translation-gizmo.md)
- [RotationGizmo API](../api-reference/rotation-gizmo.md)
- [ScaleGizmo API](../api-reference/scale-gizmo.md)

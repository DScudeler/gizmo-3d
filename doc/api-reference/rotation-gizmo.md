# RotationGizmo API Reference

Interactive 3D rotation gizmo with circular handles for axis-aligned rotations.

## Import

```qml
import Gizmo3D 1.0
```

## Overview

The **RotationGizmo** provides visual circle handles for rotating 3D objects around axes (X, Y, Z). It renders perspective-correct circles using Canvas 2D while performing 3D geometric calculations for angle measurement and rotation manipulation.

**Key Features**:
- Axis-aligned rotation circles (red=X, green=Y, blue=Z)
- Visual arc feedback showing rotation angle during drag
- Angle snapping with absolute or relative modes
- Signal-based manipulation pattern for quaternion control
- Geometric hit detection for precise circle interaction
- Automatic visual updates on camera, position, or rotation changes

## Basic Usage

```qml
import QtQuick
import QtQuick3D
import Gizmo3D 1.0

View3D {
    id: view3d
    anchors.fill: parent
    camera: PerspectiveCamera { position: Qt.vector3d(0, 200, 300) }

    Model {
        id: targetCube
        source: "#Cube"
        materials: PrincipledMaterial { baseColor: "#ff80c0" }
    }
}

RotationGizmo {
    id: rotationGizmo
    anchors.fill: parent
    view3d: view3d
    targetNode: targetCube
    snapEnabled: true
    snapAngle: 15.0
}

SimpleController {
    gizmo: rotationGizmo
    targetNode: targetCube
}
```

## Properties

### Required Properties

#### `view3d : View3D`

Reference to the View3D component containing the 3D scene.

**Required**: Yes

**Type**: View3D

**Description**: The gizmo uses the View3D's coordinate mapping functions to convert between world and screen space for perspective-correct circle rendering.

```qml
RotationGizmo {
    view3d: myView3D  // Must reference the View3D
}
```

---

#### `targetNode : Node`

The 3D object to manipulate (used for visual tracking).

**Required**: Yes (for visual tracking)

**Type**: Node (Model, Node, or any Qt Quick 3D object)

**Description**: The gizmo renders circles at the `targetNode`'s position and monitors it for position and rotation changes to trigger repaints. The gizmo does **not** directly modify the target node; rotation is performed through signals.

```qml
RotationGizmo {
    targetNode: myCube  // The object being rotated
}
```

### Optional Properties

#### `gizmoSize : real`

Screen-space radius of the rotation circles in pixels.

**Type**: real

**Default**: `80.0`

**Description**: Controls the radius of the circle handles in screen space. The gizmo automatically scales to maintain constant screen-space size regardless of camera distance.

```qml
RotationGizmo {
    gizmoSize: 100.0  // Larger circles
}
```

---

#### `snapEnabled : bool`

Enable angle snapping.

**Type**: bool

**Default**: `false`

**Description**: When enabled, rotation angles are snapped to increments defined by `snapAngle`.

```qml
RotationGizmo {
    snapEnabled: true
    snapAngle: 15.0  // Snap to 15-degree increments
}
```

---

#### `snapAngle : real`

Angular snap increment in degrees.

**Type**: real

**Default**: `15.0`

**Units**: Degrees

**Description**: The angular spacing for snapping. Common values: 15° (24 steps per revolution), 45° (8 steps), 90° (4 steps).

```qml
RotationGizmo {
    snapEnabled: true
    snapAngle: 45.0  // Snap to 45-degree increments
}
```

---

#### `snapToAbsolute : bool`

Snap to world angles or relative to drag start angle.

**Type**: bool

**Default**: `true`

**Description**:
- `true`: Snap to absolute world angles (e.g., 0°, 15°, 30°, 45°...)
- `false`: Snap relative to drag start angle (e.g., 12°, 27°, 42°... if drag started at 12°)

```qml
RotationGizmo {
    snapEnabled: true
    snapAngle: 15.0
    snapToAbsolute: true  // Snap to world angles
}
```

### Read-Only Properties

#### `activeAxis : int`

Currently dragged rotation axis (uses `GizmoEnums.Axis` values).

**Type**: int

**Read-Only**: Yes

**Values**:
- `GizmoEnums.Axis.None` (0): No axis active
- `GizmoEnums.Axis.X` (1): X axis (red circle, YZ plane rotation) active
- `GizmoEnums.Axis.Y` (2): Y axis (green circle, ZX plane rotation) active
- `GizmoEnums.Axis.Z` (3): Z axis (blue circle, XY plane rotation) active

```qml
RotationGizmo {
    id: gizmo
}

Text {
    text: gizmo.activeAxis === GizmoEnums.Axis.X ? "Rotating around X axis" : "Not rotating X"
}
```

---

#### `dragStartAngle : real`

Angle in radians at the start of the drag.

**Type**: real

**Read-Only**: Yes

**Units**: Radians

**Description**: The angle where the drag began, used internally for delta calculation. Reset to 0.0 when drag ends.

---

#### `currentAngle : real`

Current angle in radians during the drag.

**Type**: real

**Read-Only**: Yes

**Units**: Radians

**Description**: The current angle during drag, updated continuously as the mouse moves. Used to render the visual arc feedback.

---

#### `targetPosition : vector3d`

Cached position of the target node.

**Type**: vector3d

**Read-Only**: Yes

**Description**: Automatically updated via property binding when `targetNode.position` changes. Used internally for rendering circles at the correct location.

## Signals

### Rotation Signals

#### `rotationStarted(int axis)`

Emitted when rotation drag begins.

**Parameters**:
- `axis` (int): The rotation axis (`GizmoEnums.Axis.X`, `GizmoEnums.Axis.Y`, or `GizmoEnums.Axis.Z`)

**Usage**: Store the initial rotation (quaternion or euler) of the target node.

```qml
RotationGizmo {
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    onRotationStarted: function(axis) {
        dragStartRot = targetCube.rotation
        console.log("Started rotating around axis:", axis)
    }
}
```

---

#### `rotationDelta(int axis, int transformMode, real angleDegrees, bool snapActive)`

Emitted continuously during rotation drag with angular displacement.

**Parameters**:
- `axis` (int): The rotation axis (`GizmoEnums.Axis.X`, `GizmoEnums.Axis.Y`, or `GizmoEnums.Axis.Z`)
- `transformMode` (int): Current transform mode (`GizmoEnums.TransformMode.World` or `GizmoEnums.TransformMode.Local`)
- `angleDegrees` (real): Angular displacement in degrees since drag started
- `snapActive` (bool): Whether angle snapping was applied to this delta

**Emission Frequency**: Every mouse move during drag

**Usage**: Compose the rotation quaternion and apply it to the target node.

```qml
RotationGizmo {
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
        // Determine rotation axis vector
        var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                    : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)

        // Create quaternion for rotation delta
        var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)

        // Compose with drag start rotation
        targetCube.rotation = deltaQuat.times(dragStartRot)
    }
}
```

**Important**: The `angleDegrees` parameter is cumulative from drag start, not incremental. Always compose with the `dragStartRot`, not the current rotation.

---

#### `rotationEnded(int axis)`

Emitted when rotation drag ends.

**Parameters**:
- `axis` (int): The rotation axis that was being dragged (`GizmoEnums.Axis.X`, `GizmoEnums.Axis.Y`, or `GizmoEnums.Axis.Z`)

**Usage**: Finalize the rotation, create undo history, or perform validation.

```qml
RotationGizmo {
    onRotationEnded: function(axis) {
        console.log("Finished rotating around axis:", axis)
        // Commit to undo stack, normalize quaternion, etc.
    }
}
```

## Visual Customization

### Circle Colors

**Read-Only Color Properties**:
- `xAxisColor`: Red (active=#ff6666, inactive=#ff0000)
- `yAxisColor`: Green (active=#66ff66, inactive=#00ff00)
- `zAxisColor`: Blue (active=#6666ff, inactive=#0000ff)

**Note**: Colors automatically lighten when the circle is active (being dragged). Active circles also render with thicker lines (4px vs 2px) and display a filled arc showing the rotation angle.

### Visual Feedback

During rotation:
- **Active Circle**: Thicker outline (4px), highlighted color, filled arc showing rotation
- **Inactive Circles**: Thin outline (2px), standard color
- **Arc Fill**: Semi-transparent pie slice from center to perimeter showing rotation angle

## Implementation Details

### Coordinate System

The gizmo uses Qt Quick 3D's right-handed coordinate system:
- **X axis rotation** (red): Around X, in YZ plane
- **Y axis rotation** (green): Around Y, in ZX plane
- **Z axis rotation** (blue): Around Z, in XY plane

### Rotation Planes

Each circle represents rotation in a specific plane:

| Circle Color | Rotation Axis | Plane | Description |
|--------------|---------------|-------|-------------|
| Red | X | YZ | Rotation around X axis, circle in YZ plane |
| Green | Y | ZX | Rotation around Y axis, circle in ZX plane |
| Blue | Z | XY | Rotation around Z axis, circle in XY plane |

### Hit Detection

The gizmo uses geometric calculations for circle hit detection:
- **Method**: Distance from mouse to polyline (64 segments)
- **Hit Threshold**: 8 pixels from circle perimeter
- **Priority**: Closest circle within threshold wins
- **Algorithm**: Tests all three circles, selects nearest

### Angle Calculation

Angles are calculated using ray-plane intersection:
1. **Ray Construction**: Camera position and mouse direction in world space
2. **Plane Intersection**: Ray intersects the rotation plane at a 3D point
3. **Angle Measurement**: Angle between reference axis and point vector from center
4. **Delta Calculation**: Difference between current and drag start angles
5. **Normalization**: Angle deltas normalized to [-180°, +180°] range

### Rendering Strategy

- **Canvas Type**: Threaded with FramebufferObject render target
- **Circle Sampling**: 64 segments for smooth perspective-correct circles
- **Arc Rendering**: Filled pie slice from center using segment indices
- **Repaint Triggers**:
  - Target node position, rotation, or euler rotation changes
  - Camera position or rotation changes
  - Mouse drag operations
  - Axis activation/deactivation

### Quaternion Composition

**Critical**: Always compose rotation deltas with the drag start rotation:

```qml
// CORRECT: Compose with drag start rotation
var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
targetCube.rotation = deltaQuat.times(dragStartRot)

// INCORRECT: Composing with current rotation accumulates errors
targetCube.rotation = deltaQuat.times(targetCube.rotation)  // ❌ Don't do this
```

This prevents quaternion drift and ensures the rotation matches the visual feedback exactly.

## Common Patterns

### Basic Rotation Controller

```qml
RotationGizmo {
    id: gizmo
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    onRotationStarted: function(axis) {
        dragStartRot = targetCube.rotation
    }

    onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
        var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                    : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)
        var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
        targetCube.rotation = deltaQuat.times(dragStartRot)
    }
}
```

### Rotation Constraints

Limit rotation to specific angles:

```qml
RotationGizmo {
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
        // Clamp rotation to ±90 degrees
        var clampedAngle = Math.max(-90, Math.min(90, angleDegrees))

        var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                    : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)
        var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, clampedAngle)
        targetCube.rotation = deltaQuat.times(dragStartRot)
    }
}
```

### Multi-Object Rotation

Rotate multiple objects simultaneously:

```qml
RotationGizmo {
    id: gizmo
    property var selectedObjects: [cube1, cube2, cube3]
    property var dragStartRotations: []

    onRotationStarted: function(axis) {
        dragStartRotations = selectedObjects.map(obj => obj.rotation)
    }

    onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
        var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                    : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)
        var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)

        for (var i = 0; i < selectedObjects.length; i++) {
            selectedObjects[i].rotation = deltaQuat.times(dragStartRotations[i])
        }
    }
}
```

### Undo/Redo Integration

```qml
RotationGizmo {
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    onRotationStarted: function(axis) {
        dragStartRot = targetCube.rotation
    }

    onRotationEnded: function(axis) {
        var finalRot = targetCube.rotation
        undoStack.push(new RotateCommand(targetCube, dragStartRot, finalRot))
    }

    onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
        var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                    : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)
        var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
        targetCube.rotation = deltaQuat.times(dragStartRot)
    }
}
```

### Using Euler Angles

Convert to euler angles if needed:

```qml
RotationGizmo {
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

    onRotationStarted: function(axis) {
        dragStartRot = targetCube.rotation
    }

    onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
        var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                    : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)
        var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
        targetCube.rotation = deltaQuat.times(dragStartRot)
    }

    onRotationEnded: function(axis) {
        // Access euler angles if needed
        console.log("Final euler rotation:", targetCube.eulerRotation)
    }
}
```

## Performance Considerations

- Circle rendering uses 64 segments per circle (192 total segments)
- Canvas repaints are triggered manually via `requestPaint()` for optimal performance
- Geometric calculations are performed once per frame
- Screen-space rendering avoids expensive 3D shader operations
- Threaded canvas rendering prevents UI blocking

## Common Issues

### Rotation Accumulation Errors

**Problem**: Rotation drifts or becomes incorrect over time.

**Solution**: Always compose with `dragStartRot`, not current rotation:

```qml
// CORRECT
targetCube.rotation = deltaQuat.times(dragStartRot)

// INCORRECT - causes drift
targetCube.rotation = deltaQuat.times(targetCube.rotation)
```

### Gimbal Lock

**Problem**: Rotation becomes unpredictable or loses degrees of freedom.

**Solution**: Use quaternions throughout, avoid euler angle intermediate conversions during drag.

### Circle Not Visible

**Problem**: Circles don't appear or are partially clipped.

**Solution**:
- Ensure the gizmo Item is **above** the View3D in the z-order
- Set `z: 1001` on the gizmo to force it on top
- Verify `view3d` and `targetNode` properties are set

## See Also

- [Controller Pattern Guide](../user-guide/controller-pattern.md) - Implementation patterns
- [Snapping Guide](../user-guide/snapping.md) - Angle snap configuration
- [TranslationGizmo API](translation-gizmo.md) - Translation manipulation
- [GlobalGizmo API](global-gizmo.md) - Combined translation/rotation
- [GizmoMath API](gizmo-math.md) - Quaternion utilities
- [Undo/Redo Example](../advanced/undo-redo.md) - Command pattern integration

# TranslationGizmo API Reference

Interactive 3D translation gizmo with axis and planar manipulation handles.

## Import

```qml
import Gizmo3D 1.0
```

## Overview

The **TranslationGizmo** provides visual handles for translating 3D objects along axes (X, Y, Z) and within planes (XY, XZ, YZ). It renders arrows and plane squares using Canvas 2D in screen space while performing 3D geometric calculations for precise manipulation.

**Key Features**:
- Axis-aligned translation (red=X, green=Y, blue=Z arrows)
- Planar translation (yellow=XY, magenta=XZ, cyan=YZ squares)
- Grid snapping with absolute or relative modes
- Signal-based manipulation pattern for external control
- Geometric hit detection for precise interaction
- Automatic visual updates on camera or target movement

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
        materials: PrincipledMaterial { baseColor: "#4080ff" }
    }
}

TranslationGizmo {
    id: gizmo
    anchors.fill: parent
    view3d: view3d
    targetNode: targetCube
    snapEnabled: true
    snapIncrement: 1.0
}

SimpleController {
    gizmo: gizmo
    targetNode: targetCube
}
```

## Properties

### Required Properties

#### `view3d : View3D`

Reference to the View3D component containing the 3D scene.

**Required**: Yes

**Type**: View3D

**Description**: The gizmo uses the View3D's coordinate mapping functions (`mapFrom3DScene`, `mapTo3DScene`) to convert between world and screen space. This property must be set for the gizmo to function.

```qml
TranslationGizmo {
    view3d: myView3D  // Must reference the View3D
}
```

---

#### `targetNode : Node`

The 3D object to manipulate (used for visual tracking).

**Required**: Yes (for visual tracking)

**Type**: Node (Model, Node, or any Qt Quick 3D object)

**Description**: The gizmo renders at the `targetNode`'s position and monitors it for position changes to trigger repaints. Note that the gizmo does **not** directly modify the target node; manipulation is performed through signals.

```qml
TranslationGizmo {
    targetNode: myCube  // The object being manipulated
}
```

### Optional Properties

#### `gizmoSize : real`

Screen-space size of the gizmo in pixels.

**Type**: real

**Default**: `100.0`

**Description**: Controls the length of the arrow handles in screen space. The gizmo automatically scales to maintain constant screen-space size regardless of camera distance.

```qml
TranslationGizmo {
    gizmoSize: 120.0  // Larger arrows
}
```

---

#### `snapEnabled : bool`

Enable grid snapping.

**Type**: bool

**Default**: `false`

**Description**: When enabled, translation deltas are snapped to grid increments defined by `snapIncrement`.

```qml
TranslationGizmo {
    snapEnabled: true
    snapIncrement: 5.0  // Snap to 5-unit grid
}
```

---

#### `snapIncrement : real`

Grid size for snapping.

**Type**: real

**Default**: `1.0`

**Units**: World-space units

**Description**: The spacing of the snap grid in world coordinates. Used when `snapEnabled` is `true`.

```qml
TranslationGizmo {
    snapEnabled: true
    snapIncrement: 0.5  // Snap every 0.5 units
}
```

---

#### `snapToAbsolute : bool`

Snap to world grid or relative to drag start position.

**Type**: bool

**Default**: `true`

**Description**:
- `true`: Snap to absolute world grid (e.g., 0, 1, 2, 3...)
- `false`: Snap relative to drag start position (e.g., 2.3, 3.3, 4.3... if drag started at 2.3)

```qml
TranslationGizmo {
    snapEnabled: true
    snapIncrement: 1.0
    snapToAbsolute: true  // Snap to world grid
}
```

### Read-Only Properties

#### `activeAxis : int`

Currently dragged axis (uses `GizmoEnums.Axis` values).

**Type**: int

**Read-Only**: Yes

**Values**:
- `GizmoEnums.Axis.None` (0): No axis active
- `GizmoEnums.Axis.X` (1): X axis (red arrow) active
- `GizmoEnums.Axis.Y` (2): Y axis (green arrow) active
- `GizmoEnums.Axis.Z` (3): Z axis (blue arrow) active

```qml
TranslationGizmo {
    id: gizmo
}

Text {
    text: gizmo.activeAxis === GizmoEnums.Axis.X ? "Dragging X axis" : "Not dragging X"
}
```

---

#### `activePlane : int`

Currently dragged plane (uses `GizmoEnums.Plane` values).

**Type**: int

**Read-Only**: Yes

**Values**:
- `GizmoEnums.Plane.None` (0): No plane active
- `GizmoEnums.Plane.XY` (1): XY plane (yellow square) active
- `GizmoEnums.Plane.XZ` (2): XZ plane (magenta square) active
- `GizmoEnums.Plane.YZ` (3): YZ plane (cyan square) active

```qml
TranslationGizmo {
    id: gizmo
}

Text {
    text: gizmo.activePlane === GizmoEnums.Plane.XY ? "Dragging in XY plane" : "Not dragging plane"
}
```

---

#### `targetPosition : vector3d`

Cached position of the target node.

**Type**: vector3d

**Read-Only**: Yes

**Description**: Automatically updated via property binding when `targetNode.position` changes. Used internally for rendering.

## Signals

### Axis Translation Signals

#### `axisTranslationStarted(int axis)`

Emitted when axis drag begins.

**Parameters**:
- `axis` (int): The axis being dragged (`GizmoEnums.Axis.X`, `GizmoEnums.Axis.Y`, or `GizmoEnums.Axis.Z`)

**Usage**: Store the initial position of the target node.

```qml
TranslationGizmo {
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    onAxisTranslationStarted: function(axis) {
        dragStartPos = targetCube.position
        console.log("Started dragging axis:", axis)
    }
}
```

---

#### `axisTranslationDelta(int axis, int transformMode, real delta, bool snapActive)`

Emitted continuously during axis drag with displacement delta.

**Parameters**:
- `axis` (int): The axis being dragged (`GizmoEnums.Axis.X`, `GizmoEnums.Axis.Y`, or `GizmoEnums.Axis.Z`)
- `transformMode` (int): Current transform mode (`GizmoEnums.TransformMode.World` or `GizmoEnums.TransformMode.Local`)
- `delta` (real): Displacement along the axis since drag started (world units)
- `snapActive` (bool): Whether snapping was applied to this delta

**Emission Frequency**: Every mouse move during drag

**Usage**: Apply the delta to the target node's position along the specified axis.

```qml
TranslationGizmo {
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    onAxisTranslationDelta: function(axis, transformMode, delta, snapActive) {
        var pos = dragStartPos
        if (axis === GizmoEnums.Axis.X) pos.x += delta
        else if (axis === GizmoEnums.Axis.Y) pos.y += delta
        else if (axis === GizmoEnums.Axis.Z) pos.z += delta
        targetCube.position = pos
    }
}
```

---

#### `axisTranslationEnded(int axis)`

Emitted when axis drag ends.

**Parameters**:
- `axis` (int): The axis that was being dragged (`GizmoEnums.Axis.X`, `GizmoEnums.Axis.Y`, or `GizmoEnums.Axis.Z`)

**Usage**: Finalize the transformation, create undo history, or perform validation.

```qml
TranslationGizmo {
    onAxisTranslationEnded: function(axis) {
        console.log("Finished dragging axis:", axis)
        // Commit to undo stack, validate bounds, etc.
    }
}
```

### Plane Translation Signals

#### `planeTranslationStarted(int plane)`

Emitted when planar drag begins.

**Parameters**:
- `plane` (int): The plane being dragged (`GizmoEnums.Plane.XY`, `GizmoEnums.Plane.XZ`, or `GizmoEnums.Plane.YZ`)

**Usage**: Store the initial position of the target node.

```qml
TranslationGizmo {
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    onPlaneTranslationStarted: function(plane) {
        dragStartPos = targetCube.position
        console.log("Started dragging plane:", plane)
    }
}
```

---

#### `planeTranslationDelta(int plane, int transformMode, vector3d delta, bool snapActive)`

Emitted continuously during planar drag with displacement delta.

**Parameters**:
- `plane` (int): The plane being dragged (`GizmoEnums.Plane.XY`, `GizmoEnums.Plane.XZ`, or `GizmoEnums.Plane.YZ`)
- `transformMode` (int): Current transform mode (`GizmoEnums.TransformMode.World` or `GizmoEnums.TransformMode.Local`)
- `delta` (vector3d): Displacement vector since drag started (local units, consistent with axis translation)
  - **XY plane**: `delta.x` and `delta.y` contain movement along local X and Y axes, `delta.z` is 0
  - **XZ plane**: `delta.x` and `delta.z` contain movement along local X and Z axes, `delta.y` is 0
  - **YZ plane**: `delta.y` and `delta.z` contain movement along local Y and Z axes, `delta.x` is 0
- `snapActive` (bool): Whether snapping was applied to this delta

**Emission Frequency**: Every mouse move during drag

**Usage**: Apply the full delta vector to the target node's position.

```qml
TranslationGizmo {
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    onPlaneTranslationDelta: function(plane, delta, snapActive) {
        targetCube.position = Qt.vector3d(
            dragStartPos.x + delta.x,
            dragStartPos.y + delta.y,
            dragStartPos.z + delta.z
        )
    }
}
```

---

#### `planeTranslationEnded(int plane)`

Emitted when planar drag ends.

**Parameters**:
- `plane` (int): The plane that was being dragged (`GizmoEnums.Plane.XY`, `GizmoEnums.Plane.XZ`, or `GizmoEnums.Plane.YZ`)

**Usage**: Finalize the transformation, create undo history, or perform validation.

```qml
TranslationGizmo {
    onPlaneTranslationEnded: function(plane) {
        console.log("Finished dragging plane:", plane)
        // Commit to undo stack, validate bounds, etc.
    }
}
```

## Visual Customization

### Axis Colors

**Read-Only Color Properties**:
- `xAxisColor`: Red (active=#ff6666, inactive=#ff0000)
- `yAxisColor`: Green (active=#66ff66, inactive=#00ff00)
- `zAxisColor`: Blue (active=#6666ff, inactive=#0000ff)

### Plane Colors

**Read-Only Color Properties**:
- `xyPlaneColor`: Yellow (active=#ffff99, inactive=#ffff00)
- `xzPlaneColor`: Magenta (active=#ff99ff, inactive=#ff00ff)
- `yzPlaneColor`: Cyan (active=#99ffff, inactive=#00ffff)

**Note**: Colors automatically lighten when the handle is active (being dragged).

## Implementation Details

### Coordinate System

The gizmo uses Qt Quick 3D's right-handed coordinate system:
- **X axis**: Right (red arrow)
- **Y axis**: Up (green arrow)
- **Z axis**: Forward (blue arrow)

### Hit Detection

The gizmo uses geometric calculations for precise hit detection:
- **Axes**: Distance from mouse to line segment in screen space
- **Planes**: Point-in-quad test in screen space
- **Hit Threshold**: 10 pixels for axis selection
- **Priority**: Axes are tested before planes (axes have priority)

### Rendering Strategy

- **Canvas Type**: Threaded with FramebufferObject render target
- **Coordinate Mapping**: Uses `View3D.mapFrom3DScene` for world-to-screen conversion
- **Repaint Triggers**:
  - Target node position changes
  - Camera position or rotation changes
  - Mouse drag operations
  - Axis/plane activation/deactivation

### Performance Considerations

- Canvas repaints are triggered manually via `requestPaint()` for optimal performance
- Geometric calculations are performed once per frame
- Screen-space rendering avoids expensive 3D shader operations

## Common Patterns

### Transform Validation

Reject invalid transformations:

```qml
TranslationGizmo {
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    onAxisTranslationDelta: function(axis, transformMode, delta, snapActive) {
        var newPos = calculateNewPosition(axis, delta)

        // Validate bounds
        if (isWithinBounds(newPos)) {
            targetCube.position = newPos
        }
    }

    function isWithinBounds(pos) {
        return pos.x >= -100 && pos.x <= 100 &&
               pos.y >= 0 && pos.y <= 200 &&
               pos.z >= -100 && pos.z <= 100
    }

    function calculateNewPosition(axis, delta) {
        if (axis === GizmoEnums.Axis.X) return Qt.vector3d(dragStartPos.x + delta, dragStartPos.y, dragStartPos.z)
        if (axis === GizmoEnums.Axis.Y) return Qt.vector3d(dragStartPos.x, dragStartPos.y + delta, dragStartPos.z)
        if (axis === GizmoEnums.Axis.Z) return Qt.vector3d(dragStartPos.x, dragStartPos.y, dragStartPos.z + delta)
        return dragStartPos
    }
}
```

### Multi-Object Manipulation

Manipulate multiple objects simultaneously:

```qml
TranslationGizmo {
    id: gizmo
    property var selectedObjects: [cube1, cube2, cube3]
    property var dragStartPositions: []

    onAxisTranslationStarted: function(axis) {
        dragStartPositions = selectedObjects.map(obj => obj.position)
    }

    onAxisTranslationDelta: function(axis, transformMode, delta, snapActive) {
        for (var i = 0; i < selectedObjects.length; i++) {
            var startPos = dragStartPositions[i]
            if (axis === GizmoEnums.Axis.X) {
                selectedObjects[i].position = Qt.vector3d(startPos.x + delta, startPos.y, startPos.z)
            } else if (axis === GizmoEnums.Axis.Y) {
                selectedObjects[i].position = Qt.vector3d(startPos.x, startPos.y + delta, startPos.z)
            } else if (axis === GizmoEnums.Axis.Z) {
                selectedObjects[i].position = Qt.vector3d(startPos.x, startPos.y, startPos.z + delta)
            }
        }
    }
}
```

### Undo/Redo Integration

Store commands for undo/redo:

```qml
TranslationGizmo {
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
    property int dragAxis: 0
    property int dragPlane: 0

    onAxisTranslationStarted: function(axis) {
        dragStartPos = targetCube.position
        dragAxis = axis
    }

    onAxisTranslationEnded: function(axis) {
        var finalPos = targetCube.position
        undoStack.push(new TranslateCommand(targetCube, dragStartPos, finalPos))
    }

    onPlaneTranslationStarted: function(plane) {
        dragStartPos = targetCube.position
        dragPlane = plane
    }

    onPlaneTranslationEnded: function(plane) {
        var finalPos = targetCube.position
        undoStack.push(new TranslateCommand(targetCube, dragStartPos, finalPos))
    }
}
```

## See Also

- [Controller Pattern Guide](../user-guide/controller-pattern.md) - Implementation patterns
- [Snapping Guide](../user-guide/snapping.md) - Snap configuration details
- [RotationGizmo API](rotation-gizmo.md) - Rotation manipulation
- [GlobalGizmo API](global-gizmo.md) - Combined translation/rotation
- [GizmoMath API](gizmo-math.md) - Utility functions
- [Multi-Object Example](../examples/multi-object.md) - Multi-object manipulation
- [Undo/Redo Example](../advanced/undo-redo.md) - Command pattern integration

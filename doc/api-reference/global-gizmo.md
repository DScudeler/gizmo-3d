# GlobalGizmo API Reference

Combined transformation gizmo with runtime switchable translation, rotation, and scale modes.

## Import

```qml
import Gizmo3D 1.0
```

## Overview

The **GlobalGizmo** combines TranslationGizmo, RotationGizmo, and ScaleGizmo into a unified interface with mode switching. It factors out common properties, forwards signals from all child gizmos, and provides a convenient single-component solution for complete 3D object manipulation.

**Key Features**:
- Mode switching between translate, rotate, scale, or all simultaneously
- World/local transform mode support
- Unified property interface for common settings
- Signal forwarding from all child gizmos
- Automatic z-ordering when multiple modes active
- Simplified integration with single gizmo instance

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
        materials: PrincipledMaterial { baseColor: "#80c040" }
    }
}

GlobalGizmo {
    id: globalGizmo
    anchors.fill: parent
    view3d: view3d
    targetNode: targetCube
    mode: "translate"     // or "rotate", "scale", "both", "all"
    transformMode: GizmoEnums.TransformMode.World  // or GizmoEnums.TransformMode.Local
    snapEnabled: true
}

SimpleController {
    gizmo: globalGizmo
    targetNode: targetCube
}
```

## Properties

### Required Properties

#### `view3d : View3D`

Reference to the View3D component.

**Required**: Yes
**Type**: View3D

#### `targetNode : Node`

The 3D object to manipulate.

**Required**: Yes
**Type**: Node

### Mode Control

#### `mode : string`

Active manipulation mode.

**Type**: string
**Default**: `"translate"`
**Valid Values**:
- `"translate"`: Show only TranslationGizmo
- `"rotate"`: Show only RotationGizmo
- `"scale"`: Show only ScaleGizmo
- `"both"`: Show TranslationGizmo and RotationGizmo (legacy compatibility)
- `"all"`: Show all three gizmos with composite arrow layout

```qml
GlobalGizmo {
    mode: "all"  // Translation arrows (outer) + Scale handles (inner) + Rotation circles
}
```

**Composite Mode ("all")**: In this mode, scale handles occupy the inner portion of arrows (0-50%) and translation arrows occupy the outer portion (50-100%), creating a combined visual appearance.

#### `transformMode : int`

Coordinate system for manipulation.

**Type**: int
**Default**: `GizmoEnums.TransformMode.World`
**Valid Values**:
- `GizmoEnums.TransformMode.World` (0): Axes aligned with global coordinate system
- `GizmoEnums.TransformMode.Local` (1): Axes aligned with object's rotation

```qml
GlobalGizmo {
    transformMode: GizmoEnums.TransformMode.Local  // Gizmo follows object rotation
}
```

### Size Properties

#### `gizmoSize : real`

Base screen-space size for all gizmos.

**Type**: real
**Default**: `80.0`

**Note**: TranslationGizmo automatically scales to `gizmoSize * 1.3` to prevent overlap with RotationGizmo.

### Snap Properties

#### `snapEnabled : bool`

Enable snapping for all gizmos.

**Type**: bool
**Default**: `false`

#### `snapIncrement : real`

Translation grid size (world units).

**Type**: real
**Default**: `1.0`

#### `snapAngle : real`

Rotation angle increment (degrees).

**Type**: real
**Default**: `15.0`

#### `scaleSnapIncrement : real`

Scale increment (0.1 = 10% steps).

**Type**: real
**Default**: `0.1`

#### `snapToAbsolute : bool`

Snap to world grid/angles (true) or relative to drag start (false).

**Type**: bool
**Default**: `true`

### Read-Only Properties

#### `activeAxis : int`

Currently dragged axis from the active gizmo.

**Type**: int
**Read-Only**: Yes

**Behavior**:
- Returns first non-zero activeAxis from child gizmos
- Priority: ScaleGizmo → TranslationGizmo → RotationGizmo

#### `activePlane : int`

Currently dragged plane from TranslationGizmo.

**Type**: int
**Read-Only**: Yes

#### `isActive : bool`

True when any child gizmo is being manipulated.

**Type**: bool
**Read-Only**: Yes

#### `isCompositeMode : bool`

True when `mode === "all"`.

**Type**: bool
**Read-Only**: Yes

## Signals

### Translation Signals (Forwarded)

All TranslationGizmo signals are forwarded:

- `axisTranslationStarted(int axis)`
- `axisTranslationDelta(int axis, string transformMode, real delta, bool snapActive)`
- `axisTranslationEnded(int axis)`
- `planeTranslationStarted(int plane)`
- `planeTranslationDelta(int plane, string transformMode, vector3d delta, bool snapActive)`
- `planeTranslationEnded(int plane)`

See [TranslationGizmo API](translation-gizmo.md#signals) for parameter details.

### Rotation Signals (Forwarded)

All RotationGizmo signals are forwarded:

- `rotationStarted(int axis)`
- `rotationDelta(int axis, string transformMode, real angleDegrees, bool snapActive)`
- `rotationEnded(int axis)`

See [RotationGizmo API](rotation-gizmo.md#signals) for parameter details.

### Scale Signals (Forwarded)

All ScaleGizmo signals are forwarded:

- `scaleStarted(int axis)`
- `scaleDelta(int axis, string transformMode, real scaleFactor, bool snapActive)`
- `scaleEnded(int axis)`

See [ScaleGizmo API](scale-gizmo.md#signals) for parameter details.

## Common Patterns

### Mode Switching with Keyboard

```qml
GlobalGizmo {
    id: gizmo
    mode: "translate"
}

Item {
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_T) gizmo.mode = "translate"
        else if (event.key === Qt.Key_R) gizmo.mode = "rotate"
        else if (event.key === Qt.Key_S) gizmo.mode = "scale"
        else if (event.key === Qt.Key_A) gizmo.mode = "all"
        else if (event.key === Qt.Key_G) {
            // Toggle world/local
            gizmo.transformMode = gizmo.transformMode === GizmoEnums.TransformMode.World
                ? GizmoEnums.TransformMode.Local
                : GizmoEnums.TransformMode.World
        }
    }
}
```

### Mode Toggle Toolbar

```qml
Row {
    Button {
        text: "Translate"
        highlighted: gizmo.mode === "translate"
        onClicked: gizmo.mode = "translate"
    }
    Button {
        text: "Rotate"
        highlighted: gizmo.mode === "rotate"
        onClicked: gizmo.mode = "rotate"
    }
    Button {
        text: "Scale"
        highlighted: gizmo.mode === "scale"
        onClicked: gizmo.mode = "scale"
    }
    Button {
        text: "All"
        highlighted: gizmo.mode === "all"
        onClicked: gizmo.mode = "all"
    }

    // World/Local toggle
    Button {
        text: gizmo.transformMode === GizmoEnums.TransformMode.World ? "World" : "Local"
        onClicked: gizmo.transformMode = gizmo.transformMode === GizmoEnums.TransformMode.World
            ? GizmoEnums.TransformMode.Local
            : GizmoEnums.TransformMode.World
    }
}
```

### Custom Controller for All Modes

```qml
GlobalGizmo {
    id: gizmo
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)
    property vector3d dragStartScale: Qt.vector3d(1, 1, 1)

    // Translation handlers
    onAxisTranslationStarted: (axis) => {
        dragStartPos = targetCube.position
    }
    onAxisTranslationDelta: (axis, mode, delta, snap) => {
        var pos = dragStartPos
        if (axis === GizmoEnums.Axis.X) pos.x += delta
        else if (axis === GizmoEnums.Axis.Y) pos.y += delta
        else if (axis === GizmoEnums.Axis.Z) pos.z += delta
        targetCube.position = pos
    }

    // Rotation handlers
    onRotationStarted: (axis) => {
        dragStartRot = targetCube.rotation
    }
    onRotationDelta: (axis, mode, angle, snap) => {
        var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                    : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                    : Qt.vector3d(0, 0, 1)
        var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angle)
        targetCube.rotation = deltaQuat.times(dragStartRot)
    }

    // Scale handlers
    onScaleStarted: (axis) => {
        dragStartScale = targetCube.scale
    }
    onScaleDelta: (axis, mode, factor, snap) => {
        if (axis === GizmoEnums.Axis.Uniform) {
            // Uniform
            targetCube.scale = Qt.vector3d(
                dragStartScale.x * factor,
                dragStartScale.y * factor,
                dragStartScale.z * factor
            )
        } else {
            var scale = dragStartScale
            if (axis === GizmoEnums.Axis.X) scale.x *= factor
            else if (axis === GizmoEnums.Axis.Y) scale.y *= factor
            else if (axis === GizmoEnums.Axis.Z) scale.z *= factor
            targetCube.scale = scale
        }
    }
}
```

## Implementation Details

### Component Structure

```
GlobalGizmo (Item)
├── ScaleGizmo (visible when mode = "scale" or "all")
│   └── arrowEndRatio: isCompositeMode ? 0.5 : 1.0
├── TranslationGizmo (visible when mode = "translate" or "both" or "all")
│   └── arrowStartRatio: isCompositeMode ? 0.5 : 0.0
├── RotationGizmo (visible when mode = "rotate" or "both" or "all")
│   └── z: 1 (renders on top)
├── Connections → TranslationGizmo (signal forwarding)
├── Connections → RotationGizmo (signal forwarding)
└── Connections → ScaleGizmo (signal forwarding)
```

### Property Binding

| GlobalGizmo Property | Translation | Rotation | Scale |
|---------------------|-------------|----------|-------|
| `view3d` | ✓ | ✓ | ✓ |
| `targetNode` | ✓ | ✓ | ✓ |
| `transformMode` | ✓ | ✓ | ✓ |
| `snapEnabled` | ✓ | ✓ | ✓ |
| `snapToAbsolute` | ✓ | ✓ | ✓ |
| `gizmoSize` | × 1.3 | × 1.0 | × 1.0 |
| `snapIncrement` | ✓ | ✗ | ✗ |
| `snapAngle` | ✗ | ✓ | ✗ |
| `scaleSnapIncrement` | ✗ | ✗ | ✓ |

### Arrow Ratio in Composite Mode

In "all" mode, arrows are divided:
- **ScaleGizmo**: `arrowStartRatio: 0.0`, `arrowEndRatio: 0.5` (inner half)
- **TranslationGizmo**: `arrowStartRatio: 0.5`, `arrowEndRatio: 1.0` (outer half)

This creates a seamless visual where scale handles are near the center and translation arrows extend outward.

## See Also

- [TranslationGizmo API](translation-gizmo.md) - Translation component
- [RotationGizmo API](rotation-gizmo.md) - Rotation component
- [ScaleGizmo API](scale-gizmo.md) - Scale component
- [Controller Pattern Guide](../user-guide/controller-pattern.md) - Signal handling
- [Transform Modes](../user-guide/transform-modes.md) - World vs local modes
- [Snapping Guide](../user-guide/snapping.md) - Snap configuration

# ScaleGizmo API Reference

The ScaleGizmo component provides interactive scale manipulation handles for 3D objects. It displays axis-aligned arrows with square handles for axis-constrained scaling, plus a center handle for uniform scaling.

## Import

```qml
import Gizmo3D 1.0
```

## Properties

### Required Properties

| Property | Type | Description |
|----------|------|-------------|
| `view3d` | View3D | Reference to the View3D containing the 3D scene. Required for coordinate mapping. |
| `targetNode` | Node | The 3D node being manipulated. Used for visual tracking and local mode calculations. |

### Size Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `gizmoSize` | real | 100.0 | Base size of the gizmo in screen-space pixels. |
| `maxScreenSize` | real | 150.0 | Maximum screen-space extent to prevent oversized arrows at close distances. |
| `lineWidth` | real | 4 | Width of the arrow shafts in pixels. |

### Transform Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `transformMode` | string | "world" | Coordinate mode: `"world"` for global axes, `"local"` for object-relative axes. |

### Arrow Ratio Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `arrowStartRatio` | real | 0.0 | Start point of arrows as ratio of gizmoSize (0.0 = center). |
| `arrowEndRatio` | real | 1.0 | End point of arrows as ratio of gizmoSize (1.0 = full length). |

These properties control which portion of the arrow is drawn, useful for composite mode in GlobalGizmo where scale handles occupy the inner portion.

### Snap Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `snapEnabled` | bool | false | Enable scale snapping to increments. |
| `snapIncrement` | real | 0.1 | Scale snap increment (0.1 = 10% steps). |
| `snapToAbsolute` | bool | true | When true, snap to absolute scale values (0.5, 1.0, 1.5...). When false, snap relative to drag start. |

### State Properties (Read-Only)

| Property | Type | Description |
|----------|------|-------------|
| `activeAxis` | int | Currently active axis: 0=none, 1=X, 2=Y, 3=Z, 4=uniform (center handle). |
| `isActive` | bool | True when any axis is being dragged. |
| `targetPosition` | vector3d | Computed position of the target node (updates automatically). |
| `currentAxes` | var | Object containing current X, Y, Z axis vectors based on transformMode. |

### Color Properties (Read-Only)

| Property | Type | Description |
|----------|------|-------------|
| `xAxisColor` | color | X axis color (red, brightens when active). |
| `yAxisColor` | color | Y axis color (green, brightens when active). |
| `zAxisColor` | color | Z axis color (blue, brightens when active). |
| `uniformColor` | color | Center handle color (yellow, brightens when active). |

## Signals

### scaleStarted

```qml
signal scaleStarted(int axis)
```

Emitted when the user begins dragging a scale handle.

**Parameters:**
- `axis`: The axis being scaled (1=X, 2=Y, 3=Z, 4=uniform)

### scaleDelta

```qml
signal scaleDelta(int axis, string transformMode, real scaleFactor, bool snapActive)
```

Emitted continuously during drag with the current scale factor relative to drag start.

**Parameters:**
- `axis`: The axis being scaled (1=X, 2=Y, 3=Z, 4=uniform)
- `transformMode`: Current transform mode (`"world"` or `"local"`)
- `scaleFactor`: Scale multiplier relative to drag start (1.0 = no change, 2.0 = double, 0.5 = half)
- `snapActive`: Whether snapping was applied to this delta

### scaleEnded

```qml
signal scaleEnded(int axis)
```

Emitted when the user releases the scale handle.

**Parameters:**
- `axis`: The axis that was being scaled (1=X, 2=Y, 3=Z, 4=uniform)

## Usage Examples

### Basic Scale Controller

```qml
ScaleGizmo {
    id: scaleGizmo
    view3d: myView3D
    targetNode: myCube

    property vector3d dragStartScale: Qt.vector3d(1, 1, 1)

    onScaleStarted: function(axis) {
        dragStartScale = myCube.scale
    }

    onScaleDelta: function(axis, transformMode, scaleFactor, snapActive) {
        if (axis === 4) {
            // Uniform scaling - apply to all axes
            myCube.scale = Qt.vector3d(
                dragStartScale.x * scaleFactor,
                dragStartScale.y * scaleFactor,
                dragStartScale.z * scaleFactor
            )
        } else if (axis === 1) {
            // X-axis scaling
            myCube.scale = Qt.vector3d(
                dragStartScale.x * scaleFactor,
                dragStartScale.y,
                dragStartScale.z
            )
        } else if (axis === 2) {
            // Y-axis scaling
            myCube.scale = Qt.vector3d(
                dragStartScale.x,
                dragStartScale.y * scaleFactor,
                dragStartScale.z
            )
        } else if (axis === 3) {
            // Z-axis scaling
            myCube.scale = Qt.vector3d(
                dragStartScale.x,
                dragStartScale.y,
                dragStartScale.z * scaleFactor
            )
        }
    }
}
```

### With Snapping Enabled

```qml
ScaleGizmo {
    view3d: myView3D
    targetNode: myCube

    snapEnabled: true
    snapIncrement: 0.25    // Snap to 25% increments
    snapToAbsolute: true   // Snap to 0.25, 0.5, 0.75, 1.0, 1.25, etc.

    property vector3d dragStartScale

    onScaleStarted: dragStartScale = myCube.scale
    onScaleDelta: (axis, mode, factor, snap) => {
        // factor will be snapped to nearest 0.25 increment
        applyScale(axis, dragStartScale, factor)
    }
}
```

### Local Mode Scaling

```qml
ScaleGizmo {
    view3d: myView3D
    targetNode: myCube
    transformMode: "local"  // Scale along object's rotated axes

    property vector3d dragStartScale

    onScaleStarted: dragStartScale = myCube.scale
    onScaleDelta: (axis, mode, factor, snap) => {
        // In local mode, scaling respects object's rotation
        applyScale(axis, dragStartScale, factor)
    }
}
```

### With Minimum Scale Constraint

```qml
ScaleGizmo {
    view3d: myView3D
    targetNode: myCube

    property vector3d dragStartScale
    property real minScale: 0.1
    property real maxScale: 10.0

    onScaleStarted: dragStartScale = myCube.scale

    onScaleDelta: function(axis, mode, factor, snap) {
        // Clamp scale factor
        var clampedFactor = Math.max(minScale / dragStartScale.x,
                                     Math.min(maxScale / dragStartScale.x, factor))

        if (axis === 4) {
            myCube.scale = Qt.vector3d(
                dragStartScale.x * clampedFactor,
                dragStartScale.y * clampedFactor,
                dragStartScale.z * clampedFactor
            )
        }
        // ... handle axis-specific scaling
    }
}
```

## Interaction Behavior

### Axis Scaling (X, Y, Z)

- Click and drag on a square handle at the end of an axis arrow
- Dragging along the screen-projected axis direction increases scale
- Dragging against the axis direction decreases scale
- Scale factor is calculated as: `1.0 + (projectedDisplacement / arrowScreenLength)`
- Minimum scale is clamped to 0.01 to prevent negative/zero scale

### Uniform Scaling (Center Handle)

- Click and drag on the center square handle
- Dragging up (negative Y in screen space) increases scale
- Dragging down increases decreases scale
- Sensitivity: 100 pixels of movement = 2x scale change
- Minimum scale is clamped to 0.01

## Visual Appearance

```
                Y (green)
                │ ■
                │
        ■───────┼───────■ X (red)
               ■│
                │
                ■
                Z (blue)
```

- **Arrows**: Colored lines with square handles at endpoints
- **Center Handle**: Yellow square at gizmo origin for uniform scaling
- **Colors**: X=red, Y=green, Z=blue, Uniform=yellow
- **Active State**: Colors brighten when an axis is being dragged

## See Also

- [TranslationGizmo](translation-gizmo.md) - Position manipulation
- [RotationGizmo](rotation-gizmo.md) - Rotation manipulation
- [GlobalGizmo](global-gizmo.md) - Combined gizmo with mode switching
- [Controller Pattern](../user-guide/controller-pattern.md) - Signal handling patterns
- [Snapping](../user-guide/snapping.md) - Grid snapping configuration

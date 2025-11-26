# Snapping Guide

Configure grid and angle snapping for precise object manipulation.

## Overview

All gizmos support snapping to constrain transformations to grid increments (translation) or angular increments (rotation). Snapping can be absolute (world grid) or relative (from drag start position).

## Translation Snapping

### Enable Snapping

```qml
TranslationGizmo {
    snapEnabled: true
    snapIncrement: 1.0
    snapToAbsolute: true
}
```

### Properties

**`snapEnabled`** - Enable/disable snapping (bool, default: false)

**`snapIncrement`** - Grid spacing in world units (real, default: 1.0)

**`snapToAbsolute`** - Snap mode (bool, default: true)
- `true`: Snap to world grid (0, 1, 2, 3, ...)
- `false`: Snap relative to drag start position

### Common Configurations

```qml
// Fine grid (0.1 units)
TranslationGizmo {
    snapEnabled: true
    snapIncrement: 0.1
}

// Coarse grid (5 units)
TranslationGizmo {
    snapEnabled: true
    snapIncrement: 5.0
}

// Relative snapping
TranslationGizmo {
    snapEnabled: true
    snapIncrement: 1.0
    snapToAbsolute: false  // Snap relative to drag start
}
```

## Rotation Snapping

### Enable Snapping

```qml
RotationGizmo {
    snapEnabled: true
    snapAngle: 15.0
    snapToAbsolute: true
}
```

### Properties

**`snapAngle`** - Angular increment in degrees (real, default: 15.0)

### Common Angles

```qml
// 15-degree increments (24 steps per revolution)
RotationGizmo { snapEnabled: true; snapAngle: 15.0 }

// 45-degree increments (8 steps)
RotationGizmo { snapEnabled: true; snapAngle: 45.0 }

// 90-degree increments (4 steps - cardinal directions)
RotationGizmo { snapEnabled: true; snapAngle: 90.0 }

// 30-degree increments (12 steps)
RotationGizmo { snapEnabled: true; snapAngle: 30.0 }
```

## Runtime Toggle

### Checkbox Control

```qml
CheckBox {
    id: snapCheckbox
    text: "Enable Snap"
    checked: false
}

TranslationGizmo {
    snapEnabled: snapCheckbox.checked
}
```

### Keyboard Modifier

Hold Shift to temporarily enable/disable snapping:

```qml
TranslationGizmo {
    id: gizmo
    property bool shiftPressed: false
    snapEnabled: shiftPressed
}

Item {
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Shift && !event.isAutoRepeat) {
            gizmo.shiftPressed = true
        }
    }
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Shift && !event.isAutoRepeat) {
            gizmo.shiftPressed = false
        }
    }
}
```

## Snap Feedback

Check if snapping was applied via the `snapActive` parameter in delta signals:

```qml
onAxisTranslationDelta: function(axis, delta, snapActive) {
    if (snapActive) {
        console.log("Snapped to grid")
    }
    // Apply transformation...
}
```

## Global Gizmo Snapping

GlobalGizmo provides unified snap control for both translation and rotation:

```qml
GlobalGizmo {
    snapEnabled: true
    snapIncrement: 1.0      // Translation
    snapAngle: 15.0         // Rotation
    snapToAbsolute: true    // Both
}
```

## Best Practices

1. **Default Off**: Start with snapping disabled, let users enable it
2. **Visual Feedback**: Show snap settings in UI (grid size, angle)
3. **Keyboard Toggle**: Provide Shift-key toggle for temporary snap override
4. **Appropriate Increments**: Match grid size to scene scale (0.1 for small objects, 10 for large)
5. **Absolute Mode**: Use absolute snapping for world-aligned grids
6. **Relative Mode**: Use relative snapping for precise offsets

## See Also

- [TranslationGizmo API](../api-reference/translation-gizmo.md#snap-properties)
- [RotationGizmo API](../api-reference/rotation-gizmo.md#snap-properties)
- [GlobalGizmo API](../api-reference/global-gizmo.md#snap-properties)

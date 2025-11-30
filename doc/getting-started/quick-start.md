# Quick Start Guide

Get up and running with Gizmo3D in 5 minutes.

## Installation

See [Installation Guide](installation.md) for detailed build instructions.

## First Gizmo Integration

### Step 1: Import the Module

Add the Gizmo3D import to your QML file:

```qml
import QtQuick
import QtQuick3D
import Gizmo3D 1.0
```

### Step 2: Add a TranslationGizmo

Create a gizmo overlay on your View3D:

```qml
View3D {
    id: view3d
    anchors.fill: parent

    PerspectiveCamera {
        id: camera
        position: Qt.vector3d(0, 200, 300)
        eulerRotation: Qt.vector3d(-30, 0, 0)
    }

    Model {
        id: targetCube
        source: "#Cube"
        materials: PrincipledMaterial {
            baseColor: "#4080ff"
        }
    }

    DirectionalLight {}
}

// Gizmo overlay
TranslationGizmo {
    id: gizmo
    anchors.fill: parent
    view3d: view3d
    targetNode: targetCube
    snapEnabled: true
    snapIncrement: 1.0
}
```

### Step 3: Connect Manipulation Signals

Implement a controller to handle manipulation:

```qml
// Controller for handling transformations
QtObject {
    id: controller
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

    Component.onCompleted: {
        gizmo.axisTranslationStarted.connect(onTranslationStarted)
        gizmo.axisTranslationDelta.connect(onAxisTranslationDelta)
        gizmo.planeTranslationDelta.connect(onPlaneTranslationDelta)
    }

    function onTranslationStarted(axis) {
        dragStartPos = targetCube.position
    }

    function onAxisTranslationDelta(axis, transformMode, delta, snapActive) {
        if (axis === GizmoEnums.Axis.X) {
            targetCube.position = Qt.vector3d(dragStartPos.x + delta, dragStartPos.y, dragStartPos.z)
        } else if (axis === GizmoEnums.Axis.Y) {
            targetCube.position = Qt.vector3d(dragStartPos.x, dragStartPos.y + delta, dragStartPos.z)
        } else if (axis === GizmoEnums.Axis.Z) {
            targetCube.position = Qt.vector3d(dragStartPos.x, dragStartPos.y, dragStartPos.z + delta)
        }
    }

    function onPlaneTranslationDelta(plane, delta, snapActive) {
        targetCube.position = Qt.vector3d(
            dragStartPos.x + delta.x,
            dragStartPos.y + delta.y,
            dragStartPos.z + delta.z
        )
    }
}
```

### Step 4: Use SimpleController (Recommended)

For simpler integration, use the provided SimpleController pattern:

```qml
import Gizmo3D 1.0

TranslationGizmo {
    id: gizmo
    anchors.fill: parent
    view3d: view3d
    targetNode: targetCube
}

// Reusable controller handles all signal connections
SimpleController {
    gizmo: gizmo
    targetNode: targetCube
}
```

## Running the Example

Test the built-in example application:

```bash
# From build directory
./build/debug/examples/gizmo3d_example
```

The example demonstrates all three gizmo types (TranslationGizmo, RotationGizmo, GlobalGizmo) with interactive controls.

## Test Your Integration

1. **Click and drag** the colored arrows (X=red, Y=green, Z=blue) to translate along axes
2. **Click and drag** the colored squares to translate in planes
3. **Enable snapping** to constrain movement to grid increments
4. **Check the console** for any QML errors or warnings

## Next Steps

- Learn about the [Controller Pattern](../user-guide/controller-pattern.md)
- Configure [Snapping](../user-guide/snapping.md) behavior
- Explore the complete [API Reference](../api-reference/translation-gizmo.md)
- Add [RotationGizmo](../api-reference/rotation-gizmo.md) for rotation manipulation
- Use [GlobalGizmo](../api-reference/global-gizmo.md) for combined transform modes

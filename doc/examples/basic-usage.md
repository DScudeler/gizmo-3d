# Basic Usage Examples

Complete code examples demonstrating common Gizmo3D usage patterns.

## Minimal Translation Example

```qml
import QtQuick
import QtQuick.Window
import QtQuick3D
import Gizmo3D 1.0

Window {
    width: 800
    height: 600
    visible: true

    View3D {
        id: view3d
        anchors.fill: parent

        PerspectiveCamera {
            position: Qt.vector3d(0, 200, 300)
            eulerRotation: Qt.vector3d(-30, 0, 0)
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-45, 45, 0)
        }

        Model {
            id: cube
            source: "#Cube"
            materials: PrincipledMaterial {
                baseColor: "#4080ff"
            }
        }
    }

    TranslationGizmo {
        anchors.fill: parent
        view3d: view3d
        targetNode: cube
    }

    SimpleController {
        gizmo: translationGizmo
        targetNode: cube
    }
}
```

## Minimal Rotation Example

```qml
import QtQuick
import QtQuick.Window
import QtQuick3D
import Gizmo3D 1.0

Window {
    width: 800
    height: 600
    visible: true

    View3D {
        id: view3d
        anchors.fill: parent

        PerspectiveCamera {
            position: Qt.vector3d(0, 200, 300)
        }

        DirectionalLight {}

        Model {
            id: cube
            source: "#Cube"
            materials: PrincipledMaterial { baseColor: "#ff80c0" }
        }
    }

    RotationGizmo {
        id: rotationGizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: cube
    }

    SimpleController {
        gizmo: rotationGizmo
        targetNode: cube
    }
}
```

## Combined Translation and Rotation

```qml
import QtQuick
import QtQuick.Window
import QtQuick3D
import Gizmo3D 1.0

Window {
    width: 800
    height: 600
    visible: true

    View3D {
        id: view3d
        anchors.fill: parent
        camera: camera

        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 200, 300)
        }

        DirectionalLight {}

        Model {
            id: cube
            source: "#Cube"
            materials: PrincipledMaterial { baseColor: "#80c040" }
        }
    }

    GlobalGizmo {
        id: gizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: cube
        mode: GizmoEnums.Mode.Both  // Show translation and rotation simultaneously
    }

    SimpleController {
        gizmo: gizmo
        targetNode: cube
    }
}
```

## Mode Switching with Keyboard

```qml
GlobalGizmo {
    id: gizmo
    mode: GizmoEnums.Mode.Translate
}

Item {
    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_T) gizmo.mode = GizmoEnums.Mode.Translate
        else if (event.key === Qt.Key_R) gizmo.mode = GizmoEnums.Mode.Rotate
        else if (event.key === Qt.Key_B) gizmo.mode = GizmoEnums.Mode.Both
    }
}

Text {
    text: "Press T (translate), R (rotate), or B (both)"
}
```

## With Snapping

```qml
TranslationGizmo {
    id: gizmo
    view3d: view3d
    targetNode: cube
    snapEnabled: snapCheckbox.checked
    snapIncrement: 5.0
}

CheckBox {
    id: snapCheckbox
    text: "Snap to 5-unit grid"
}
```

## Camera Control Integration

```qml
View3D {
    id: view3d

    PerspectiveCamera {
        id: camera
        position: Qt.vector3d(0, 200, 300)
    }

    // Disable camera when gizmo is active
    WasdController {
        controlledObject: camera
        enabled: !gizmoActive
    }
}

property bool gizmoActive: gizmo.activeAxis !== GizmoEnums.Axis.None ||
                           rotationGizmo.activeAxis !== GizmoEnums.Axis.None

TranslationGizmo {
    id: gizmo
}

RotationGizmo {
    id: rotationGizmo
}
```

## Multiple Objects with Selection

```qml
View3D {
    id: view3d

    Model { id: cube1; source: "#Cube"; position: Qt.vector3d(-50, 0, 0) }
    Model { id: cube2; source: "#Cube"; position: Qt.vector3d(0, 0, 0) }
    Model { id: cube3; source: "#Cube"; position: Qt.vector3d(50, 0, 0) }
}

property var selectedCube: cube1

TranslationGizmo {
    view3d: view3d
    targetNode: selectedCube
}

Row {
    Button { text: "Cube 1"; onClicked: selectedCube = cube1 }
    Button { text: "Cube 2"; onClicked: selectedCube = cube2 }
    Button { text: "Cube 3"; onClicked: selectedCube = cube3 }
}
```

## With Transform Bounds

```qml
Item {
    property var gizmo: translationGizmo
    property var cube: targetCube
    property vector3d dragStartPos

    Connections {
        target: gizmo

        function onAxisTranslationStarted(axis) {
            dragStartPos = cube.position
        }

        function onAxisTranslationDelta(axis, transformMode, delta, snapActive) {
            var newPos = dragStartPos
            if (axis === GizmoEnums.Axis.X) newPos.x += delta
            else if (axis === GizmoEnums.Axis.Y) newPos.y += delta
            else if (axis === GizmoEnums.Axis.Z) newPos.z += delta

            // Clamp to bounds
            newPos.x = Math.max(-100, Math.min(100, newPos.x))
            newPos.y = Math.max(0, Math.min(200, newPos.y))
            newPos.z = Math.max(-100, Math.min(100, newPos.z))

            cube.position = newPos
        }
    }
}
```

## See Also

- [Quick Start Guide](../getting-started/quick-start.md)
- [Controller Pattern Guide](../user-guide/controller-pattern.md)
- [API Reference](../api-reference/translation-gizmo.md)

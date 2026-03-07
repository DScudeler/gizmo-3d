import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Helpers
import Gizmo3D

Window {
    id: mainWindow
    width: 1600
    height: 1000
    visible: true
    title: "Gizmo3D Stress Test - " + objectCountSlider.value + " Objects"
    color: "#1a1a2e"

    property Node selectedNode: null

    // Deterministic hash from index for pseudo-random distribution
    function hash(n) {
        var x = Math.sin(n * 127.1 + 311.7) * 43758.5453
        return x - Math.floor(x)
    }

    // Mesh sources cycling by index
    readonly property var meshTypes: ["#Cube", "#Sphere", "#Cylinder", "#Cone", "#Cube"]

    // Deterministic color from index
    function colorFromIndex(idx) {
        var h = hash(idx * 7 + 13)
        var s = 0.5 + hash(idx * 3 + 7) * 0.5
        var l = 0.35 + hash(idx * 11 + 3) * 0.3
        return Qt.hsla(h, s, l, 1.0)
    }

    View3D {
        id: view3d
        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            clearColor: "#1a1a2e"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: sceneMSAACheckbox.checked ? SceneEnvironment.MSAA : SceneEnvironment.NoAA
            antialiasingQuality: SceneEnvironment.High
        }

        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 500, 800)
            eulerRotation.x: -30
            clipFar: 50000
            clipNear: 1
        }

        WasdController {
            id: wasdController
            controlledObject: camera
            speed: 200
            shiftSpeed: 600
            enabled: !globalGizmo.isActive
            acceptedButtons: enabled ? Qt.AllButtons : Qt.NoButton
        }

        DirectionalLight {
            eulerRotation.x: -30
            eulerRotation.y: -70
            brightness: 1.0
            ambientColor: Qt.rgba(0.3, 0.3, 0.3, 1.0)
        }

        DirectionalLight {
            eulerRotation.x: 30
            eulerRotation.y: 110
            brightness: 0.5
        }

        // Ground plane
        Model {
            source: "#Rectangle"
            position: Qt.vector3d(0, -10, 0)
            eulerRotation.x: -90
            scale: Qt.vector3d(100, 100, 1)
            materials: PrincipledMaterial {
                baseColor: "#2a2a3e"
                metalness: 0.0
                roughness: 0.9
            }
        }

        // Stress test objects
        Repeater3D {
            model: objectCountSlider.value

            Model {
                required property int index

                // Spread in a grid pattern with deterministic variation
                property real gridSize: Math.ceil(Math.cbrt(objectCountSlider.value))
                property real spacing: 30
                property real ix: index % gridSize
                property real iy: Math.floor(index / gridSize) % gridSize
                property real iz: Math.floor(index / (gridSize * gridSize))

                source: mainWindow.meshTypes[index % 5]

                position: Qt.vector3d(
                    (ix - gridSize / 2) * spacing + (hash(index * 3) - 0.5) * spacing * 0.5,
                    iy * spacing + 10 + (hash(index * 5) - 0.5) * spacing * 0.3,
                    (iz - gridSize / 2) * spacing + (hash(index * 7) - 0.5) * spacing * 0.5
                )

                eulerRotation: Qt.vector3d(
                    hash(index * 13) * 360,
                    hash(index * 17) * 360,
                    hash(index * 23) * 360
                )

                property real s: 0.1 + hash(index * 31) * 0.4
                scale: Qt.vector3d(s, s, s)

                pickable: pickableCheckbox.checked

                materials: PrincipledMaterial {
                    baseColor: mainWindow.colorFromIndex(index)
                    metalness: 0.3
                    roughness: 0.5
                }
            }
        }
    }

    // Click to select objects
    MouseArea {
        anchors.fill: parent
        // Don't intercept when gizmo is active
        enabled: !globalGizmo.isActive
        // Pass through to WasdController for right-click camera
        acceptedButtons: Qt.LeftButton

        onClicked: function(mouse) {
            var result = view3d.pick(mouse.x, mouse.y)
            if (result.objectHit) {
                mainWindow.selectedNode = result.objectHit
            } else {
                mainWindow.selectedNode = null
            }
        }
    }

    // GlobalGizmo overlay
    GlobalGizmo {
        id: globalGizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: mainWindow.selectedNode
        visible: mainWindow.selectedNode !== null
        mode: modeCombo.modeValue
        transformMode: transformModeCombo.transformModeValue
        shapeAntialiasing: gizmoAACheckbox.checked
        z: 1000
    }

    // Controller for gizmo
    SimpleController {
        gizmo: globalGizmo
        targetNode: mainWindow.selectedNode ? mainWindow.selectedNode : dummyNode
    }

    // Dummy node to avoid null binding errors when nothing selected
    Node { id: dummyNode }

    // FPS counter
    FrameAnimation {
        id: fpsCounter
        running: true
        property int frameCount: 0
        property real lastTime: 0
        property real fps: 0

        onTriggered: {
            frameCount++
            var now = new Date().getTime()
            if (lastTime === 0) {
                lastTime = now
                return
            }
            if (now - lastTime >= 1000) {
                fps = frameCount * 1000 / (now - lastTime)
                frameCount = 0
                lastTime = now
            }
        }
    }

    // HUD overlay
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        width: hudColumn.width + 20
        height: hudColumn.height + 20
        color: "#cc000000"
        radius: 5

        Column {
            id: hudColumn
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "Gizmo3D Stress Test"
                color: "white"
                font.pixelSize: 16
                font.bold: true
            }

            Text {
                text: "FPS: " + fpsCounter.fps.toFixed(1)
                color: fpsCounter.fps > 30 ? "#40ff40" : fpsCounter.fps > 15 ? "#ffff40" : "#ff4040"
                font.pixelSize: 14
                font.family: "monospace"
            }

            Text {
                text: "Objects: " + objectCountSlider.value
                color: "#aaaaaa"
                font.pixelSize: 13
            }

            Text {
                text: mainWindow.selectedNode
                    ? "Selected: " + mainWindow.selectedNode.source +
                      "\nPos: (" + mainWindow.selectedNode.position.x.toFixed(1) +
                      ", " + mainWindow.selectedNode.position.y.toFixed(1) +
                      ", " + mainWindow.selectedNode.position.z.toFixed(1) + ")"
                    : "Click an object to select"
                color: mainWindow.selectedNode ? "#80c0ff" : "#666666"
                font.pixelSize: 12
            }

            Text {
                text: "WASD + RMB to navigate"
                color: "#555555"
                font.pixelSize: 11
            }
        }
    }

    // Controls panel
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: controlsColumn.width + 20
        height: controlsColumn.height + 20
        color: "#cc000000"
        radius: 5

        Column {
            id: controlsColumn
            anchors.centerIn: parent
            spacing: 10
            padding: 5

            Text {
                text: "Controls"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            // Object count slider
            Column {
                spacing: 4

                Text {
                    text: "Object Count: " + objectCountSlider.value
                    color: "white"
                    font.pixelSize: 12
                }

                Slider {
                    id: objectCountSlider
                    width: 200
                    from: 1000
                    to: 10000
                    stepSize: 1000
                    value: 10000

                    // Reset selection when count changes
                    onValueChanged: mainWindow.selectedNode = null
                }
            }

            // Mode selector
            Row {
                spacing: 10

                Text {
                    text: "Mode:"
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: modeCombo
                    model: ["Translate", "Rotate", "Scale", "Both", "All"]
                    currentIndex: 4

                    readonly property int modeValue: {
                        switch (currentIndex) {
                            case 0: return GizmoEnums.Mode.Translate
                            case 1: return GizmoEnums.Mode.Rotate
                            case 2: return GizmoEnums.Mode.Scale
                            case 3: return GizmoEnums.Mode.Both
                            case 4: return GizmoEnums.Mode.All
                            default: return GizmoEnums.Mode.Translate
                        }
                    }
                }
            }

            // Transform mode selector
            Row {
                spacing: 10

                Text {
                    text: "Space:"
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: transformModeCombo
                    model: ["World", "Local"]
                    currentIndex: 0

                    readonly property int transformModeValue: currentIndex === 0
                        ? GizmoEnums.TransformMode.World
                        : GizmoEnums.TransformMode.Local
                }
            }

            // Performance toggles
            Text {
                text: "Performance"
                color: "white"
                font.pixelSize: 14
                font.bold: true
                topPadding: 5
            }

            CheckBox {
                id: gizmoAACheckbox
                text: "Gizmo AA"
                checked: true
                contentItem: Text {
                    text: gizmoAACheckbox.text
                    color: "white"
                    leftPadding: gizmoAACheckbox.indicator.width + gizmoAACheckbox.spacing
                    verticalAlignment: Text.AlignVCenter
                }
            }

            CheckBox {
                id: sceneMSAACheckbox
                text: "Scene MSAA"
                checked: true
                contentItem: Text {
                    text: sceneMSAACheckbox.text
                    color: "white"
                    leftPadding: sceneMSAACheckbox.indicator.width + sceneMSAACheckbox.spacing
                    verticalAlignment: Text.AlignVCenter
                }
            }

            CheckBox {
                id: pickableCheckbox
                text: "Pickable"
                checked: true
                onCheckedChanged: mainWindow.selectedNode = null
                contentItem: Text {
                    text: pickableCheckbox.text
                    color: "white"
                    leftPadding: pickableCheckbox.indicator.width + pickableCheckbox.spacing
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Deselect button
            Button {
                text: "Deselect"
                enabled: mainWindow.selectedNode !== null
                onClicked: mainWindow.selectedNode = null
            }
        }
    }
}

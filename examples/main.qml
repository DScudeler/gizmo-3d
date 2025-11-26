import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick3D
import QtQuick3D.Helpers
import Gizmo3D

Window {
    id: mainWindow
    width: 1400
    height: 900
    visible: true
    title: "Gizmo3D - Translation, Rotation, Scale & Global Gizmos Example"
    color: "#2e2e2e"

    View3D {
        id: view3d
        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            clearColor: "#2e2e2e"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        // Camera with orbit controls
        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 250, 400)
            eulerRotation.x: -30
            clipFar: 10000
            clipNear: 1
        }

        WasdController {
            id: wasdController
            controlledObject: camera
            speed: 100
            shiftSpeed: 300
            // Disable camera control when any gizmo is active
            enabled: !translationGizmo.isActive &&
                     !rotationGizmo.isActive &&
                     !scaleGizmo.isActive &&
                     !globalGizmo.isActive
            acceptedButtons: enabled ? Qt.AllButtons : Qt.NoButton
        }

        // Lights
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

        // Target cube for translation (top-left)
        Model {
            id: translationCube
            position: Qt.vector3d(-80, 40, -80)
            source: "#Cube"
            scale: Qt.vector3d(0.5, 0.5, 0.5)

            materials: PrincipledMaterial {
                baseColor: "#4080c0"
                metalness: 0.5
                roughness: 0.3
            }
        }

        // Target cube for rotation (top-right)
        Model {
            id: rotationCube
            position: Qt.vector3d(80, 40, -80)
            source: "#Cube"
            scale: Qt.vector3d(0.5, 0.5, 0.5)

            materials: PrincipledMaterial {
                baseColor: "#c04080"
                metalness: 0.5
                roughness: 0.3
            }
        }

        // Target cube for scale (bottom-left)
        Model {
            id: scaleCube
            position: Qt.vector3d(-80, 40, 80)
            source: "#Cube"
            scale: Qt.vector3d(0.5, 0.5, 0.5)

            materials: PrincipledMaterial {
                baseColor: "#c0c040"
                metalness: 0.5
                roughness: 0.3
            }
        }

        // Target cube for global transform (bottom-right)
        Model {
            id: globalCube
            position: Qt.vector3d(80, 40, 80)
            eulerRotation: Qt.vector3d(0, 45, 0)  // Rotate to demonstrate local mode
            source: "#Cube"
            scale: Qt.vector3d(0.5, 0.5, 0.5)

            materials: PrincipledMaterial {
                baseColor: "#40c080"
                metalness: 0.5
                roughness: 0.3
            }
        }

        // Ground plane for reference
        Model {
            source: "#Rectangle"
            position: Qt.vector3d(0, -10, 0)
            eulerRotation.x: -90
            scale: Qt.vector3d(10, 10, 1)

            materials: PrincipledMaterial {
                baseColor: "#404040"
                metalness: 0.0
                roughness: 0.9
            }
        }
    }

    // Translation Gizmo overlay (top-left cube)
    TranslationGizmo {
        id: translationGizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: translationCube
        gizmoSize: 80
        snapEnabled: translationSnapEnabledCheckbox.checked
        snapIncrement: translationSnapIncrementSpinbox.realValue
        snapToAbsolute: translationSnapToAbsoluteCheckbox.checked
        z: 1000
    }

    // Controller for translation gizmo
    SimpleController {
        gizmo: translationGizmo
        targetNode: translationCube
    }

    // Rotation Gizmo overlay (top-right cube)
    RotationGizmo {
        id: rotationGizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: rotationCube
        gizmoSize: 80
        snapEnabled: rotationSnapEnabledCheckbox.checked
        snapAngle: rotationSnapAngleSpinbox.realValue
        snapToAbsolute: rotationSnapToAbsoluteCheckbox.checked
        z: 1001
    }

    // Controller for rotation gizmo
    SimpleController {
        gizmo: rotationGizmo
        targetNode: rotationCube
    }

    // Scale Gizmo overlay (bottom-left cube)
    ScaleGizmo {
        id: scaleGizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: scaleCube
        gizmoSize: 80
        snapEnabled: scaleSnapEnabledCheckbox.checked
        snapIncrement: scaleSnapIncrementSpinbox.realValue
        z: 1002
    }

    // Controller for scale gizmo
    SimpleController {
        gizmo: scaleGizmo
        targetNode: scaleCube
    }

    // Global Gizmo overlay (bottom-right cube - all three combined)
    GlobalGizmo {
        id: globalGizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: globalCube
        mode: globalModeCombo.model[globalModeCombo.currentIndex]
        transformMode: globalTransformModeCombo.transformModeValue
        snapEnabled: globalSnapEnabledCheckbox.checked
        snapIncrement: translationSnapIncrementSpinbox.realValue
        snapAngle: rotationSnapAngleSpinbox.realValue
        scaleSnapIncrement: scaleSnapIncrementSpinbox.realValue
        snapToAbsolute: true
        z: 1003
    }

    // Controller for global gizmo
    SimpleController {
        gizmo: globalGizmo
        targetNode: globalCube
    }

    // Info text
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        width: infoText.width + 20
        height: infoText.height + 20
        color: "#cc000000"
        radius: 5

        Text {
            id: infoText
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 13
            text: "Gizmo3D Example - Four Gizmo Types\n\n" +
                  "Blue Cube (Top-Left) - Translation:\n" +
                  "  Position: (" +
                  translationCube.position.x.toFixed(1) + ", " +
                  translationCube.position.y.toFixed(1) + ", " +
                  translationCube.position.z.toFixed(1) + ")\n" +
                  "  Drag arrows to translate\n" +
                  "  Snap: " + (translationGizmo.snapEnabled ? "ON (" + translationGizmo.snapIncrement + ")" : "OFF") + "\n\n" +
                  "Pink Cube (Top-Right) - Rotation:\n" +
                  "  Rotation: (" +
                  rotationCube.eulerRotation.x.toFixed(1) + "°, " +
                  rotationCube.eulerRotation.y.toFixed(1) + "°, " +
                  rotationCube.eulerRotation.z.toFixed(1) + "°)\n" +
                  "  Drag circles to rotate\n" +
                  "  Snap: " + (rotationGizmo.snapEnabled ? "ON (" + rotationGizmo.snapAngle + "°)" : "OFF") + "\n\n" +
                  "Yellow Cube (Bottom-Left) - Scale:\n" +
                  "  Scale: (" +
                  scaleCube.scale.x.toFixed(2) + ", " +
                  scaleCube.scale.y.toFixed(2) + ", " +
                  scaleCube.scale.z.toFixed(2) + ")\n" +
                  "  Drag square-ended arrows to scale\n" +
                  "  Snap: " + (scaleGizmo.snapEnabled ? "ON (" + scaleGizmo.snapIncrement + ")" : "OFF") + "\n\n" +
                  "Green Cube (Bottom-Right) - Global:\n" +
                  "  Position: (" +
                  globalCube.position.x.toFixed(1) + ", " +
                  globalCube.position.y.toFixed(1) + ", " +
                  globalCube.position.z.toFixed(1) + ")\n" +
                  "  Rotation: (" +
                  globalCube.eulerRotation.x.toFixed(1) + "°, " +
                  globalCube.eulerRotation.y.toFixed(1) + "°, " +
                  globalCube.eulerRotation.z.toFixed(1) + "°)\n" +
                  "  Scale: (" +
                  globalCube.scale.x.toFixed(2) + ", " +
                  globalCube.scale.y.toFixed(2) + ", " +
                  globalCube.scale.z.toFixed(2) + ")\n" +
                  "  Mode: " + globalGizmo.mode + "\n" +
                  "  Transform: " + globalGizmo.transformMode + "\n" +
                  "  Snap: " + (globalGizmo.snapEnabled ? "ON" : "OFF")
        }
    }

    // Translation Snap Controls
    Rectangle {
        id: translationSnapRect
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: translationSnapControls.width + 20
        height: translationSnapControls.height + 20
        color: "#cc000000"
        radius: 5

        Column {
            id: translationSnapControls
            anchors.centerIn: parent
            spacing: 10
            padding: 5

            Text {
                text: "Translation Snap Settings"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            Row {
                spacing: 10

                CheckBox {
                    id: translationSnapEnabledCheckbox
                    text: "Enable Snap"
                    checked: false

                    contentItem: Text {
                        text: translationSnapEnabledCheckbox.text
                        color: "white"
                        leftPadding: translationSnapEnabledCheckbox.indicator.width + translationSnapEnabledCheckbox.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Row {
                spacing: 10
                enabled: translationSnapEnabledCheckbox.checked

                Text {
                    text: "Increment:"
                    color: enabled ? "white" : "#808080"
                    anchors.verticalCenter: parent.verticalCenter
                }

                SpinBox {
                    id: translationSnapIncrementSpinbox
                    from: 1
                    to: 200
                    value: 10
                    stepSize: 1
                    editable: true

                    property int decimals: 1
                    property real realValue: value / 10

                    validator: DoubleValidator {
                        bottom: Math.min(translationSnapIncrementSpinbox.from, translationSnapIncrementSpinbox.to)
                        top:  Math.max(translationSnapIncrementSpinbox.from, translationSnapIncrementSpinbox.to)
                    }

                    textFromValue: function(value, locale) {
                        return Number(value / 10).toLocaleString(locale, 'f', translationSnapIncrementSpinbox.decimals)
                    }

                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 10
                    }
                }
            }

            Row {
                spacing: 10

                CheckBox {
                    id: translationSnapToAbsoluteCheckbox
                    text: "Snap to World Grid"
                    checked: true
                    enabled: translationSnapEnabledCheckbox.checked

                    contentItem: Text {
                        text: translationSnapToAbsoluteCheckbox.text
                        color: translationSnapToAbsoluteCheckbox.enabled ? "white" : "#808080"
                        leftPadding: translationSnapToAbsoluteCheckbox.indicator.width + translationSnapToAbsoluteCheckbox.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Text {
                text: "Presets:"
                color: "white"
                font.pixelSize: 12
                topPadding: 5
            }

            Row {
                spacing: 5

                Button {
                    text: "0.5"
                    onClicked: {
                        translationSnapEnabledCheckbox.checked = true
                        translationSnapIncrementSpinbox.value = 5
                    }
                }

                Button {
                    text: "1"
                    onClicked: {
                        translationSnapEnabledCheckbox.checked = true
                        translationSnapIncrementSpinbox.value = 10
                    }
                }

                Button {
                    text: "5"
                    onClicked: {
                        translationSnapEnabledCheckbox.checked = true
                        translationSnapIncrementSpinbox.value = 50
                    }
                }

                Button {
                    text: "10"
                    onClicked: {
                        translationSnapEnabledCheckbox.checked = true
                        translationSnapIncrementSpinbox.value = 100
                    }
                }
            }
        }
    }

    // Scale Snap Controls
    Rectangle {
        anchors.top: translationSnapRect.bottom
        anchors.topMargin: 20
        anchors.right: parent.right
        anchors.margins: 10
        width: scaleSnapControls.width + 20
        height: scaleSnapControls.height + 20
        color: "#cc000000"
        radius: 5

        Column {
            id: scaleSnapControls
            anchors.centerIn: parent
            spacing: 10
            padding: 5

            Text {
                text: "Scale Snap Settings"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            Row {
                spacing: 10

                CheckBox {
                    id: scaleSnapEnabledCheckbox
                    text: "Enable Snap"
                    checked: false

                    contentItem: Text {
                        text: scaleSnapEnabledCheckbox.text
                        color: "white"
                        leftPadding: scaleSnapEnabledCheckbox.indicator.width + scaleSnapEnabledCheckbox.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Row {
                spacing: 10
                enabled: scaleSnapEnabledCheckbox.checked

                Text {
                    text: "Increment:"
                    color: enabled ? "white" : "#808080"
                    anchors.verticalCenter: parent.verticalCenter
                }

                SpinBox {
                    id: scaleSnapIncrementSpinbox
                    from: 1
                    to: 200
                    value: 10
                    stepSize: 1
                    editable: true

                    property int decimals: 2
                    property real realValue: value / 100

                    validator: DoubleValidator {
                        bottom: Math.min(scaleSnapIncrementSpinbox.from, scaleSnapIncrementSpinbox.to)
                        top:  Math.max(scaleSnapIncrementSpinbox.from, scaleSnapIncrementSpinbox.to)
                    }

                    textFromValue: function(value, locale) {
                        return Number(value / 100).toLocaleString(locale, 'f', scaleSnapIncrementSpinbox.decimals)
                    }

                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 100
                    }
                }
            }

            Text {
                text: "Presets:"
                color: "white"
                font.pixelSize: 12
                topPadding: 5
            }

            Row {
                spacing: 5

                Button {
                    text: "0.05"
                    onClicked: {
                        scaleSnapEnabledCheckbox.checked = true
                        scaleSnapIncrementSpinbox.value = 5
                    }
                }

                Button {
                    text: "0.1"
                    onClicked: {
                        scaleSnapEnabledCheckbox.checked = true
                        scaleSnapIncrementSpinbox.value = 10
                    }
                }

                Button {
                    text: "0.25"
                    onClicked: {
                        scaleSnapEnabledCheckbox.checked = true
                        scaleSnapIncrementSpinbox.value = 25
                    }
                }

                Button {
                    text: "0.5"
                    onClicked: {
                        scaleSnapEnabledCheckbox.checked = true
                        scaleSnapIncrementSpinbox.value = 50
                    }
                }
            }
        }
    }

    // Rotation Snap Controls
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        width: rotationSnapControls.width + 20
        height: rotationSnapControls.height + 20
        color: "#cc000000"
        radius: 5

        Column {
            id: rotationSnapControls
            anchors.centerIn: parent
            spacing: 10
            padding: 5

            Text {
                text: "Rotation Snap Settings"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            Row {
                spacing: 10

                CheckBox {
                    id: rotationSnapEnabledCheckbox
                    text: "Enable Snap"
                    checked: false

                    contentItem: Text {
                        text: rotationSnapEnabledCheckbox.text
                        color: "white"
                        leftPadding: rotationSnapEnabledCheckbox.indicator.width + rotationSnapEnabledCheckbox.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Row {
                spacing: 10
                enabled: rotationSnapEnabledCheckbox.checked

                Text {
                    text: "Angle:"
                    color: enabled ? "white" : "#808080"
                    anchors.verticalCenter: parent.verticalCenter
                }

                SpinBox {
                    id: rotationSnapAngleSpinbox
                    from: 1
                    to: 180
                    value: 15
                    stepSize: 1
                    editable: true

                    property int decimals: 0
                    property real realValue: value

                    validator: IntValidator {
                        bottom: Math.min(rotationSnapAngleSpinbox.from, rotationSnapAngleSpinbox.to)
                        top: Math.max(rotationSnapAngleSpinbox.from, rotationSnapAngleSpinbox.to)
                    }

                    textFromValue: function(value, locale) {
                        return Number(value).toLocaleString(locale, 'f', 0) + "°"
                    }

                    valueFromText: function(text, locale) {
                        return parseInt(text)
                    }
                }
            }

            Row {
                spacing: 10

                CheckBox {
                    id: rotationSnapToAbsoluteCheckbox
                    text: "Snap to World Angles"
                    checked: true
                    enabled: rotationSnapEnabledCheckbox.checked

                    contentItem: Text {
                        text: rotationSnapToAbsoluteCheckbox.text
                        color: rotationSnapToAbsoluteCheckbox.enabled ? "white" : "#808080"
                        leftPadding: rotationSnapToAbsoluteCheckbox.indicator.width + rotationSnapToAbsoluteCheckbox.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Text {
                text: "Presets:"
                color: "white"
                font.pixelSize: 12
                topPadding: 5
            }

            Row {
                spacing: 5

                Button {
                    text: "5°"
                    onClicked: {
                        rotationSnapEnabledCheckbox.checked = true
                        rotationSnapAngleSpinbox.value = 5
                    }
                }

                Button {
                    text: "15°"
                    onClicked: {
                        rotationSnapEnabledCheckbox.checked = true
                        rotationSnapAngleSpinbox.value = 15
                    }
                }

                Button {
                    text: "45°"
                    onClicked: {
                        rotationSnapEnabledCheckbox.checked = true
                        rotationSnapAngleSpinbox.value = 45
                    }
                }

                Button {
                    text: "90°"
                    onClicked: {
                        rotationSnapEnabledCheckbox.checked = true
                        rotationSnapAngleSpinbox.value = 90
                    }
                }
            }
        }
    }

    // Global Gizmo Controls
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 10
        width: globalGizmoControls.width + 20
        height: globalGizmoControls.height + 20
        color: "#cc000000"
        radius: 5

        Column {
            id: globalGizmoControls
            anchors.centerIn: parent
            spacing: 10
            padding: 5

            Text {
                text: "Global Gizmo Settings"
                color: "white"
                font.pixelSize: 14
                font.bold: true
            }

            Row {
                spacing: 10

                Text {
                    text: "Mode:"
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: globalModeCombo
                    model: ["translate", "rotate", "scale", "both", "all"]
                    currentIndex: 4  // "all" by default
                }
            }

            Row {
                spacing: 10

                CheckBox {
                    id: globalSnapEnabledCheckbox
                    text: "Enable Snap"
                    checked: false

                    contentItem: Text {
                        text: globalSnapEnabledCheckbox.text
                        color: "white"
                        leftPadding: globalSnapEnabledCheckbox.indicator.width + globalSnapEnabledCheckbox.spacing
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Row {
                spacing: 10

                Text {
                    text: "Transform Mode:"
                    color: "white"
                    anchors.verticalCenter: parent.verticalCenter
                }

                ComboBox {
                    id: globalTransformModeCombo
                    model: ["World", "Local"]
                    currentIndex: 0

                    // Convert ComboBox index to GizmoEnums.TransformMode value
                    readonly property int transformModeValue: currentIndex === 0
                        ? GizmoEnums.TransformMode.World
                        : GizmoEnums.TransformMode.Local
                }
            }

            Text {
                text: "Quick Mode Switch:"
                color: "white"
                font.pixelSize: 12
                topPadding: 5
            }

            Row {
                spacing: 5

                Button {
                    text: "Translate"
                    onClicked: globalModeCombo.currentIndex = 0
                }

                Button {
                    text: "Rotate"
                    onClicked: globalModeCombo.currentIndex = 1
                }
            }

            Row {
                spacing: 5

                Button {
                    text: "Scale"
                    onClicked: globalModeCombo.currentIndex = 2
                }

                Button {
                    text: "Both"
                    onClicked: globalModeCombo.currentIndex = 3
                }

                Button {
                    text: "All"
                    onClicked: globalModeCombo.currentIndex = 4
                }
            }
        }
    }
}

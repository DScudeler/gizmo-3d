import QtQuick
import QtQuick.Window
import QtQuick3D
import QtQuick3D.Helpers
import Gizmo3D

Window {
    id: mainWindow
    width: 1280
    height: 720
    visible: true
    title: "Gizmo3D - Translation Gizmo Example"
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
            position: Qt.vector3d(0, 200, 300)
            eulerRotation.x: -30
            clipFar: 10000
            clipNear: 1
        }

        WasdController {
            controlledObject: camera
            speed: 100
            shiftSpeed: 300
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

        // Target cube at origin
        Model {
            id: targetCube
            position: Qt.vector3d(0, 0, 0)
            source: "#Cube"
            scale: Qt.vector3d(0.5, 0.5, 0.5)

            materials: PrincipledMaterial {
                baseColor: "#4080c0"
                metalness: 0.5
                roughness: 0.3
            }
        }

        // Ground plane for reference
        Model {
            source: "#Rectangle"
            position: Qt.vector3d(0, -50, 0)
            eulerRotation.x: -90
            scale: Qt.vector3d(10, 10, 1)

            materials: PrincipledMaterial {
                baseColor: "#404040"
                metalness: 0.0
                roughness: 0.9
            }
        }

        // Grid helper (visual reference)
        Node {
            id: gridHelper

            Repeater {
                model: 21
                Model {
                    readonly property real offset: (index - 10) * 50
                    source: "#Cylinder"
                    position: Qt.vector3d(offset, -50, 0)
                    scale: Qt.vector3d(0.01, 500, 0.01)
                    materials: PrincipledMaterial {
                        baseColor: index === 10 ? "#808080" : "#606060"
                        metalness: 0
                        roughness: 1
                    }
                }
            }

            Repeater {
                model: 21
                Model {
                    readonly property real offset: (index - 10) * 50
                    source: "#Cylinder"
                    position: Qt.vector3d(0, -50, offset)
                    scale: Qt.vector3d(0.01, 500, 0.01)
                    eulerRotation.z: 90
                    materials: PrincipledMaterial {
                        baseColor: index === 10 ? "#808080" : "#606060"
                        metalness: 0
                        roughness: 1
                    }
                }
            }
        }
    }

    // Translation Gizmo overlay
    TranslationGizmo {
        id: gizmo
        anchors.fill: parent
        view3d: view3d
        targetNode: targetCube
        gizmoSize: 80
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
            font.pixelSize: 14
            text: "Translation Gizmo Example\n" +
                  "Cube Position: (" +
                  targetCube.position.x.toFixed(1) + ", " +
                  targetCube.position.y.toFixed(1) + ", " +
                  targetCube.position.z.toFixed(1) + ")\n" +
                  "Drag the arrows to translate the cube"
        }
    }
}

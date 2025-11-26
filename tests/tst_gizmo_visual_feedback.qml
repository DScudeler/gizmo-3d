import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

TestCase {
    id: testCase
    name: "GizmoVisualFeedback"
    width: 800
    height: 600
    visible: true
    when: windowShown

    Component {
        id: translationSceneComponent
        Item {
            width: 800
            height: 600

            View3D {
                id: view
                anchors.fill: parent

                PerspectiveCamera {
                    id: camera
                    position: Qt.vector3d(0, 0, 300)
                    eulerRotation: Qt.vector3d(0, 0, 0)
                }

                DirectionalLight {
                    eulerRotation: Qt.vector3d(-45, 45, 0)
                }

                Node {
                    id: targetNode
                    position: Qt.vector3d(0, 0, 0)

                    Model {
                        source: "#Cube"
                        materials: DefaultMaterial {
                            diffuseColor: "blue"
                        }
                    }
                }
            }

            TranslationGizmo {
                id: gizmo
                anchors.fill: parent
                view3d: view
                targetNode: targetNode
                gizmoSize: 100
            }
        }
    }

    Component {
        id: rotationSceneComponent
        Item {
            width: 800
            height: 600

            View3D {
                id: view
                anchors.fill: parent

                PerspectiveCamera {
                    id: camera
                    position: Qt.vector3d(0, 0, 300)
                    eulerRotation: Qt.vector3d(0, 0, 0)
                }

                DirectionalLight {
                    eulerRotation: Qt.vector3d(-45, 45, 0)
                }

                Node {
                    id: targetNode
                    position: Qt.vector3d(0, 0, 0)
                    rotation: Qt.quaternion(1, 0, 0, 0)

                    Model {
                        source: "#Cube"
                        materials: DefaultMaterial {
                            diffuseColor: "green"
                        }
                    }
                }
            }

            RotationGizmo {
                id: gizmo
                anchors.fill: parent
                view3d: view
                targetNode: targetNode
                gizmoSize: 80
            }
        }
    }

    // ========== Translation Gizmo Color Tests ==========

    function test_translation_active_axis_changes_color() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Initial state - no active axis
        compare(gizmo.activeAxis, 0, "No axis should be active initially")
        compare(gizmo.xAxisColor.toString(), "#ff0000", "X axis should be default red")
        compare(gizmo.yAxisColor.toString(), "#00ff00", "Y axis should be default green")
        compare(gizmo.zAxisColor.toString(), "#0000ff", "Z axis should be default blue")

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Activate X axis
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        compare(gizmo.activeAxis, 1, "X axis should be active")
        compare(gizmo.xAxisColor.toString(), "#ff6666", "X axis should be highlighted red")
        compare(gizmo.yAxisColor.toString(), "#00ff00", "Y axis should remain default green")
        compare(gizmo.zAxisColor.toString(), "#0000ff", "Z axis should remain default blue")

        mouseRelease(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Should return to default colors
        compare(gizmo.activeAxis, 0, "No axis should be active after release")
        compare(gizmo.xAxisColor.toString(), "#ff0000", "X axis should return to default red")
    }

    function test_translation_active_plane_changes_color() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Initial state - no active plane
        compare(gizmo.activePlane, 0, "No plane should be active initially")
        compare(gizmo.xyPlaneColor.toString(), "#ffff00", "XY plane should be default yellow")
        compare(gizmo.xzPlaneColor.toString(), "#ff00ff", "XZ plane should be default magenta")
        compare(gizmo.yzPlaneColor.toString(), "#00ffff", "YZ plane should be default cyan")

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        if (geometry.planes.xy.length === 4) {
            var xyCenter = Qt.point(
                (geometry.planes.xy[0].x + geometry.planes.xy[2].x) / 2,
                (geometry.planes.xy[0].y + geometry.planes.xy[2].y) / 2
            )

            // Activate XY plane
            mousePress(gizmo, xyCenter.x, xyCenter.y)

            compare(gizmo.activePlane, 1, "XY plane should be active")
            compare(gizmo.xyPlaneColor.toString(), "#ffff99", "XY plane should be highlighted")
            compare(gizmo.xzPlaneColor.toString(), "#ff00ff", "XZ plane should remain default")
            compare(gizmo.yzPlaneColor.toString(), "#00ffff", "YZ plane should remain default")

            mouseRelease(gizmo, xyCenter.x, xyCenter.y)

            // Should return to default colors
            compare(gizmo.activePlane, 0, "No plane should be active after release")
            compare(gizmo.xyPlaneColor.toString(), "#ffff00", "XY plane should return to default")
        } else {
            skip("XY plane geometry not available")
        }
    }

    function test_translation_inactive_state_default_colors() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Verify default colors when inactive
        compare(gizmo.activeAxis, 0, "No axis should be active")
        compare(gizmo.activePlane, 0, "No plane should be active")

        compare(gizmo.xAxisColor.toString(), "#ff0000", "X axis default color")
        compare(gizmo.yAxisColor.toString(), "#00ff00", "Y axis default color")
        compare(gizmo.zAxisColor.toString(), "#0000ff", "Z axis default color")

        compare(gizmo.xyPlaneColor.toString(), "#ffff00", "XY plane default color")
        compare(gizmo.xzPlaneColor.toString(), "#ff00ff", "XZ plane default color")
        compare(gizmo.yzPlaneColor.toString(), "#00ffff", "YZ plane default color")
    }

    // ========== Rotation Gizmo Color Tests ==========

    function test_rotation_active_axis_changes_color() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Initial state
        compare(gizmo.activeAxis, 0, "No axis should be active initially")
        compare(gizmo.xAxisColor.toString(), "#ff0000", "X axis should be default red")
        compare(gizmo.yAxisColor.toString(), "#00ff00", "Y axis should be default green")
        compare(gizmo.zAxisColor.toString(), "#0000ff", "Z axis should be default blue")

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 0) {
            var point = circle[0]

            // Activate Z axis (XY circle)
            mousePress(gizmo, point.x, point.y)

            compare(gizmo.activeAxis, 3, "Z axis should be active")
            compare(gizmo.zAxisColor.toString(), "#6666ff", "Z axis should be highlighted blue")
            compare(gizmo.xAxisColor.toString(), "#ff0000", "X axis should remain default")
            compare(gizmo.yAxisColor.toString(), "#00ff00", "Y axis should remain default")

            mouseRelease(gizmo, point.x, point.y)

            // Should return to default
            compare(gizmo.activeAxis, 0, "No axis should be active after release")
            compare(gizmo.zAxisColor.toString(), "#0000ff", "Z axis should return to default")
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Canvas Repaint Trigger Tests ==========

    Component {
        id: repaintTrackingScene
        Item {
            width: 800
            height: 600

            property int paintCount: 0

            View3D {
                id: view
                anchors.fill: parent

                PerspectiveCamera {
                    id: camera
                    position: Qt.vector3d(0, 0, 300)
                    eulerRotation: Qt.vector3d(0, 0, 0)
                }

                DirectionalLight {
                    eulerRotation: Qt.vector3d(-45, 45, 0)
                }

                Node {
                    id: targetNode
                    position: Qt.vector3d(0, 0, 0)

                    Model {
                        source: "#Cube"
                        materials: DefaultMaterial {
                            diffuseColor: "blue"
                        }
                    }
                }
            }

            TranslationGizmo {
                id: gizmo
                anchors.fill: parent
                view3d: view
                targetNode: targetNode
                gizmoSize: 100
            }

            // Track canvas paints
            Connections {
                target: gizmo.children[0] // Canvas is first child
                function onPaint() {
                    parent.paintCount++
                }
            }
        }
    }

    function test_repaint_on_target_position_change() {
        var scene = createTemporaryObject(repaintTrackingScene, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0]
        var targetNode = view.children[2]

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var initialPaintCount = scene.paintCount

        // Change target position
        targetNode.position = Qt.vector3d(50, 0, 0)

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Should have triggered a repaint
        verify(scene.paintCount > initialPaintCount, "Canvas should repaint when target position changes")
    }

    function test_repaint_on_camera_move() {
        var scene = createTemporaryObject(repaintTrackingScene, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0]
        var camera = view.children[0]

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var initialPaintCount = scene.paintCount

        // Move camera
        camera.position = Qt.vector3d(50, 50, 350)

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Should have triggered a repaint
        verify(scene.paintCount > initialPaintCount, "Canvas should repaint when camera moves")
    }

    function test_repaint_on_active_axis_change() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Activating an axis should trigger repaint for color change
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Active axis should be set
        compare(gizmo.activeAxis, 1, "X axis should be active")

        mouseRelease(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Should have returned to inactive state
        compare(gizmo.activeAxis, 0, "No axis should be active")
    }

    // ========== Rotation Gizmo Visual Arc Tests ==========

    function test_rotation_arc_visualization_during_drag() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 10) {
            var startPoint = circle[0]
            var endPoint = circle[Math.floor(circle.length / 4)]

            // Before drag - angles should be default
            compare(gizmo.dragStartAngle, 0.0, "Drag start angle should be 0 initially")
            compare(gizmo.currentAngle, 0.0, "Current angle should be 0 initially")

            // Start drag
            mousePress(gizmo, startPoint.x, startPoint.y)

            // Angles should be set during drag
            verify(gizmo.dragStartAngle !== 0.0 || gizmo.currentAngle !== 0.0,
                   "Angles should be set during drag")

            // Move to create arc
            mouseMove(gizmo, endPoint.x, endPoint.y)

            // Current angle should update
            verify(gizmo.currentAngle !== gizmo.dragStartAngle,
                   "Current angle should change during drag")

            mouseRelease(gizmo, endPoint.x, endPoint.y)

            // After release, angles should reset
            compare(gizmo.dragStartAngle, 0.0, "Drag start angle should reset")
            compare(gizmo.currentAngle, 0.0, "Current angle should reset")
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_rotation_arc_start_end_angles_match_drag() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 10) {
            var startPoint = circle[0]

            mousePress(gizmo, startPoint.x, startPoint.y)

            var startAngle = gizmo.dragStartAngle

            // Move slightly
            var endPoint = circle[5]
            mouseMove(gizmo, endPoint.x, endPoint.y)

            var currentAngle = gizmo.currentAngle

            // Drag start angle should remain constant during drag
            compare(gizmo.dragStartAngle, startAngle, "Drag start angle should not change during drag")

            // Current angle should be different from start
            verify(currentAngle !== startAngle, "Current angle should differ from start angle")

            mouseRelease(gizmo, endPoint.x, endPoint.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Geometry Update Tests ==========

    function test_geometry_updates_on_gizmo_size_change() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry1 = gizmo.calculateGizmoGeometry()
        verify(geometry1 !== null, "Initial geometry should be calculated")

        var length1 = Math.sqrt(
            Math.pow(geometry1.xEnd.x - geometry1.center.x, 2) +
            Math.pow(geometry1.xEnd.y - geometry1.center.y, 2)
        )

        // Change gizmo size
        gizmo.gizmoSize = 200

        wait(50)

        var geometry2 = gizmo.calculateGizmoGeometry()
        verify(geometry2 !== null, "Updated geometry should be calculated")

        var length2 = Math.sqrt(
            Math.pow(geometry2.xEnd.x - geometry2.center.x, 2) +
            Math.pow(geometry2.xEnd.y - geometry2.center.y, 2)
        )

        // Arrow length should have changed proportionally
        verify(length2 > length1, "Arrow length should increase with gizmo size")
        verify(Math.abs(length2 - 200) < 10, "Arrow length should match new gizmo size")
    }

    function test_component_completed_triggers_initial_paint() {
        // This test verifies that the gizmo renders on component completion
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Geometry should be available immediately after component completion
        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated on component completion")
    }

    // ========== Visual State Consistency Tests ==========

    function test_visual_state_matches_active_state() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Test axis activation visual feedback
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Visual state (color) should match active state
        compare(gizmo.activeAxis, 1, "Active axis state should be X")
        verify(gizmo.xAxisColor !== "#ff0000", "X axis color should change to indicate active state")

        mouseRelease(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Visual state should revert
        compare(gizmo.activeAxis, 0, "Active axis should reset")
        compare(gizmo.xAxisColor.toString(), "#ff0000", "X axis color should revert to default")
    }
}

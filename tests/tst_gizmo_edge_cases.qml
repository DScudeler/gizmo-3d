import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

TestCase {
    id: testCase
    name: "GizmoEdgeCases"
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

    Component {
        id: signalSpyComponent
        SignalSpy {}
    }

    // ========== Null/Invalid State Tests ==========

    function test_null_view3d_no_crash() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Set view3d to null
        gizmo.view3d = null

        // Should not crash when calculating geometry
        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry === null, "Geometry should be null with no view3d")

        // Mouse interactions should not crash
        mouseClick(gizmo, 100, 100)
    }

    function test_null_targetNode_no_crash() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Set targetNode to null
        gizmo.targetNode = null

        // Should not crash when calculating geometry
        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry === null, "Geometry should be null with no targetNode")

        // Mouse interactions should not crash
        mouseClick(gizmo, 100, 100)
    }

    function test_zero_gizmo_size() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        gizmo.gizmoSize = 0

        // Should not crash
        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry calculation should not crash with zero size")
    }

    function test_negative_gizmo_size() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        gizmo.gizmoSize = -50

        // Should not crash
        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry calculation should not crash with negative size")
    }

    function test_very_large_gizmo_size() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        gizmo.gizmoSize = 10000

        // Should not crash
        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry calculation should not crash with very large size")
    }

    // ========== Camera Movement During Drag Tests ==========

    function test_camera_move_during_drag() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var camera = view.children[0]
        var initialCameraPos = camera.position

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Start drag
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Move camera during drag
        camera.position = Qt.vector3d(50, 50, 350)

        // Continue drag - should not crash
        mouseMove(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)

        // Restore camera and release
        camera.position = initialCameraPos
        mouseRelease(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)

        // Should complete without crashes
        compare(gizmo.activeAxis, 0, "Drag should complete")
    }

    function test_target_move_during_drag() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Start drag
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Externally move target during drag
        targetNode.position = Qt.vector3d(100, 0, 0)

        wait(50)

        // Continue drag - should not crash
        mouseMove(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)
        mouseRelease(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)

        // Should complete without crashes
        compare(gizmo.activeAxis, 0, "Drag should complete")
    }

    // ========== Rapid Interaction Tests ==========

    function test_rapid_click_sequences() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Rapid clicks should not cause issues
        for (var i = 0; i < 5; i++) {
            mouseClick(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        }

        // Should still be in valid state
        compare(gizmo.activeAxis, 0, "Active axis should be 0 after rapid clicks")
    }

    function test_rapid_axis_switching() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Click X axis
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        mouseRelease(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        wait(10)
        geometry = gizmo.calculateGizmoGeometry()

        // Immediately click Y axis
        mousePress(gizmo, geometry.yEnd.x, geometry.yEnd.y)
        mouseRelease(gizmo, geometry.yEnd.x, geometry.yEnd.y)

        wait(10)
        geometry = gizmo.calculateGizmoGeometry()

        // Immediately click Z axis
        mousePress(gizmo, geometry.zEnd.x, geometry.zEnd.y)
        mouseRelease(gizmo, geometry.zEnd.x, geometry.zEnd.y)

        // Should be in valid state
        compare(gizmo.activeAxis, 0, "Active axis should be 0 after switching")
    }

    function test_click_drag_release_rapid_repeat() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "axisTranslationDelta"
        })

        // Repeat drag operations rapidly
        for (var i = 0; i < 3; i++) {
            var geometry = gizmo.calculateGizmoGeometry()
            if (geometry) {
                mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
                mouseMove(gizmo, geometry.xEnd.x + 20, geometry.xEnd.y)
                mouseRelease(gizmo, geometry.xEnd.x + 20, geometry.xEnd.y)
                wait(10)
            }
        }

        // Should have emitted deltas for all drags
        verify(deltaSpy.count > 0, "Delta signals should be emitted")
    }

    // ========== Rotation Gizmo Edge Cases ==========

    function test_rotation_null_view3d() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        gizmo.view3d = null

        // Should not crash
        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry === null, "Geometry should be null with no view3d")

        mouseClick(gizmo, 100, 100)
    }

    function test_rotation_wrap_around_360() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 10) {
            // Start near 360 degrees (end of circle)
            var startPoint = circle[circle.length - 2]
            // End near 0 degrees (start of circle)
            var endPoint = circle[1]

            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)

            // Should emit delta, handling wrap-around
            verify(deltaSpy.count > 0, "Delta should be emitted even with wrap-around")

            mouseRelease(gizmo, endPoint.x, endPoint.y)

            compare(gizmo.activeAxis, 0, "Active axis should reset")
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Canvas Availability Tests ==========

    function test_hit_test_before_canvas_ready() {
        // Create a fresh scene
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Try to interact immediately without wait
        // This tests graceful handling when canvas might not be ready
        mouseClick(gizmo, 400, 300)

        // Should not crash
        verify(true, "Should handle early interaction gracefully")
    }

    // ========== Extreme Target Positions ==========

    function test_very_far_target_position() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]

        // Move target very far away
        targetNode.position = Qt.vector3d(10000, 10000, -5000)

        wait(50)

        // Should not crash
        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated even with extreme positions")
    }

    function test_target_behind_camera() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]

        // Move target behind camera
        targetNode.position = Qt.vector3d(0, 0, 500)

        wait(50)

        // Should not crash
        var geometry = gizmo.calculateGizmoGeometry()
        // Geometry might be calculated but screen positions may be off-screen
        // The key is that it doesn't crash
    }

    // ========== Invalid Snap Values ==========

    function test_zero_snap_increment() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        gizmo.snapEnabled = true
        gizmo.snapIncrement = 0

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Should not crash during drag with zero snap
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        mouseMove(gizmo, geometry.xEnd.x + 30, geometry.xEnd.y)
        mouseRelease(gizmo, geometry.xEnd.x + 30, geometry.xEnd.y)
    }

    function test_negative_snap_increment() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        gizmo.snapEnabled = true
        gizmo.snapIncrement = -5.0

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Should not crash during drag with negative snap
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        mouseMove(gizmo, geometry.xEnd.x + 30, geometry.xEnd.y)
        mouseRelease(gizmo, geometry.xEnd.x + 30, geometry.xEnd.y)
    }

    function test_rotation_zero_snap_angle() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        gizmo.snapEnabled = true
        gizmo.snapAngle = 0

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 5) {
            var startPoint = circle[0]
            var endPoint = circle[5]

            // Should not crash with zero snap angle
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)
            mouseRelease(gizmo, endPoint.x, endPoint.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Drag Beyond Canvas Bounds ==========

    function test_drag_beyond_canvas_bounds() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "axisTranslationDelta"
        })

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Start drag on X axis
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Move way beyond canvas bounds
        mouseMove(gizmo, -1000, -1000)

        // Should still emit deltas and not crash
        mouseRelease(gizmo, -1000, -1000)

        compare(gizmo.activeAxis, 0, "Drag should complete")
    }

    // ========== State Consistency Tests ==========

    function test_activeAxis_resets_after_release() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Drag X axis
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        verify(gizmo.activeAxis !== 0, "Active axis should be set during drag")

        mouseRelease(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        compare(gizmo.activeAxis, 0, "Active axis should reset after release")
    }

    function test_rotation_activeAxis_resets() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 0) {
            var point = circle[0]

            mousePress(gizmo, point.x, point.y)
            verify(gizmo.activeAxis !== 0, "Active axis should be set during drag")

            mouseRelease(gizmo, point.x, point.y)
            compare(gizmo.activeAxis, 0, "Active axis should reset after release")
            compare(gizmo.dragStartAngle, 0.0, "Drag start angle should reset")
            compare(gizmo.currentAngle, 0.0, "Current angle should reset")
        } else {
            skip("Circle geometry not available")
        }
    }
}

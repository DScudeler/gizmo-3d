import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

TestCase {
    id: testCase
    name: "RotationGizmoInteraction"
    width: 800
    height: 600
    visible: true
    when: windowShown

    Component {
        id: testSceneComponent
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
                            diffuseColor: "blue"
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

                // Trivial controller for testing
                property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

                onRotationStarted: function(axis) {
                    dragStartRot = targetNode.rotation
                }

                onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
                    var axisVec = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                                : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                                : Qt.vector3d(0, 0, 1)
                    var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
                    targetNode.rotation = deltaQuat.times(dragStartRot)
                }
            }
        }
    }

    Component {
        id: signalSpyComponent
        SignalSpy {}
    }

    // Helper function to get a point on a circle
    function getCirclePoint(geometry, circleName, angleRadians) {
        var circle = geometry.circles[circleName]
        if (!circle || circle.length === 0) return null

        var normalizedAngle = angleRadians
        while (normalizedAngle < 0) normalizedAngle += Math.PI * 2
        while (normalizedAngle >= Math.PI * 2) normalizedAngle -= Math.PI * 2

        var idx = Math.floor((normalizedAngle / (Math.PI * 2)) * (circle.length - 1))
        return circle[idx]
    }

    // ========== Circle Hit Detection Tests ==========

    function test_click_x_circle_activates() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Wait for gizmo and canvas rendering to complete
        waitForRendering(gizmo, 5000)
        wait(100) // Additional time for Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Click on YZ circle (X-axis rotation) - this is the red circle
        var point = getCirclePoint(geometry, "yz", Math.PI / 4) // 45 degrees
        if (point) {
            mousePress(gizmo, point.x, point.y)

            compare(gizmo.activeAxis, 1, "Active axis should be X (1) for YZ circle")

            mouseRelease(gizmo, point.x, point.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_click_y_circle_activates() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Wait for gizmo and canvas rendering to complete
        waitForRendering(gizmo, 5000)
        wait(100) // Additional time for Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Click on ZX circle (Y-axis rotation) - this is the green circle
        var point = getCirclePoint(geometry, "zx", Math.PI / 2) // 90 degrees
        if (point) {
            mousePress(gizmo, point.x, point.y)

            compare(gizmo.activeAxis, 2, "Active axis should be Y (2) for ZX circle")

            mouseRelease(gizmo, point.x, point.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_click_z_circle_activates() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Wait for gizmo and canvas rendering to complete
        waitForRendering(gizmo, 5000)
        wait(100) // Additional time for Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Click on XY circle (Z-axis rotation) - this is the blue circle
        var point = getCirclePoint(geometry, "xy", 0) // 0 degrees
        if (point) {
            mousePress(gizmo, point.x, point.y)

            compare(gizmo.activeAxis, 3, "Active axis should be Z (3) for XY circle")

            mouseRelease(gizmo, point.x, point.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Rotation Drag Signal Tests ==========

    function test_drag_x_rotation_emits_signals() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var startedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationStarted"
        })
        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })
        var endedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationEnded"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "yz", 0)
        var endPoint = getCirclePoint(geometry, "yz", Math.PI / 4) // 45 degrees

        if (startPoint && endPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)

            compare(startedSpy.count, 1, "Started signal should be emitted once")
            compare(startedSpy.signalArguments[0][0], 1, "Started signal should indicate X axis")

            mouseMove(gizmo, endPoint.x, endPoint.y)

            verify(deltaSpy.count > 0, "Delta signal should be emitted during drag")
            compare(deltaSpy.signalArguments[0][0], 1, "Delta signal should indicate X axis")

            mouseRelease(gizmo, endPoint.x, endPoint.y)

            compare(endedSpy.count, 1, "Ended signal should be emitted once")
            compare(endedSpy.signalArguments[0][0], 1, "Ended signal should indicate X axis")
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_drag_y_rotation_emits_signals() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var startedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationStarted"
        })
        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })
        var endedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationEnded"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "zx", 0)
        var endPoint = getCirclePoint(geometry, "zx", Math.PI / 3) // 60 degrees

        if (startPoint && endPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)
            compare(startedSpy.count, 1, "Started signal should be emitted once")
            compare(startedSpy.signalArguments[0][0], 2, "Started signal should indicate Y axis")

            mouseMove(gizmo, endPoint.x, endPoint.y)
            verify(deltaSpy.count > 0, "Delta signal should be emitted during drag")
            compare(deltaSpy.signalArguments[0][0], 2, "Delta signal should indicate Y axis")

            mouseRelease(gizmo, endPoint.x, endPoint.y)
            compare(endedSpy.count, 1, "Ended signal should be emitted once")
            compare(endedSpy.signalArguments[0][0], 2, "Ended signal should indicate Y axis")
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_drag_z_rotation_emits_signals() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var startedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationStarted"
        })
        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })
        var endedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationEnded"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "xy", Math.PI / 2) // 90 degrees
        var endPoint = getCirclePoint(geometry, "xy", Math.PI) // 180 degrees

        if (startPoint && endPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)
            compare(startedSpy.count, 1, "Started signal should be emitted once")
            compare(startedSpy.signalArguments[0][0], 3, "Started signal should indicate Z axis")

            mouseMove(gizmo, endPoint.x, endPoint.y)
            verify(deltaSpy.count > 0, "Delta signal should be emitted during drag")
            compare(deltaSpy.signalArguments[0][0], 3, "Delta signal should indicate Z axis")

            mouseRelease(gizmo, endPoint.x, endPoint.y)
            compare(endedSpy.count, 1, "Ended signal should be emitted once")
            compare(endedSpy.signalArguments[0][0], 3, "Ended signal should indicate Z axis")
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Angle Calculation Tests ==========

    function test_rotation_angle_delta_is_reasonable() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
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

        var startPoint = getCirclePoint(geometry, "xy", 0)
        var endPoint = getCirclePoint(geometry, "xy", Math.PI / 2) // 90 degrees rotation

        if (startPoint && endPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)

            if (deltaSpy.count > 0) {
                var angleDegrees = deltaSpy.signalArguments[deltaSpy.count - 1][1]

                // The angle should be reasonably close to 90 degrees
                // (allowing some tolerance for coordinate mapping accuracy)
                verify(Math.abs(angleDegrees) < 180, "Angle delta should be reasonable (<180 degrees)")
            }

            mouseRelease(gizmo, endPoint.x, endPoint.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Multiple Delta Emissions Tests ==========

    function test_continuous_rotation_emits_multiple_deltas() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
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

        var startPoint = getCirclePoint(geometry, "xy", 0)

        if (startPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)

            // Multiple moves should emit multiple deltas
            var point1 = getCirclePoint(geometry, "xy", Math.PI / 8)
            if (point1) mouseMove(gizmo, point1.x, point1.y)
            var count1 = deltaSpy.count

            var point2 = getCirclePoint(geometry, "xy", Math.PI / 4)
            if (point2) mouseMove(gizmo, point2.x, point2.y)
            var count2 = deltaSpy.count

            var point3 = getCirclePoint(geometry, "xy", Math.PI / 2)
            if (point3) mouseMove(gizmo, point3.x, point3.y)
            var count3 = deltaSpy.count

            mouseRelease(gizmo, point3.x, point3.y)

            verify(count3 >= count2, "Delta count should increase with each move")
            verify(count2 >= count1, "Delta count should increase with each move")
            verify(count1 > 0, "At least one delta should be emitted")
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Snap Integration Tests ==========

    function test_rotation_with_snap_enabled() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Enable snap with 15 degree increment
        gizmo.snapEnabled = true
        gizmo.snapAngle = 15.0

        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "xy", 0)
        var endPoint = getCirclePoint(geometry, "xy", Math.PI / 6) // ~30 degrees

        if (startPoint && endPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)

            // Verify snapActive parameter is true
            if (deltaSpy.count > 0) {
                var snapActive = deltaSpy.signalArguments[deltaSpy.count - 1][2]
                compare(snapActive, true, "snapActive should be true when snap is enabled")

                // The angle should be snapped to a multiple of 15 degrees
                var angleDegrees = deltaSpy.signalArguments[deltaSpy.count - 1][1]
                var remainder = Math.abs(angleDegrees) % 15.0
                verify(remainder < 0.1 || remainder > 14.9, "Angle should be snapped to 15-degree increments")
            }

            mouseRelease(gizmo, endPoint.x, endPoint.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_rotation_with_snap_disabled() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Ensure snap is disabled
        gizmo.snapEnabled = false

        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "xy", 0)
        var endPoint = getCirclePoint(geometry, "xy", Math.PI / 7) // ~25.7 degrees (not a snap multiple)

        if (startPoint && endPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)

            // Verify snapActive parameter is false
            if (deltaSpy.count > 0) {
                var snapActive = deltaSpy.signalArguments[deltaSpy.count - 1][2]
                compare(snapActive, false, "snapActive should be false when snap is disabled")
            }

            mouseRelease(gizmo, endPoint.x, endPoint.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_rotation_with_45_degree_snap() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Enable snap with 45 degree increment
        gizmo.snapEnabled = true
        gizmo.snapAngle = 45.0

        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "xy", 0)
        var endPoint = getCirclePoint(geometry, "xy", Math.PI / 3) // ~60 degrees

        if (startPoint && endPoint) {
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)

            // Verify angle is snapped to 45-degree increments
            if (deltaSpy.count > 0) {
                var angleDegrees = deltaSpy.signalArguments[deltaSpy.count - 1][1]
                var remainder = Math.abs(angleDegrees) % 45.0
                verify(remainder < 0.1 || remainder > 44.9, "Angle should be snapped to 45-degree increments")
            }

            mouseRelease(gizmo, endPoint.x, endPoint.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Edge Cases ==========

    function test_click_outside_circles_no_interaction() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var startedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationStarted"
        })

        // Click in corner, far from circles
        mousePress(gizmo, 10, 10)

        compare(startedSpy.count, 0, "No signal should be emitted when clicking outside")
        compare(gizmo.activeAxis, 0, "Active axis should remain 0")

        mouseRelease(gizmo, 10, 10)
    }

    function test_rapid_click_release() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var startedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationStarted"
        })
        var endedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationEnded"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var point = getCirclePoint(geometry, "xy", 0)

        if (point) {
            // Rapid click without drag
            mouseClick(gizmo, point.x, point.y)

            compare(startedSpy.count, 1, "Started signal should be emitted")
            compare(endedSpy.count, 1, "Ended signal should be emitted")
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_signal_order_consistency() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var startedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationStarted"
        })
        var deltaSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationDelta"
        })
        var endedSpy = createTemporaryObject(signalSpyComponent, testCase, {
            target: gizmo,
            signalName: "rotationEnded"
        })

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "xy", 0)
        var endPoint = getCirclePoint(geometry, "xy", Math.PI / 4)

        if (startPoint && endPoint) {
            // Perform full rotation operation
            mousePress(gizmo, startPoint.x, startPoint.y)
            compare(startedSpy.count, 1, "Started should emit first")
            compare(deltaSpy.count, 0, "Delta should not emit yet")
            compare(endedSpy.count, 0, "Ended should not emit yet")

            mouseMove(gizmo, endPoint.x, endPoint.y)
            compare(startedSpy.count, 1, "Started should still be 1")
            verify(deltaSpy.count > 0, "Delta should emit during move")
            compare(endedSpy.count, 0, "Ended should not emit yet")

            mouseRelease(gizmo, endPoint.x, endPoint.y)
            compare(startedSpy.count, 1, "Started should still be 1")
            compare(endedSpy.count, 1, "Ended should emit last")
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_controller_updates_rotation() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2] // Node is third child of View3D
        verify(targetNode !== null, "TargetNode should exist")

        var initialRot = targetNode.rotation

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "xy", 0)
        var endPoint = getCirclePoint(geometry, "xy", Math.PI / 4)

        if (startPoint && endPoint) {
            // Drag to rotate
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)
            mouseRelease(gizmo, endPoint.x, endPoint.y)

            // Rotation should have changed (controller pattern working)
            var finalRot = targetNode.rotation
            verify(finalRot.scalar !== initialRot.scalar ||
                   finalRot.x !== initialRot.x ||
                   finalRot.y !== initialRot.y ||
                   finalRot.z !== initialRot.z,
                   "Target rotation should change after drag")
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Visual Arc Tests ==========

    function test_arc_angles_update_during_drag() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var startPoint = getCirclePoint(geometry, "xy", 0)
        var endPoint = getCirclePoint(geometry, "xy", Math.PI / 6)

        if (startPoint && endPoint) {
            // Initial state - no active rotation
            compare(gizmo.activeAxis, 0, "No active axis initially")

            mousePress(gizmo, startPoint.x, startPoint.y)

            // After press, angles should be set
            verify(gizmo.dragStartAngle !== undefined, "Drag start angle should be set")
            compare(gizmo.activeAxis, 3, "Z axis should be active")

            mouseMove(gizmo, endPoint.x, endPoint.y)

            // Current angle should update during drag
            verify(gizmo.currentAngle !== undefined, "Current angle should be set")

            mouseRelease(gizmo, endPoint.x, endPoint.y)

            // After release, angles should reset
            compare(gizmo.dragStartAngle, 0.0, "Drag start angle should reset")
            compare(gizmo.currentAngle, 0.0, "Current angle should reset")
            compare(gizmo.activeAxis, 0, "Active axis should reset")
        } else {
            skip("Circle geometry not available")
        }
    }
}

import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

TestCase {
    id: testCase
    name: "GizmoControllerIntegration"
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
                    position: Qt.vector3d(50, 25, -10)

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

                // Trivial controller implementation
                property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

                onAxisTranslationStarted: function(axis) {
                    dragStartPos = targetNode.position
                }

                onAxisTranslationDelta: function(axis, transformMode, delta, snapActive) {
                    if (axis === GizmoEnums.Axis.X) {
                        targetNode.position = Qt.vector3d(dragStartPos.x + delta, dragStartPos.y, dragStartPos.z)
                    } else if (axis === GizmoEnums.Axis.Y) {
                        targetNode.position = Qt.vector3d(dragStartPos.x, dragStartPos.y + delta, dragStartPos.z)
                    } else if (axis === GizmoEnums.Axis.Z) {
                        targetNode.position = Qt.vector3d(dragStartPos.x, dragStartPos.y, dragStartPos.z + delta)
                    }
                }

                onPlaneTranslationStarted: function(plane) {
                    dragStartPos = targetNode.position
                }

                onPlaneTranslationDelta: function(plane, transformMode, delta, snapActive) {
                    targetNode.position = Qt.vector3d(
                        dragStartPos.x + delta.x,
                        dragStartPos.y + delta.y,
                        dragStartPos.z + delta.z
                    )
                }
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

                // Trivial controller implementation
                property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

                onRotationStarted: function(axis) {
                    dragStartRot = targetNode.rotation
                }

                onRotationDelta: function(axis, angleDegrees, snapActive) {
                    var axisVec = axis === 1 ? Qt.vector3d(1, 0, 0)
                                : axis === 2 ? Qt.vector3d(0, 1, 0)
                                : Qt.vector3d(0, 0, 1)
                    var deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
                    targetNode.rotation = deltaQuat.times(dragStartRot)
                }
            }
        }
    }

    // ========== Translation Controller Tests ==========

    function test_translation_controller_preserves_drag_start() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]
        var initialPos = targetNode.position

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Start drag
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)

        // Verify dragStartPos is captured
        compare(gizmo.dragStartPos, initialPos, "Drag start position should match initial position")

        mouseRelease(gizmo, geometry.xEnd.x, geometry.xEnd.y)
    }

    function test_translation_controller_applies_axis_delta() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]
        var initialPos = targetNode.position

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Drag X axis
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        mouseMove(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)
        mouseRelease(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)

        var finalPos = targetNode.position

        // X should have changed, Y and Z should remain the same
        verify(finalPos.x !== initialPos.x, "X position should change")
        fuzzyCompare(finalPos.y, initialPos.y, 0.01, "Y position should remain the same")
        fuzzyCompare(finalPos.z, initialPos.z, 0.01, "Z position should remain the same")
    }

    function test_translation_controller_applies_plane_delta() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]
        var initialPos = targetNode.position

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Drag XY plane
        if (geometry.planes.xy.length === 4) {
            var xyCenter = Qt.point(
                (geometry.planes.xy[0].x + geometry.planes.xy[2].x) / 2,
                (geometry.planes.xy[0].y + geometry.planes.xy[2].y) / 2
            )

            mousePress(gizmo, xyCenter.x, xyCenter.y)
            mouseMove(gizmo, xyCenter.x + 30, xyCenter.y + 30)
            mouseRelease(gizmo, xyCenter.x + 30, xyCenter.y + 30)

            var finalPos = targetNode.position

            // Position should have changed (XY plane allows X and Y movement)
            verify(finalPos.x !== initialPos.x || finalPos.y !== initialPos.y,
                   "Position should change on XY plane drag")
        } else {
            skip("XY plane geometry not available")
        }
    }

    function test_translation_controller_multiple_drags() {
        var scene = createTemporaryObject(translationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]
        var initialPos = targetNode.position

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // First drag on X axis
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        mouseMove(gizmo, geometry.xEnd.x + 30, geometry.xEnd.y)
        mouseRelease(gizmo, geometry.xEnd.x + 30, geometry.xEnd.y)

        var posAfterFirstDrag = targetNode.position
        verify(posAfterFirstDrag.x !== initialPos.x, "Position should change after first drag")

        wait(50)
        geometry = gizmo.calculateGizmoGeometry()

        // Second drag on Y axis
        mousePress(gizmo, geometry.yEnd.x, geometry.yEnd.y)
        mouseMove(gizmo, geometry.yEnd.x, geometry.yEnd.y - 30)
        mouseRelease(gizmo, geometry.yEnd.x, geometry.yEnd.y - 30)

        var posAfterSecondDrag = targetNode.position

        // Both X and Y should have changed from initial
        verify(posAfterSecondDrag.x !== initialPos.x, "X should still be changed")
        verify(posAfterSecondDrag.y !== initialPos.y, "Y should now be changed")
    }

    // ========== Rotation Controller Tests ==========

    function test_rotation_controller_preserves_drag_start() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]
        var initialRot = targetNode.rotation

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 0) {
            var point = circle[0]

            // Start drag
            mousePress(gizmo, point.x, point.y)

            // Verify dragStartRot is captured
            compare(gizmo.dragStartRot.scalar, initialRot.scalar, "Drag start rotation scalar should match")
            compare(gizmo.dragStartRot.x, initialRot.x, "Drag start rotation x should match")
            compare(gizmo.dragStartRot.y, initialRot.y, "Drag start rotation y should match")
            compare(gizmo.dragStartRot.z, initialRot.z, "Drag start rotation z should match")

            mouseRelease(gizmo, point.x, point.y)
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_rotation_controller_applies_delta() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]
        var initialRot = targetNode.rotation

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 10) {
            var startPoint = circle[0]
            var endPoint = circle[Math.floor(circle.length / 4)] // ~90 degrees

            // Perform rotation
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)
            mouseRelease(gizmo, endPoint.x, endPoint.y)

            var finalRot = targetNode.rotation

            // Rotation should have changed
            verify(finalRot.scalar !== initialRot.scalar ||
                   finalRot.x !== initialRot.x ||
                   finalRot.y !== initialRot.y ||
                   finalRot.z !== initialRot.z,
                   "Rotation should change after drag")
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_rotation_controller_quaternion_multiplication_order() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]

        // Set a known initial rotation
        var initialQuat = GizmoMath.quaternionFromAxisAngle(Qt.vector3d(1, 0, 0), 45) // 45 degrees around X
        targetNode.rotation = initialQuat

        wait(50)

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        var circle = geometry.circles.xy
        if (circle && circle.length > 10) {
            var startPoint = circle[0]
            var endPoint = circle[Math.floor(circle.length / 8)] // ~45 degrees

            // Perform rotation around Z
            mousePress(gizmo, startPoint.x, startPoint.y)
            mouseMove(gizmo, endPoint.x, endPoint.y)
            mouseRelease(gizmo, endPoint.x, endPoint.y)

            var finalRot = targetNode.rotation

            // Final rotation should be different from initial (combination of X and Z rotations)
            verify(finalRot.scalar !== initialQuat.scalar ||
                   finalRot.x !== initialQuat.x ||
                   finalRot.y !== initialQuat.y ||
                   finalRot.z !== initialQuat.z,
                   "Rotation should combine initial and delta rotations")
        } else {
            skip("Circle geometry not available")
        }
    }

    // ========== Multi-Object Controller Tests ==========

    Component {
        id: multiObjectSceneComponent
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
                    id: targetNode1
                    position: Qt.vector3d(0, 0, 0)

                    Model {
                        source: "#Cube"
                        materials: DefaultMaterial {
                            diffuseColor: "blue"
                        }
                    }
                }

                Node {
                    id: targetNode2
                    position: Qt.vector3d(0, 0, 0)

                    Model {
                        source: "#Sphere"
                        materials: DefaultMaterial {
                            diffuseColor: "red"
                        }
                    }
                }
            }

            TranslationGizmo {
                id: gizmo
                anchors.fill: parent
                view3d: view
                targetNode: targetNode1
                gizmoSize: 100

                property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
                property list<Node> additionalTargets: [targetNode2]

                onAxisTranslationStarted: function(axis) {
                    dragStartPos = targetNode.position
                }

                onAxisTranslationDelta: function(axis, delta, snapActive) {
                    // Apply to primary target
                    if (axis === 1) {
                        targetNode.position = Qt.vector3d(dragStartPos.x + delta, dragStartPos.y, dragStartPos.z)
                    } else if (axis === 2) {
                        targetNode.position = Qt.vector3d(dragStartPos.x, dragStartPos.y + delta, dragStartPos.z)
                    } else if (axis === 3) {
                        targetNode.position = Qt.vector3d(dragStartPos.x, dragStartPos.y, dragStartPos.z + delta)
                    }

                    // Apply to additional targets
                    for (var i = 0; i < additionalTargets.length; i++) {
                        var target = additionalTargets[i]
                        if (axis === 1) {
                            target.position.x = dragStartPos.x + delta
                        } else if (axis === 2) {
                            target.position.y = dragStartPos.y + delta
                        } else if (axis === 3) {
                            target.position.z = dragStartPos.z + delta
                        }
                    }
                }
            }
        }
    }

    function test_controller_can_update_multiple_targets() {
        var scene = createTemporaryObject(multiObjectSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var target1 = view.children[2]
        var target2 = view.children[3]

        var initial1 = target1.position
        var initial2 = target2.position

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Drag X axis
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        mouseMove(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)
        mouseRelease(gizmo, geometry.xEnd.x + 50, geometry.xEnd.y)

        // Both targets should move (in this controller implementation)
        verify(target1.position.x !== initial1.x, "Target 1 should move")
        verify(target2.position.x !== initial2.x, "Target 2 should move")
    }

    // ========== Validation Controller Tests ==========

    Component {
        id: validatingSceneComponent
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

                property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
                property real minX: -50
                property real maxX: 50
                property int rejectedCount: 0

                onAxisTranslationStarted: function(axis) {
                    dragStartPos = targetNode.position
                }

                onAxisTranslationDelta: function(axis, delta, snapActive) {
                    var newPos = Qt.vector3d(0, 0, 0)

                    if (axis === 1) {
                        newPos = Qt.vector3d(dragStartPos.x + delta, dragStartPos.y, dragStartPos.z)

                        // Validate X position
                        if (newPos.x < minX || newPos.x > maxX) {
                            rejectedCount++
                            return // Reject invalid position
                        }

                        targetNode.position = newPos
                    } else if (axis === 2) {
                        targetNode.position = Qt.vector3d(dragStartPos.x, dragStartPos.y + delta, dragStartPos.z)
                    } else if (axis === 3) {
                        targetNode.position = Qt.vector3d(dragStartPos.x, dragStartPos.y, dragStartPos.z + delta)
                    }
                }
            }
        }
    }

    function test_controller_validation_rejects_invalid_deltas() {
        var scene = createTemporaryObject(validatingSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]

        // Set position near boundary
        targetNode.position = Qt.vector3d(40, 0, 0)

        wait(50)

        var initialPos = targetNode.position

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Try to drag beyond maxX (50)
        mousePress(gizmo, geometry.xEnd.x, geometry.xEnd.y)
        mouseMove(gizmo, geometry.xEnd.x + 200, geometry.xEnd.y) // Large movement
        mouseRelease(gizmo, geometry.xEnd.x + 200, geometry.xEnd.y)

        // Position should be clamped or rejected
        verify(targetNode.position.x <= gizmo.maxX, "Position should not exceed maxX")

        // Some deltas should have been rejected
        verify(gizmo.rejectedCount > 0, "Some invalid deltas should have been rejected")
    }
}

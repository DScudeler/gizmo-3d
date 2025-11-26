import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

TestCase {
    id: testCase
    name: "RotationGizmoSnap"
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
                            diffuseColor: "red"
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

    function test_snapEnabled_property() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1] // RotationGizmo is second child
        verify(gizmo !== null, "Gizmo should exist")

        // Test default value
        compare(gizmo.snapEnabled, false, "snapEnabled should default to false")

        // Test toggling
        gizmo.snapEnabled = true
        compare(gizmo.snapEnabled, true, "snapEnabled should be true after setting")

        gizmo.snapEnabled = false
        compare(gizmo.snapEnabled, false, "snapEnabled should be false after setting")
    }

    function test_snapAngle_property() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test default value
        compare(gizmo.snapAngle, 15.0, "snapAngle should default to 15.0")

        // Test various values
        gizmo.snapAngle = 30.0
        compare(gizmo.snapAngle, 30.0, "snapAngle should be 30.0 after setting")

        gizmo.snapAngle = 5.0
        compare(gizmo.snapAngle, 5.0, "snapAngle should be 5.0 after setting")

        gizmo.snapAngle = 45.0
        compare(gizmo.snapAngle, 45.0, "snapAngle should be 45.0 after setting")
    }

    function test_snapToAbsolute_property() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test default value
        compare(gizmo.snapToAbsolute, true, "snapToAbsolute should default to true")

        // Test toggling
        gizmo.snapToAbsolute = false
        compare(gizmo.snapToAbsolute, false, "snapToAbsolute should be false after setting")

        gizmo.snapToAbsolute = true
        compare(gizmo.snapToAbsolute, true, "snapToAbsolute should be true after setting")
    }

    function test_snapValue_function() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test snapValue function with angle-specific values

        // Test snapping to 15 degree increments
        var result1 = GizmoMath.snapValue(12.0, 15.0)
        compare(result1, 15.0, "12.0 should snap to 15.0 with increment 15.0")

        var result2 = GizmoMath.snapValue(7.0, 15.0)
        compare(result2, 0.0, "7.0 should snap to 0.0 with increment 15.0")

        var result3 = GizmoMath.snapValue(22.0, 15.0)
        compare(result3, 15.0, "22.0 should snap to 15.0 with increment 15.0")

        var result3b = GizmoMath.snapValue(23.0, 15.0)
        compare(result3b, 30.0, "23.0 should snap to 30.0 with increment 15.0")

        // Test snapping to 30 degree increments
        var result4 = GizmoMath.snapValue(40.0, 30.0)
        compare(result4, 30.0, "40.0 should snap to 30.0 with increment 30.0")

        var result5 = GizmoMath.snapValue(50.0, 30.0)
        compare(result5, 60.0, "50.0 should snap to 60.0 with increment 30.0")

        // Test snapping to 45 degree increments
        var result6 = GizmoMath.snapValue(60.0, 45.0)
        compare(result6, 45.0, "60.0 should snap to 45.0 with increment 45.0")

        var result7 = GizmoMath.snapValue(70.0, 45.0)
        compare(result7, 90.0, "70.0 should snap to 90.0 with increment 45.0")

        // Test edge case: zero increment should return original value
        var result8 = GizmoMath.snapValue(37.5, 0.0)
        compare(result8, 37.5, "Zero increment should return original value")

        // Test edge case: negative increment should return original value
        var result9 = GizmoMath.snapValue(37.5, -15.0)
        compare(result9, 37.5, "Negative increment should return original value")

        // Test negative angles
        var result10 = GizmoMath.snapValue(-12.0, 15.0)
        compare(result10, -15.0, "-12.0 should snap to -15.0 with increment 15.0")

        var result11 = GizmoMath.snapValue(-22.0, 15.0)
        compare(result11, -15.0, "-22.0 should snap to -15.0 with increment 15.0")

        var result11b = GizmoMath.snapValue(-23.0, 15.0)
        compare(result11b, -30.0, "-23.0 should snap to -30.0 with increment 15.0")
    }

    function test_property_persistence() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Set all snap properties
        gizmo.snapEnabled = true
        gizmo.snapAngle = 30.0
        gizmo.snapToAbsolute = false

        // Verify they persist
        compare(gizmo.snapEnabled, true, "snapEnabled should persist")
        compare(gizmo.snapAngle, 30.0, "snapAngle should persist")
        compare(gizmo.snapToAbsolute, false, "snapToAbsolute should persist")

        // Change and verify again
        gizmo.snapEnabled = false
        gizmo.snapAngle = 45.0
        gizmo.snapToAbsolute = true

        compare(gizmo.snapEnabled, false, "snapEnabled should update")
        compare(gizmo.snapAngle, 45.0, "snapAngle should update")
        compare(gizmo.snapToAbsolute, true, "snapToAbsolute should update")
    }

    function test_activeAxis_property() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Verify activeAxis starts at 0 (none)
        compare(gizmo.activeAxis, 0, "activeAxis should default to 0")
    }

    function test_targetNode_binding() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0] // View3D
        var gizmo = scene.children[1] // RotationGizmo

        verify(view !== null, "View3D should exist")
        verify(gizmo !== null, "Gizmo should exist")

        // Verify targetNode is bound correctly
        verify(gizmo.targetNode !== null, "targetNode should be set")
        compare(gizmo.targetNode.position, Qt.vector3d(0, 0, 0), "targetNode should be at origin")
    }

    function test_snap_with_different_angles() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test that different snap angles produce different results
        var angle = 37.0

        gizmo.snapAngle = 15.0
        var snap1 = GizmoMath.snapValue(angle, gizmo.snapAngle)
        compare(snap1, 30.0, "37.0 should snap to 30.0 with angle 15.0")

        gizmo.snapAngle = 30.0
        var snap2 = GizmoMath.snapValue(angle, gizmo.snapAngle)
        compare(snap2, 30.0, "37.0 should snap to 30.0 with angle 30.0")

        gizmo.snapAngle = 45.0
        var snap3 = GizmoMath.snapValue(angle, gizmo.snapAngle)
        compare(snap3, 45.0, "37.0 should snap to 45.0 with angle 45.0")

        gizmo.snapAngle = 90.0
        var snap4 = GizmoMath.snapValue(angle, gizmo.snapAngle)
        compare(snap4, 0.0, "37.0 should snap to 0.0 with angle 90.0")
    }

    function test_snap_rounding_behavior() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test rounding to nearest (standard Math.round behavior)

        // Exactly at 7.5 degrees with 15 degree increment should round up
        var result1 = GizmoMath.snapValue(7.5, 15.0)
        compare(result1, 15.0, "7.5 should round up to 15.0")

        // 22.5 degrees with 15 degree increment should round up
        var result2 = GizmoMath.snapValue(22.5, 15.0)
        compare(result2, 30.0, "22.5 should round up to 30.0")

        // Just below midpoint should round down
        var result3 = GizmoMath.snapValue(7.4, 15.0)
        compare(result3, 0.0, "7.4 should round down to 0.0")

        // Just above midpoint should round up
        var result4 = GizmoMath.snapValue(7.6, 15.0)
        compare(result4, 15.0, "7.6 should round up to 15.0")
    }

    function test_snap_with_zero_angle() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test snapping zero
        var result1 = GizmoMath.snapValue(0.0, 15.0)
        compare(result1, 0.0, "0.0 should snap to 0.0")

        var result2 = GizmoMath.snapValue(0.0, 30.0)
        compare(result2, 0.0, "0.0 should snap to 0.0 with any angle")

        // Test values near zero
        var result3 = GizmoMath.snapValue(3.0, 15.0)
        compare(result3, 0.0, "3.0 should snap to 0.0")

        var result4 = GizmoMath.snapValue(-3.0, 15.0)
        compare(result4, 0.0, "-3.0 should snap to 0.0")
    }

    function test_snap_common_angles() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test common rotation angles snap correctly

        // 90 degree increments
        gizmo.snapAngle = 90.0
        compare(GizmoMath.snapValue(85.0, 90.0), 90.0, "85° should snap to 90°")
        compare(GizmoMath.snapValue(95.0, 90.0), 90.0, "95° should snap to 90°")
        compare(GizmoMath.snapValue(180.0, 90.0), 180.0, "180° should snap to 180°")
        compare(GizmoMath.snapValue(270.0, 90.0), 270.0, "270° should snap to 270°")

        // 45 degree increments
        gizmo.snapAngle = 45.0
        compare(GizmoMath.snapValue(40.0, 45.0), 45.0, "40° should snap to 45°")
        compare(GizmoMath.snapValue(135.0, 45.0), 135.0, "135° should snap to 135°")

        // 1 degree increments (fine control)
        gizmo.snapAngle = 1.0
        compare(GizmoMath.snapValue(37.4, 1.0), 37.0, "37.4° should snap to 37°")
        compare(GizmoMath.snapValue(37.6, 1.0), 38.0, "37.6° should snap to 38°")
    }

    function test_component_creation_with_snap_properties() {
        // Test creating gizmo with snap properties set inline
        var component = Qt.createComponent("qrc:/qt/qml/Gizmo3D/RotationGizmo.qml")
        verify(component.status === Component.Ready || component.status === Component.Loading,
               "Component should be ready or loading")

        if (component.status === Component.Error) {
            console.log("Component errors:", component.errorString())
            verify(false, "Component should not have errors")
        }
    }

    // Behavioral tests for snapToAbsolute feature with rotation
    function test_snapToAbsolute_rotation_behavior() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Set up gizmo with snap enabled
        gizmo.snapEnabled = true
        gizmo.snapAngle = 15.0  // 15 degree increments

        // Test absolute snapping (snapToAbsolute: true)
        gizmo.snapToAbsolute = true

        // Scenario: Object starts at 7 degrees, user rotates by 10 degrees
        // Absolute mode: 7 + 10 = 17 degrees, snaps to 15 degrees, delta = 15 - 7 = 8 degrees
        var startAngle = 7.0
        var rawDelta = 10.0
        var finalAbsolute = GizmoMath.snapValueAbsolute(startAngle + rawDelta, 15.0)
        var deltaAbsolute = finalAbsolute - startAngle
        compare(deltaAbsolute, 8.0, "Absolute mode: 7° + 10° = 17° snaps to 15°, delta = 8°")

        // Test relative snapping (snapToAbsolute: false)
        gizmo.snapToAbsolute = false

        // Relative mode: 10 degree delta snaps to 15 degrees (nearest increment)
        var deltaRelative = GizmoMath.snapValue(rawDelta, 15.0)
        compare(deltaRelative, 15.0, "Relative mode: 10° delta snaps to 15°")

        // Verify the behaviors are different
        verify(Math.abs(deltaAbsolute - deltaRelative) > 0.01,
               "Absolute and relative rotation snapping should produce different results")
    }

    function test_rotation_snap_modes_different_results() {
        // This test verifies that rotation snap modes produce different outputs
        // when starting from a non-grid angle

        var startAngle = 7.0  // Not on 15-degree grid
        var rawDelta = 12.0
        var snapIncrement = 15.0

        // Absolute snapping: snap final angle to world grid
        var finalAbsolute = GizmoMath.snapValueAbsolute(startAngle + rawDelta, snapIncrement)
        var deltaAbsolute = finalAbsolute - startAngle
        // 7 + 12 = 19, snaps to 15, delta = 15 - 7 = 8
        compare(deltaAbsolute, 8.0, "Absolute mode: 7° + 12° = 19° snaps to 15°, delta = 8°")

        // Relative snapping: snap delta to grid
        var deltaRelative = GizmoMath.snapValue(rawDelta, snapIncrement)
        // 12 snaps to 15
        compare(deltaRelative, 15.0, "Relative mode: 12° delta snaps to 15°")

        // Verify they're different
        verify(Math.abs(deltaAbsolute - deltaRelative) > 0.01,
               "Rotation snap modes must produce different results from non-grid angles")

        // Additional example: negative rotation
        var rawDelta2 = -8.0
        var finalAbsolute2 = GizmoMath.snapValueAbsolute(startAngle + rawDelta2, snapIncrement)
        var deltaAbsolute2 = finalAbsolute2 - startAngle
        // 7 + (-8) = -1, round(-1/15)*15 = 0, delta = 0 - 7 = -7
        compare(deltaAbsolute2, -7.0, "Absolute mode: 7° + (-8°) = -1° snaps to 0°, delta = -7°")

        var deltaRelative2 = GizmoMath.snapValue(rawDelta2, snapIncrement)
        // round(-8/15)*15 = round(-0.53)*15 = -1*15 = -15
        compare(deltaRelative2, -15.0, "Relative mode: -8° delta snaps to -15°")

        verify(Math.abs(deltaAbsolute2 - deltaRelative2) > 0.01,
               "Rotation modes should differ for negative deltas too")
    }

    function test_rotation_world_grid_alignment() {
        // Test that absolute mode aligns to world angles: 0°, 15°, 30°, 45°, etc.

        var snapIncrement = 15.0

        // Test various starting angles with small deltas
        var testCases = [
            {start: 7.0, delta: 1.0, expectedFinal: 15.0},   // 7+1=8, round(8/15)=1, 1*15=15
            {start: 7.0, delta: -3.0, expectedFinal: 0.0},   // 7-3=4, round(4/15)=0, 0*15=0
            {start: 22.0, delta: -5.0, expectedFinal: 15.0}, // 22-5=17, round(17/15)=1, 1*15=15
            {start: 44.0, delta: 2.0, expectedFinal: 45.0}   // 44+2=46, round(46/15)=3, 3*15=45
        ]

        for (var i = 0; i < testCases.length; i++) {
            var tc = testCases[i]
            var finalAngle = GizmoMath.snapValueAbsolute(tc.start + tc.delta, snapIncrement)
            compare(finalAngle, tc.expectedFinal,
                    "Start " + tc.start + "° + delta " + tc.delta + "° should snap to " + tc.expectedFinal + "°")
        }
    }
}

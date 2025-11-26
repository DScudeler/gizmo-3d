import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

TestCase {
    id: testCase
    name: "TranslationGizmoSnap"
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

    function test_snapEnabled_property() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1] // TranslationGizmo is second child
        verify(gizmo !== null, "Gizmo should exist")

        // Test default value
        compare(gizmo.snapEnabled, false, "snapEnabled should default to false")

        // Test toggling
        gizmo.snapEnabled = true
        compare(gizmo.snapEnabled, true, "snapEnabled should be true after setting")

        gizmo.snapEnabled = false
        compare(gizmo.snapEnabled, false, "snapEnabled should be false after setting")
    }

    function test_snapIncrement_property() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test default value
        compare(gizmo.snapIncrement, 1.0, "snapIncrement should default to 1.0")

        // Test various values
        gizmo.snapIncrement = 5.0
        compare(gizmo.snapIncrement, 5.0, "snapIncrement should be 5.0 after setting")

        gizmo.snapIncrement = 0.5
        compare(gizmo.snapIncrement, 0.5, "snapIncrement should be 0.5 after setting")

        gizmo.snapIncrement = 10.0
        compare(gizmo.snapIncrement, 10.0, "snapIncrement should be 10.0 after setting")
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

        // Test snapValue function directly from GizmoMath
        // Note: This tests the mathematical correctness of the snap function

        // Test snapping to increment of 1.0
        var result1 = GizmoMath.snapValue(1.3, 1.0)
        compare(result1, 1.0, "1.3 should snap to 1.0 with increment 1.0")

        var result2 = GizmoMath.snapValue(1.7, 1.0)
        compare(result2, 2.0, "1.7 should snap to 2.0 with increment 1.0")

        // Test snapping to increment of 5.0
        var result3 = GizmoMath.snapValue(7.0, 5.0)
        compare(result3, 5.0, "7.0 should snap to 5.0 with increment 5.0")

        var result4 = GizmoMath.snapValue(8.0, 5.0)
        compare(result4, 10.0, "8.0 should snap to 10.0 with increment 5.0")

        // Test snapping to increment of 0.5
        var result5 = GizmoMath.snapValue(1.2, 0.5)
        compare(result5, 1.0, "1.2 should snap to 1.0 with increment 0.5")

        var result6 = GizmoMath.snapValue(1.4, 0.5)
        compare(result6, 1.5, "1.4 should snap to 1.5 with increment 0.5")

        // Test edge case: zero increment should return original value
        var result7 = GizmoMath.snapValue(1.234, 0.0)
        compare(result7, 1.234, "Zero increment should return original value")

        // Test edge case: negative increment should return original value
        var result8 = GizmoMath.snapValue(1.234, -1.0)
        compare(result8, 1.234, "Negative increment should return original value")

        // Test negative values
        var result9 = GizmoMath.snapValue(-1.3, 1.0)
        compare(result9, -1.0, "-1.3 should snap to -1.0 with increment 1.0")

        var result10 = GizmoMath.snapValue(-1.7, 1.0)
        compare(result10, -2.0, "-1.7 should snap to -2.0 with increment 1.0")
    }

    function test_property_persistence() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Set all snap properties
        gizmo.snapEnabled = true
        gizmo.snapIncrement = 2.5
        gizmo.snapToAbsolute = false

        // Verify they persist
        compare(gizmo.snapEnabled, true, "snapEnabled should persist")
        compare(gizmo.snapIncrement, 2.5, "snapIncrement should persist")
        compare(gizmo.snapToAbsolute, false, "snapToAbsolute should persist")

        // Change and verify again
        gizmo.snapEnabled = false
        gizmo.snapIncrement = 7.0
        gizmo.snapToAbsolute = true

        compare(gizmo.snapEnabled, false, "snapEnabled should update")
        compare(gizmo.snapIncrement, 7.0, "snapIncrement should update")
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
        var gizmo = scene.children[1] // TranslationGizmo

        verify(view !== null, "View3D should exist")
        verify(gizmo !== null, "Gizmo should exist")

        // Verify targetNode is bound correctly
        verify(gizmo.targetNode !== null, "targetNode should be set")
        compare(gizmo.targetNode.position, Qt.vector3d(0, 0, 0), "targetNode should be at origin")
    }

    Component {
        id: signalSpyComponent
        SignalSpy {}
    }

    function test_snap_with_different_increments() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test that different snap increments produce different results
        var value = 3.7

        gizmo.snapIncrement = 1.0
        var snap1 = GizmoMath.snapValue(value, gizmo.snapIncrement)
        compare(snap1, 4.0, "3.7 should snap to 4.0 with increment 1.0")

        gizmo.snapIncrement = 0.5
        var snap2 = GizmoMath.snapValue(value, gizmo.snapIncrement)
        compare(snap2, 3.5, "3.7 should snap to 3.5 with increment 0.5")

        gizmo.snapIncrement = 5.0
        var snap3 = GizmoMath.snapValue(value, gizmo.snapIncrement)
        compare(snap3, 5.0, "3.7 should snap to 5.0 with increment 5.0")

        gizmo.snapIncrement = 2.0
        var snap4 = GizmoMath.snapValue(value, gizmo.snapIncrement)
        compare(snap4, 4.0, "3.7 should snap to 4.0 with increment 2.0")
    }

    function test_snap_rounding_behavior() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test rounding to nearest (standard Math.round behavior)

        // Exactly at 0.5 should round up (standard JavaScript behavior)
        var result1 = GizmoMath.snapValue(1.5, 1.0)
        compare(result1, 2.0, "1.5 should round up to 2.0")

        var result2 = GizmoMath.snapValue(2.5, 1.0)
        compare(result2, 3.0, "2.5 should round up to 3.0")

        // Just below 0.5 should round down
        var result3 = GizmoMath.snapValue(1.4999, 1.0)
        compare(result3, 1.0, "1.4999 should round down to 1.0")

        // Just above 0.5 should round up
        var result4 = GizmoMath.snapValue(1.5001, 1.0)
        compare(result4, 2.0, "1.5001 should round up to 2.0")
    }

    function test_snap_with_zero_value() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Test snapping zero
        var result1 = GizmoMath.snapValue(0.0, 1.0)
        compare(result1, 0.0, "0.0 should snap to 0.0")

        var result2 = GizmoMath.snapValue(0.0, 5.0)
        compare(result2, 0.0, "0.0 should snap to 0.0 with any increment")

        // Test values near zero
        var result3 = GizmoMath.snapValue(0.3, 1.0)
        compare(result3, 0.0, "0.3 should snap to 0.0")

        var result4 = GizmoMath.snapValue(-0.3, 1.0)
        compare(result4, 0.0, "-0.3 should snap to 0.0")
    }

    function test_component_creation_with_snap_properties() {
        // Test creating gizmo with snap properties set inline
        var component = Qt.createComponent("qrc:/qt/qml/Gizmo3D/TranslationGizmo.qml")
        verify(component.status === Component.Ready || component.status === Component.Loading,
               "Component should be ready or loading")

        if (component.status === Component.Error) {
            console.log("Component errors:", component.errorString())
            verify(false, "Component should not have errors")
        }
    }

    // Behavioral tests for snapToAbsolute feature
    function test_snapToAbsolute_translation_behavior() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        // Set up gizmo with snap enabled
        gizmo.snapEnabled = true
        gizmo.snapIncrement = 1.0

        // Test absolute snapping (snapToAbsolute: true)
        gizmo.snapToAbsolute = true

        // For this test, we verify that GizmoMath.snapValueAbsolute works correctly
        // Scenario: Object starts at 2.3, user drags with raw delta 1.2
        // Absolute mode: 2.3 + 1.2 = 3.5, snaps to 4.0, resulting delta = 4.0 - 2.3 = 1.7
        var absoluteSnap = GizmoMath.snapValueAbsolute(2.3 + 1.2, 1.0) - 2.3
        compare(absoluteSnap, 1.7, "Absolute snap: (2.3 + 1.2) snaps to 4.0, delta is 1.7")

        // Test relative snapping (snapToAbsolute: false)
        gizmo.snapToAbsolute = false

        // With snapToAbsolute=false, delta 1.2 snaps to 1.0 regardless of start position
        var relativeSnap = GizmoMath.snapValue(1.2, 1.0)
        compare(relativeSnap, 1.0, "Relative snap: delta 1.2 snaps to 1.0")

        // Verify the behaviors are different
        verify(absoluteSnap !== relativeSnap,
               "Absolute and relative snapping should produce different results from position 2.3")
    }

    function test_snapValueAbsolute_function() {
        // Test the new snapValueAbsolute function

        // Test snapping to world grid with increment 1.0
        var result1 = GizmoMath.snapValueAbsolute(2.3, 1.0)
        compare(result1, 2.0, "2.3 should snap to world grid at 2.0")

        var result2 = GizmoMath.snapValueAbsolute(2.7, 1.0)
        compare(result2, 3.0, "2.7 should snap to world grid at 3.0")

        var result3 = GizmoMath.snapValueAbsolute(3.5, 1.0)
        compare(result3, 4.0, "3.5 should snap to world grid at 4.0")

        // Test with increment 5.0
        var result4 = GizmoMath.snapValueAbsolute(12.0, 5.0)
        compare(result4, 10.0, "12.0 should snap to world grid at 10.0 with increment 5.0")

        var result5 = GizmoMath.snapValueAbsolute(13.0, 5.0)
        compare(result5, 15.0, "13.0 should snap to world grid at 15.0 with increment 5.0")

        // Test negative values
        var result6 = GizmoMath.snapValueAbsolute(-1.3, 1.0)
        compare(result6, -1.0, "-1.3 should snap to world grid at -1.0")

        var result7 = GizmoMath.snapValueAbsolute(-1.7, 1.0)
        compare(result7, -2.0, "-1.7 should snap to world grid at -2.0")

        // Test edge cases
        var result8 = GizmoMath.snapValueAbsolute(5.0, 1.0)
        compare(result8, 5.0, "5.0 should stay at 5.0 (already on grid)")

        var result9 = GizmoMath.snapValueAbsolute(1.234, 0.0)
        compare(result9, 1.234, "Zero increment should return original value")
    }

    function test_snap_modes_produce_different_results() {
        // This test verifies that the two snap modes actually produce different outputs
        // when starting from a non-grid position

        var startPos = 2.3
        var rawDelta = 1.2
        var increment = 1.0

        // Absolute snapping: snap final position to world grid
        var finalAbsolute = GizmoMath.snapValueAbsolute(startPos + rawDelta, increment)
        var deltaAbsolute = finalAbsolute - startPos
        compare(deltaAbsolute, 1.7, "Absolute mode: delta from 2.3 with raw delta 1.2")

        // Relative snapping: snap delta to grid
        var deltaRelative = GizmoMath.snapValue(rawDelta, increment)
        compare(deltaRelative, 1.0, "Relative mode: snap delta 1.2 to 1.0")

        // Verify they're different
        verify(Math.abs(deltaAbsolute - deltaRelative) > 0.01,
               "Absolute and relative snap modes must produce different results")

        // Additional example: negative delta (avoiding .5 rounding ambiguity)
        var rawDelta2 = -1.0
        var finalAbsolute2 = GizmoMath.snapValueAbsolute(startPos + rawDelta2, increment)
        var deltaAbsolute2 = finalAbsolute2 - startPos
        // 2.3 + (-1.0) = 1.3, snaps to 1.0, delta = 1.0 - 2.3 = -1.3
        compare(deltaAbsolute2, -1.3, "Absolute mode: 2.3 + (-1.0) = 1.3 snaps to 1.0, delta = -1.3")

        var deltaRelative2 = GizmoMath.snapValue(rawDelta2, increment)
        compare(deltaRelative2, -1.0, "Relative mode: snap delta -1.0 stays at -1.0")

        // These will be different (though close) - absolute gives -1.3, relative gives -1.0
        verify(Math.abs(deltaAbsolute2 - deltaRelative2) > 0.01,
               "Modes should differ for negative deltas too")
    }
}

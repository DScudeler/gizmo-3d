import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

// Transform-hierarchy raycast tests (regression for the local-vs-world dragStartPos issue).
//
// The gizmos render and raycast in world/scene space, so their behaviour must depend
// ONLY on the target's scenePosition (world) -- never on the parent-relative .position.
// A target nested under a translated+rotated parent and a top-level target placed at the
// SAME world position must therefore behave identically: same projected geometry, and the
// same emitted delta under identical mouse input.
//
// Before the fix, TranslationGizmo/ScaleGizmo anchored their drag math at targetNode.position
// (parent-relative), so the nested case diverged from the flat case. The raycast tests below
// fail on the old code and pass on the fixed code.
//
// Notes:
//  * Full end-to-end movement of a nested target additionally requires the *controller* to map
//    the emitted world-space delta into the parent's local frame before writing .position; that
//    is intentionally out of scope here (these tests validate the gizmo, not SimpleController).
//  * The mouse-driven tests require an interactive display (the window must actually be shown so
//    synthesized presses route to the gizmo's MouseArea); they skip() gracefully otherwise.
TestCase {
    id: testCase
    name: "GizmoTransformHierarchy"
    width: 800
    height: 600
    visible: true
    when: windowShown

    // A scene with a configurable parent transform and a child target node. Exactly one gizmo
    // is made visible at a time (via activeGizmo) so it owns mouse input; the other still
    // computes geometry on demand but does not intercept events. Last-emitted deltas are recorded.
    Component {
        id: sceneComponent
        Item {
            id: sceneRoot
            width: 800
            height: 600

            // Inputs
            property vector3d parentPos: Qt.vector3d(0, 0, 0)
            property vector3d parentEuler: Qt.vector3d(0, 0, 0)
            property vector3d childLocalPos: Qt.vector3d(0, 0, 0)
            property int mode: GizmoEnums.TransformMode.World
            property string activeGizmo: "translation"   // "translation" | "scale"

            // Exposed handles
            property alias view: view
            property alias target: targetNode
            property alias tgizmo: tgizmo
            property alias sgizmo: sgizmo

            // Recorded signal output
            property int lastTransAxis: GizmoEnums.Axis.None
            property real lastTransDelta: 0
            property int lastScaleAxis: GizmoEnums.Axis.None
            property real lastScaleFactor: 1.0

            View3D {
                id: view
                anchors.fill: parent
                camera: camera

                PerspectiveCamera {
                    id: camera
                    position: Qt.vector3d(0, 0, 400)
                    eulerRotation: Qt.vector3d(0, 0, 0)
                }

                DirectionalLight { eulerRotation: Qt.vector3d(-45, 45, 0) }

                Node {
                    id: parentNode
                    position: sceneRoot.parentPos
                    eulerRotation: sceneRoot.parentEuler

                    Node {
                        id: targetNode
                        position: sceneRoot.childLocalPos
                        Model {
                            source: "#Cube"
                            materials: DefaultMaterial { diffuseColor: "blue" }
                        }
                    }
                }
            }

            TranslationGizmo {
                id: tgizmo
                anchors.fill: parent
                view3d: view
                targetNode: targetNode
                transformMode: sceneRoot.mode
                gizmoSize: 120
                visible: sceneRoot.activeGizmo === "translation"
                onAxisTranslationDelta: function(axis, transformMode, delta, snapActive) {
                    sceneRoot.lastTransAxis = axis
                    sceneRoot.lastTransDelta = delta
                }
            }

            ScaleGizmo {
                id: sgizmo
                anchors.fill: parent
                view3d: view
                targetNode: targetNode
                transformMode: sceneRoot.mode
                gizmoSize: 120
                visible: sceneRoot.activeGizmo === "scale"
                onScaleDelta: function(axis, transformMode, factor, snapActive) {
                    sceneRoot.lastScaleAxis = axis
                    sceneRoot.lastScaleFactor = factor
                }
            }
        }
    }

    // ---- helpers ----
    function approxPoint(a, b, tol) {
        return Math.abs(a.x - b.x) <= tol && Math.abs(a.y - b.y) <= tol
    }

    function makeScene(props) {
        var s = createTemporaryObject(sceneComponent, testCase, props)
        verify(s !== null, "scene created")
        waitForRendering(s, 5000)
        return s
    }

    // Press the X axis at an explicit (integer) screen point, drag +40px, return { hit, value }.
    // Using a fixed, shared press point for both scenes removes mouse-pixel discretization as a
    // variable, so any remaining difference reflects a genuine world-anchoring divergence.
    // `kind` selects the gizmo ("translation" -> delta, "scale" -> factor).
    function dragXAt(scene, kind, px, py) {
        var giz = kind === "scale" ? scene.sgizmo : scene.tgizmo
        mousePress(giz, px, py)
        if (giz.activeAxis === GizmoEnums.Axis.None) {
            mouseRelease(giz, px, py)
            return { hit: false, value: 0 }   // interactive hit detection not available
        }
        mouseMove(giz, px + 40, py)
        var value = kind === "scale" ? scene.lastScaleFactor : scene.lastTransDelta
        mouseRelease(giz, px + 40, py)
        return { hit: true, value: value }
    }

    // Run the SAME +40px X drag (identical screen coords) on a nested scene and on a top-level
    // scene placed at the nested target's world position, and assert the emitted value matches.
    function checkHierarchyInvariance(kind) {
        // Nested: parent translated + rotated, child offset locally.
        var nested = makeScene({
            parentPos: Qt.vector3d(30, 10, 0),
            parentEuler: Qt.vector3d(0, 30, 0),
            childLocalPos: Qt.vector3d(20, 0, 0),
            mode: GizmoEnums.TransformMode.World,
            activeGizmo: kind
        })
        var w = nested.target.scenePosition
        // Guard: local .position must really differ from world scenePosition.
        verify(Math.abs(nested.target.position.x - w.x) > 1.0
            || Math.abs(nested.target.position.z - w.z) > 1.0,
            "nested local .position must differ from world scenePosition")

        // Shared press point (rounded to a pixel) derived from the nested gizmo geometry.
        var giz = kind === "scale" ? nested.sgizmo : nested.tgizmo
        var g = giz.calculateGizmoGeometry()
        verify(g !== null, "nested geometry calculated")
        var px = Math.round(g.xEnd.x), py = Math.round(g.xEnd.y)

        var rNested = dragXAt(nested, kind, px, py)
        nested.destroy()
        wait(50)   // ensure the nested scene is gone before the flat scene takes over the window

        // Flat: top-level node at the SAME world position, pressed at the SAME screen point.
        var flat = makeScene({
            childLocalPos: w,
            mode: GizmoEnums.TransformMode.World,
            activeGizmo: kind
        })
        var rFlat = dragXAt(flat, kind, px, py)
        flat.destroy()

        if (!rNested.hit || !rFlat.hit) {
            skip("interactive hit detection unavailable in this rendering mode")
            return
        }

        var baseline = kind === "scale" ? 1.0 : 0.0
        verify(Math.abs(rNested.value - baseline) > 1e-4, "a non-trivial " + kind + " value should be produced")
        // Identical inputs + identical scenePosition => values must agree very tightly; a real
        // local-vs-world regression would diverge by far more than this.
        var tol = Math.max(1e-2, Math.abs(rFlat.value) * 0.01)
        fuzzyCompare(rNested.value, rFlat.value, tol,
            "nested and flat must agree (" + kind + ": nested=" + rNested.value + " flat=" + rFlat.value + ")")
    }

    // ===== Deterministic: display anchored at scenePosition, independent of hierarchy =====
    function test_display_world_anchored_at_scene_position() {
        var nested = makeScene({
            parentPos: Qt.vector3d(30, 10, 0), parentEuler: Qt.vector3d(0, 30, 0),
            childLocalPos: Qt.vector3d(20, 0, 0), mode: GizmoEnums.TransformMode.World
        })
        var w = nested.target.scenePosition
        var flat = makeScene({ childLocalPos: w, mode: GizmoEnums.TransformMode.World })

        var gN = nested.tgizmo.calculateGizmoGeometry()
        var gF = flat.tgizmo.calculateGizmoGeometry()
        verify(gN !== null && gF !== null, "geometries calculated")
        verify(isFinite(gN.center.x) && isFinite(gN.center.y), "nested center finite")

        verify(approxPoint(gN.center, gF.center, 0.5),
            "CENTER must match (display anchored at scenePosition): "
            + JSON.stringify(gN.center) + " vs " + JSON.stringify(gF.center))
        verify(approxPoint(gN.xEnd, gF.xEnd, 0.5), "X endpoint must match")
        verify(approxPoint(gN.yEnd, gF.yEnd, 0.5), "Y endpoint must match")
        verify(approxPoint(gN.zEnd, gF.zEnd, 0.5), "Z endpoint must match")
    }

    // ===== Deterministic: Local transform mode reflects the parent rotation on screen =====
    // Uses a roll (Z rotation) so the local X axis rotates within the screen plane, giving a
    // clear, view-independent screen-space difference from World mode.
    function test_display_local_mode_uses_parent_rotation() {
        var common = {
            parentPos: Qt.vector3d(30, 10, 0),
            parentEuler: Qt.vector3d(0, 0, 45),
            childLocalPos: Qt.vector3d(20, 0, 0)
        }
        var world = makeScene(Object.assign({ mode: GizmoEnums.TransformMode.World }, common))
        var local = makeScene(Object.assign({ mode: GizmoEnums.TransformMode.Local }, common))

        var gW = world.tgizmo.calculateGizmoGeometry()
        var gL = local.tgizmo.calculateGizmoGeometry()
        verify(gW !== null && gL !== null, "geometries calculated")

        verify(approxPoint(gW.center, gL.center, 0.5), "centers match in both modes")
        verify(!approxPoint(gW.xEnd, gL.xEnd, 5.0),
            "Local-mode X axis must differ from World-mode (parent roll applied): "
            + JSON.stringify(gW.xEnd) + " vs " + JSON.stringify(gL.xEnd))
        verify(isFinite(gL.xEnd.x) && isFinite(gL.xEnd.y), "local-mode geometry finite")
    }

    // ===== Raycast invariance (mouse) =====
    function test_translation_raycast_hierarchy_invariant() {
        checkHierarchyInvariance("translation")
    }

    function test_scale_raycast_hierarchy_invariant() {
        checkHierarchyInvariance("scale")
    }
}

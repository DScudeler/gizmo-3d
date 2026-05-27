import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

// Deterministic geometry tests for the rotation circle calculator, using MockProjection
// (no View3D / camera required, so these run reliably headless). They guard the two
// performance fixes in the circle path:
//   D-007: the active segment count is 48 (-> 49 points incl. the closing point), and that
//          count matches GeometryTemplates.defaultSegments so the cached unit circle is used.
//   D-006: circle points are finite 2D points (x/y), suitable to hand straight to PathPolyline.
TestCase {
    id: testCase
    name: "RotationCircleGeometry"

    function projector() {
        return MockProjection.createProjector({
            type: "perspective",
            cameraPosition: Qt.vector3d(0, 0, 300),
            viewportSize: Qt.size(800, 600)
        })
    }

    function worldAxes() {
        return { x: Qt.vector3d(1, 0, 0), y: Qt.vector3d(0, 1, 0), z: Qt.vector3d(0, 0, 1) }
    }

    function circleGeometry(extra) {
        var cfg = {
            projector: projector(),
            targetPosition: Qt.vector3d(0, 0, 0),
            axes: worldAxes(),
            gizmoSize: 80,
            maxScreenRadius: 100
        }
        if (extra) for (var k in extra) cfg[k] = extra[k]
        return RotationGeometryCalculator.calculateCircleGeometry(cfg)
    }

    // D-007: default segment count is 48 -> 49 points (matches the cached template).
    function test_default_segment_count_is_48() {
        var geo = circleGeometry(null)   // segments omitted -> calculator default
        verify(geo !== null, "geometry computed")
        compare(geo.circles.xy.length, 49, "48 segments -> 49 points (incl. closing point)")
        compare(geo.circles.yz.length, 49, "yz: 49 points")
        compare(geo.circles.zx.length, 49, "zx: 49 points")
    }

    // D-006: every circle point (and the center) is a finite 2D coordinate.
    function test_circle_points_finite_2d() {
        var geo = circleGeometry(null)
        verify(geo !== null, "geometry computed")
        verify(isFinite(geo.center.x) && isFinite(geo.center.y), "center finite")
        var planes = ["xy", "yz", "zx"]
        for (var p = 0; p < planes.length; p++) {
            var c = geo.circles[planes[p]]
            for (var i = 0; i < c.length; i++) {
                verify(isFinite(c[i].x) && isFinite(c[i].y),
                       planes[p] + " point " + i + " must be finite")
            }
        }
    }

    // An explicit segment count is still honoured (calculator stays general-purpose).
    function test_explicit_segment_count_honoured() {
        var geo = circleGeometry({ segments: 16 })
        verify(geo !== null, "geometry computed")
        compare(geo.circles.xy.length, 17, "16 segments -> 17 points")
    }

    // Exercises the C++ calculator's NATIVE projection path (View3DProjectionAdapter exposes
    // a real View3D, so the C++ calc calls View3D::mapFrom3DScene directly rather than the
    // JS fallback). Requires a camera-bearing View3D.
    Component {
        id: view3dSceneComponent
        Item {
            width: 800; height: 600
            property alias gizmo: rgizmo
            View3D {
                id: view
                anchors.fill: parent
                camera: camera
                PerspectiveCamera { id: camera; position: Qt.vector3d(0, 0, 300) }
                DirectionalLight {}
                Node { id: target; position: Qt.vector3d(0, 0, 0); Model { source: "#Cube" } }
            }
            RotationGizmo { id: rgizmo; anchors.fill: parent; view3d: view; targetNode: target; gizmoSize: 80 }
        }
    }

    function test_native_path_via_view3d() {
        var scene = createTemporaryObject(view3dSceneComponent, testCase)
        verify(scene !== null, "scene created")
        waitForRendering(scene, 5000)

        // calculateCircleGeometry() builds a real View3DProjectionAdapter projector (carries
        // the View3D) and calls the C++ RotationGeometryCalculator -> native mapFrom3DScene.
        var geo = scene.gizmo.calculateCircleGeometry()
        verify(geo !== null, "native-path geometry computed (View3D projector)")
        compare(geo.circles.xy.length, 49, "48 segments -> 49 points (native path)")
        verify(isFinite(geo.center.x) && isFinite(geo.center.y), "center finite")
        var c = geo.circles.yz
        for (var i = 0; i < c.length; i++)
            verify(isFinite(c[i].x) && isFinite(c[i].y), "native yz point " + i + " finite")
        // Center should project near the screen middle for a target at origin facing the camera.
        verify(geo.center.x > 300 && geo.center.x < 500, "center x near screen middle: " + geo.center.x)
    }
}

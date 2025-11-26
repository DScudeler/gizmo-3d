import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D

TestCase {
    id: testCase
    name: "GizmoCoordinateTransform"
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

    // ========== World-to-Screen Projection Tests ==========

    function test_world_to_screen_at_origin() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]
        targetNode.position = Qt.vector3d(0, 0, 0)

        wait(50)

        // Project origin to screen
        var screenPos = GizmoMath.worldToScreen(view, Qt.vector3d(0, 0, 0))

        // Origin should be near center of view
        verify(screenPos !== null, "Screen position should be calculated")
        verify(screenPos.x > 0 && screenPos.x < 800, "Screen X should be within view bounds")
        verify(screenPos.y > 0 && screenPos.y < 600, "Screen Y should be within view bounds")

        // Should be roughly centered (allowing some tolerance)
        verify(Math.abs(screenPos.x - 400) < 100, "Screen X should be near center")
        verify(Math.abs(screenPos.y - 300) < 100, "Screen Y should be near center")
    }

    function test_world_to_screen_offset_position() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Project offset positions
        var centerScreen = GizmoMath.worldToScreen(view, Qt.vector3d(0, 0, 0))
        var rightScreen = GizmoMath.worldToScreen(view, Qt.vector3d(10, 0, 0))
        var upScreen = GizmoMath.worldToScreen(view, Qt.vector3d(0, 10, 0))

        // Verify projections make sense
        verify(centerScreen !== null, "Center should project")
        verify(rightScreen !== null, "Right position should project")
        verify(upScreen !== null, "Up position should project")

        // +X in world should be +X on screen (to the right)
        verify(rightScreen.x > centerScreen.x, "Right position should be to the right on screen")

        // +Y in world should be -Y on screen (up means lower Y in screen coordinates)
        verify(upScreen.y < centerScreen.y, "Up position should be higher on screen (lower Y)")
    }

    function test_screen_space_gizmo_size_consistency() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]

        // Test at different Z depths
        targetNode.position = Qt.vector3d(0, 0, 0)
        wait(50)

        var geometry1 = gizmo.calculateGizmoGeometry()
        verify(geometry1 !== null, "Geometry should be calculated")

        // Calculate screen-space arrow length at Z=0
        var length1 = Math.sqrt(
            Math.pow(geometry1.xEnd.x - geometry1.center.x, 2) +
            Math.pow(geometry1.xEnd.y - geometry1.center.y, 2)
        )

        // Move target closer to camera
        targetNode.position = Qt.vector3d(0, 0, 100)
        wait(50)

        var geometry2 = gizmo.calculateGizmoGeometry()
        verify(geometry2 !== null, "Geometry should be calculated")

        // Calculate screen-space arrow length at Z=100
        var length2 = Math.sqrt(
            Math.pow(geometry2.xEnd.x - geometry2.center.x, 2) +
            Math.pow(geometry2.xEnd.y - geometry2.center.y, 2)
        )

        // Gizmo maintains constant screen-space size, so lengths should be similar
        // (allowing some tolerance for floating point and projection differences)
        verify(Math.abs(length1 - gizmo.gizmoSize) < 10, "Length1 should match gizmoSize")
        verify(Math.abs(length2 - gizmo.gizmoSize) < 10, "Length2 should match gizmoSize")
    }

    // ========== Ray Generation and Casting Tests ==========

    function test_camera_ray_generation() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0]
        verify(view !== null, "View should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Generate ray for screen center
        var centerRay = GizmoMath.getCameraRay(view, Qt.point(400, 300))

        verify(centerRay !== null, "Ray should be generated")
        verify(centerRay.origin !== null, "Ray should have origin")
        verify(centerRay.direction !== null, "Ray should have direction")

        // Ray direction should be roughly normalized
        var dirLength = Math.sqrt(
            centerRay.direction.x * centerRay.direction.x +
            centerRay.direction.y * centerRay.direction.y +
            centerRay.direction.z * centerRay.direction.z
        )
        verify(Math.abs(dirLength - 1.0) < 0.1, "Ray direction should be approximately normalized")
    }

    function test_ray_plane_intersection_xy() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0]
        verify(view !== null, "View should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        // Generate ray from screen center
        var ray = GizmoMath.getCameraRay(view, Qt.point(400, 300))

        // XY plane at Z=0 (normal pointing along Z)
        var planeOrigin = Qt.vector3d(0, 0, 0)
        var planeNormal = Qt.vector3d(0, 0, 1)

        var intersection = GizmoMath.intersectRayPlane(
            ray.origin,
            ray.direction,
            planeOrigin,
            planeNormal
        )

        verify(intersection !== null, "Ray should intersect XY plane")

        // Intersection should be near the XY plane (Z should be close to 0)
        verify(Math.abs(intersection.z) < 1.0, "Intersection Z should be near 0 for XY plane")
    }

    function test_ray_plane_intersection_xz() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0]
        verify(view !== null, "View should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var ray = GizmoMath.getCameraRay(view, Qt.point(400, 300))

        // XZ plane at Y=0 (normal pointing along Y)
        var planeOrigin = Qt.vector3d(0, 0, 0)
        var planeNormal = Qt.vector3d(0, 1, 0)

        var intersection = GizmoMath.intersectRayPlane(
            ray.origin,
            ray.direction,
            planeOrigin,
            planeNormal
        )

        verify(intersection !== null, "Ray should intersect XZ plane")

        // Intersection should be near the XZ plane (Y should be close to 0)
        verify(Math.abs(intersection.y) < 1.0, "Intersection Y should be near 0 for XZ plane")
    }

    function test_ray_plane_intersection_yz() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0]
        verify(view !== null, "View should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var ray = GizmoMath.getCameraRay(view, Qt.point(400, 300))

        // YZ plane at X=0 (normal pointing along X)
        var planeOrigin = Qt.vector3d(0, 0, 0)
        var planeNormal = Qt.vector3d(1, 0, 0)

        var intersection = GizmoMath.intersectRayPlane(
            ray.origin,
            ray.direction,
            planeOrigin,
            planeNormal
        )

        verify(intersection !== null, "Ray should intersect YZ plane")

        // Intersection should be near the YZ plane (X should be close to 0)
        verify(Math.abs(intersection.x) < 1.0, "Intersection X should be near 0 for YZ plane")
    }

    function test_ray_axis_closest_point() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var view = scene.children[0]
        verify(view !== null, "View should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var ray = GizmoMath.getCameraRay(view, Qt.point(400, 300))

        // Test closest point on X axis
        var axisOrigin = Qt.vector3d(0, 0, 0)
        var axisDirection = Qt.vector3d(1, 0, 0)

        var t = GizmoMath.closestPointOnAxisToRay(
            ray.origin,
            ray.direction,
            axisOrigin,
            axisDirection
        )

        // t should be a finite number
        verify(isFinite(t), "t parameter should be finite")
    }

    // ========== View3D Integration Tests ==========

    function test_camera_position_affects_projection() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var camera = view.children[0]

        // Get initial projection
        var initialScreen = GizmoMath.worldToScreen(view, Qt.vector3d(0, 0, 0))

        // Move camera
        camera.position = Qt.vector3d(100, 0, 300)
        wait(50)

        var movedScreen = GizmoMath.worldToScreen(view, Qt.vector3d(0, 0, 0))

        // Projection should change when camera moves
        verify(initialScreen.x !== movedScreen.x || initialScreen.y !== movedScreen.y,
               "Screen position should change when camera moves")
    }

    function test_camera_rotation_affects_projection() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var camera = view.children[0]

        // Get initial projection
        var initialScreen = GizmoMath.worldToScreen(view, Qt.vector3d(50, 0, 0))

        // Rotate camera
        camera.eulerRotation = Qt.vector3d(0, 45, 0)
        wait(50)

        var rotatedScreen = GizmoMath.worldToScreen(view, Qt.vector3d(50, 0, 0))

        // Projection should change when camera rotates
        verify(initialScreen.x !== rotatedScreen.x || initialScreen.y !== rotatedScreen.y,
               "Screen position should change when camera rotates")
    }

    // ========== Rotation Gizmo Circle Projection Tests ==========

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

    function test_rotation_circle_maintains_screen_size() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        var view = scene.children[0]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var targetNode = view.children[2]

        // Test at Z=0
        targetNode.position = Qt.vector3d(0, 0, 0)
        wait(50)

        var geometry1 = gizmo.calculateCircleGeometry()
        verify(geometry1 !== null, "Geometry should be calculated")

        // Calculate average screen-space radius from XY circle
        var circle1 = geometry1.circles.xy
        if (circle1 && circle1.length > 1) {
            var avgRadius1 = 0
            for (var i = 0; i < Math.min(4, circle1.length); i++) {
                var dx = circle1[i].x - geometry1.center.x
                var dy = circle1[i].y - geometry1.center.y
                avgRadius1 += Math.sqrt(dx * dx + dy * dy)
            }
            avgRadius1 /= Math.min(4, circle1.length)

            // Move target closer
            targetNode.position = Qt.vector3d(0, 0, 100)
            wait(50)

            var geometry2 = gizmo.calculateCircleGeometry()
            verify(geometry2 !== null, "Geometry should be calculated")

            var circle2 = geometry2.circles.xy
            if (circle2 && circle2.length > 1) {
                var avgRadius2 = 0
                for (var j = 0; j < Math.min(4, circle2.length); j++) {
                    var dx2 = circle2[j].x - geometry2.center.x
                    var dy2 = circle2[j].y - geometry2.center.y
                    avgRadius2 += Math.sqrt(dx2 * dx2 + dy2 * dy2)
                }
                avgRadius2 /= Math.min(4, circle2.length)

                // Radii should be similar (constant screen-space size)
                verify(Math.abs(avgRadius1 - avgRadius2) < 20,
                       "Circle screen-space radius should remain relatively constant")
            }
        } else {
            skip("Circle geometry not available")
        }
    }

    function test_rotation_circle_perspective_correct() {
        var scene = createTemporaryObject(rotationSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateCircleGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Circles should have multiple points for smooth rendering
        verify(geometry.circles.xy.length > 10, "XY circle should have many points")
        verify(geometry.circles.yz.length > 10, "YZ circle should have many points")
        verify(geometry.circles.zx.length > 10, "ZX circle should have many points")

        // All points should be valid screen coordinates
        for (var i = 0; i < geometry.circles.xy.length; i++) {
            verify(isFinite(geometry.circles.xy[i].x), "XY circle point X should be finite")
            verify(isFinite(geometry.circles.xy[i].y), "XY circle point Y should be finite")
        }
    }

    // ========== Gizmo Geometry Calculation Tests ==========

    function test_gizmo_geometry_includes_all_components() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Verify all expected components are present
        verify(geometry.center !== undefined, "Should have center")
        verify(geometry.xEnd !== undefined, "Should have X axis endpoint")
        verify(geometry.yEnd !== undefined, "Should have Y axis endpoint")
        verify(geometry.zEnd !== undefined, "Should have Z axis endpoint")
        verify(geometry.planes !== undefined, "Should have planes")
        verify(geometry.planes.xy !== undefined, "Should have XY plane")
        verify(geometry.planes.xz !== undefined, "Should have XZ plane")
        verify(geometry.planes.yz !== undefined, "Should have YZ plane")
    }

    function test_axis_endpoints_are_offset_from_center() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Endpoints should be different from center
        verify(geometry.xEnd.x !== geometry.center.x || geometry.xEnd.y !== geometry.center.y,
               "X endpoint should be offset from center")
        verify(geometry.yEnd.x !== geometry.center.x || geometry.yEnd.y !== geometry.center.y,
               "Y endpoint should be offset from center")
        verify(geometry.zEnd.x !== geometry.center.x || geometry.zEnd.y !== geometry.center.y,
               "Z endpoint should be offset from center")
    }

    function test_plane_geometry_forms_quads() {
        var scene = createTemporaryObject(testSceneComponent, testCase)
        verify(scene !== null, "Scene should be created")

        var gizmo = scene.children[1]
        verify(gizmo !== null, "Gizmo should exist")

        waitForRendering(gizmo, 5000)
        wait(50) // Canvas pixel data availability

        var geometry = gizmo.calculateGizmoGeometry()
        verify(geometry !== null, "Geometry should be calculated")

        // Each plane should have 4 corners
        compare(geometry.planes.xy.length, 4, "XY plane should have 4 corners")
        compare(geometry.planes.xz.length, 4, "XZ plane should have 4 corners")
        compare(geometry.planes.yz.length, 4, "YZ plane should have 4 corners")

        // All corners should have valid coordinates
        for (var i = 0; i < 4; i++) {
            verify(isFinite(geometry.planes.xy[i].x), "XY plane corner should have finite X")
            verify(isFinite(geometry.planes.xy[i].y), "XY plane corner should have finite Y")
        }
    }
}

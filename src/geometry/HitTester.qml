// HitTester.qml - Geometric hit detection for gizmo components
// Pure functions for testing mouse hits against geometric primitives

pragma Singleton
import QtQuick
import Gizmo3D

QtObject {
    /**
     * Tests if a mouse position hits an axis
     * @param mousePos - point screen-space mouse position
     * @param axisGeometry - Array of {axis: int, start: point, end: point}
     * @param threshold - real hit distance threshold in pixels
     * @returns {hit: bool, axis: int, distance: real}
     */
    function testAxisHit(mousePos, axisGeometry, threshold) {
        var closestAxis = GizmoEnums.Axis.None
        var closestDistance = Infinity

        for (var i = 0; i < axisGeometry.length; i++) {
            var test = axisGeometry[i]
            var distance = GizmoMath.distanceToLineSegment2D(mousePos, test.start, test.end)

            if (distance <= threshold && distance < closestDistance) {
                closestDistance = distance
                closestAxis = test.axis
            }
        }

        return {
            hit: closestAxis !== GizmoEnums.Axis.None,
            axis: closestAxis,
            distance: closestDistance
        }
    }

    /**
     * Tests if a mouse position hits a plane (quad)
     * @param mousePos - point screen-space mouse position
     * @param planeGeometry - Array of {plane: int, corners: [point, point, point, point]}
     * @returns {hit: bool, plane: int}
     */
    function testPlaneHit(mousePos, planeGeometry) {
        for (var i = 0; i < planeGeometry.length; i++) {
            var test = planeGeometry[i]
            if (test.corners && test.corners.length === 4) {
                if (GizmoMath.pointInQuad2D(mousePos, test.corners)) {
                    return {
                        hit: true,
                        plane: test.plane
                    }
                }
            }
        }

        return {
            hit: false,
            plane: GizmoEnums.Plane.None
        }
    }

    /**
     * Tests if a mouse position hits a circle (polyline)
     * @param mousePos - point screen-space mouse position
     * @param circleGeometry - Array of {axis: int, points: [point, ...]}
     * @param threshold - real hit distance threshold in pixels
     * @param arcRangeFunc - Optional function(axis, mousePos, circlePoints) -> bool
     *                       to test if hit is within valid arc range
     * @returns {hit: bool, axis: int, distance: real}
     */
    function testCircleHit(mousePos, circleGeometry, threshold, arcRangeFunc) {
        var closestAxis = GizmoEnums.Axis.None
        var closestDistance = Infinity

        for (var i = 0; i < circleGeometry.length; i++) {
            var test = circleGeometry[i]
            if (!test.points || test.points.length < 2) continue

            var distance = GizmoMath.distanceToPolyline2D(mousePos, test.points)

            if (distance <= threshold && distance < closestDistance) {
                // Optional arc range check
                if (arcRangeFunc && !arcRangeFunc(test.axis, mousePos, test.points)) {
                    continue
                }

                closestDistance = distance
                closestAxis = test.axis
            }
        }

        return {
            hit: closestAxis !== GizmoEnums.Axis.None,
            axis: closestAxis,
            distance: closestDistance
        }
    }

    /**
     * Tests if a mouse position hits a center handle (point)
     * @param mousePos - point screen-space mouse position
     * @param handlePos - point screen-space handle center
     * @param threshold - real hit distance threshold in pixels
     * @returns {hit: bool, distance: real}
     */
    function testCenterHandleHit(mousePos, handlePos, threshold) {
        var dx = mousePos.x - handlePos.x
        var dy = mousePos.y - handlePos.y
        var distance = Math.sqrt(dx * dx + dy * dy)

        return {
            hit: distance <= threshold,
            distance: distance
        }
    }

    /**
     * Combined hit test for translation gizmo (axes + planes)
     * @param mousePos - point screen-space mouse position
     * @param geometry - Object with {xStart, xEnd, yStart, yEnd, zStart, zEnd, planes: {xy, xz, yz}}
     * @param axisThreshold - real axis hit threshold in pixels
     * @returns {type: "none"|"axis"|"plane", axis: int, plane: int}
     */
    function testTranslationGizmoHit(mousePos, geometry, axisThreshold) {
        if (!geometry) {
            return {type: "none"}
        }

        // Test axes first (priority over planes)
        var axisGeometry = [
            {axis: GizmoEnums.Axis.X, start: geometry.xStart, end: geometry.xEnd},
            {axis: GizmoEnums.Axis.Y, start: geometry.yStart, end: geometry.yEnd},
            {axis: GizmoEnums.Axis.Z, start: geometry.zStart, end: geometry.zEnd}
        ]

        var axisHit = testAxisHit(mousePos, axisGeometry, axisThreshold)
        if (axisHit.hit) {
            return {type: "axis", axis: axisHit.axis}
        }

        // Test planes
        var planeGeometry = [
            {plane: GizmoEnums.Plane.XY, corners: geometry.planes.xy},
            {plane: GizmoEnums.Plane.XZ, corners: geometry.planes.xz},
            {plane: GizmoEnums.Plane.YZ, corners: geometry.planes.yz}
        ]

        var planeHit = testPlaneHit(mousePos, planeGeometry)
        if (planeHit.hit) {
            return {type: "plane", plane: planeHit.plane}
        }

        return {type: "none"}
    }

    /**
     * Combined hit test for rotation gizmo (circles)
     * @param mousePos - point screen-space mouse position
     * @param geometry - Object with {circles: {xy, yz, zx}}
     * @param circleThreshold - real circle hit threshold in pixels
     * @param arcRangeFunc - Optional arc range validation function
     * @returns {type: "none"|"circle", axis: int}
     */
    function testRotationGizmoHit(mousePos, geometry, circleThreshold, arcRangeFunc) {
        if (!geometry || !geometry.circles) {
            return {type: "none"}
        }

        var circleGeometry = [
            {axis: GizmoEnums.Axis.Z, points: geometry.circles.xy},  // Z-axis (XY plane)
            {axis: GizmoEnums.Axis.X, points: geometry.circles.yz},  // X-axis (YZ plane)
            {axis: GizmoEnums.Axis.Y, points: geometry.circles.zx}   // Y-axis (ZX plane)
        ]

        var circleHit = testCircleHit(mousePos, circleGeometry, circleThreshold, arcRangeFunc)
        if (circleHit.hit) {
            return {type: "circle", axis: circleHit.axis}
        }

        return {type: "none"}
    }

    /**
     * Combined hit test for scale gizmo (axes + center handle)
     * @param mousePos - point screen-space mouse position
     * @param geometry - Object with {center, xStart, xEnd, yStart, yEnd, zStart, zEnd}
     * @param axisThreshold - real axis hit threshold in pixels
     * @param centerThreshold - real center handle hit threshold in pixels
     * @returns {type: "none"|"axis"|"center", axis: int}
     */
    function testScaleGizmoHit(mousePos, geometry, axisThreshold, centerThreshold) {
        if (!geometry) {
            return {type: "none"}
        }

        // Test center handle first (highest priority)
        var centerHit = testCenterHandleHit(mousePos, geometry.center, centerThreshold)
        if (centerHit.hit) {
            return {type: "center", axis: GizmoEnums.Axis.Uniform}  // Uniform scale
        }

        // Test axes
        var axisGeometry = [
            {axis: GizmoEnums.Axis.X, start: geometry.xStart, end: geometry.xEnd},
            {axis: GizmoEnums.Axis.Y, start: geometry.yStart, end: geometry.yEnd},
            {axis: GizmoEnums.Axis.Z, start: geometry.zStart, end: geometry.zEnd}
        ]

        var axisHit = testAxisHit(mousePos, axisGeometry, axisThreshold)
        if (axisHit.hit) {
            return {type: "axis", axis: axisHit.axis}
        }

        return {type: "none"}
    }
}

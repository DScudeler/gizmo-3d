// RotationGeometryCalculator.qml - Pure geometry calculation for rotation gizmo
// Decouples circle geometry computation from rendering to enable unit testing

pragma Singleton
import QtQuick
import Gizmo3D

QtObject {
    /**
     * Linear interpolation between two values
     * @param a - Start value
     * @param b - End value
     * @param t - Interpolation factor (0-1)
     * @returns Interpolated value
     */
    function lerp(a, b, t) {
        return a + (b - a) * t
    }

    /**
     * Calculates circle geometry for rotation gizmo
     * @param config - Configuration object:
     *   {
     *     projector: Projector object implementing GizmoProjection interface
     *     targetPosition: vector3d - Center position of gizmo in world space
     *     axes: {x, y, z} - Axis directions (world or local)
     *     gizmoSize: real - Base screen-space size in pixels
     *     maxScreenRadius: real - Maximum screen-space radius in pixels
     *     segments: int - Number of segments for circle polylines (default: 64)
     *     previousRadii: {xy, yz, zx} - Previous frame radii for smoothing (optional)
     *     smoothingFactor: real - Lerp factor for temporal smoothing (default: 0.3)
     *   }
     * @returns Geometry object or null if invalid config:
     *   {
     *     center: point - Screen-space center
     *     circles: {
     *       xy: [point, ...] - XY plane circle (Z-axis rotation)
     *       yz: [point, ...] - YZ plane circle (X-axis rotation)
     *       zx: [point, ...] - ZX plane circle (Y-axis rotation)
     *     }
     *     radii: {
     *       xy: real - World-space radius for XY plane
     *       yz: real - World-space radius for YZ plane
     *       zx: real - World-space radius for ZX plane
     *     }
     *   }
     */
    function calculateCircleGeometry(config) {
        if (!config || !config.projector || !config.targetPosition || !config.axes) {
            console.error("RotationGeometryCalculator: Invalid config")
            return null
        }

        var projector = config.projector
        var targetPosition = config.targetPosition
        var axes = config.axes
        var gizmoSize = config.gizmoSize || 80.0
        var maxScreenRadius = config.maxScreenRadius || 100.0
        var segments = config.segments || 48
        var previousRadii = config.previousRadii || null
        var smoothingFactor = config.smoothingFactor !== undefined ? config.smoothingFactor : 0.3

        // Project target position to screen
        var center = GizmoProjection.projectWorldToScreen(targetPosition, projector)

        // Calculate per-plane scales by measuring both axes of each plane
        var xAxisScale = projectAxisToScreen(targetPosition, Qt.vector3d(1, 0, 0), projector, center)
        var yAxisScale = projectAxisToScreen(targetPosition, Qt.vector3d(0, 1, 0), projector, center)
        var zAxisScale = projectAxisToScreen(targetPosition, Qt.vector3d(0, 0, 1), projector, center)

        // Average the two axes that define each plane
        var xyPlaneScale = (xAxisScale + yAxisScale) / 2
        var yzPlaneScale = (yAxisScale + zAxisScale) / 2
        var zxPlaneScale = (zAxisScale + xAxisScale) / 2

        // Calculate radius for each plane based on its own projection
        var rawRadiusXY = xyPlaneScale > 0 ? gizmoSize / xyPlaneScale : 1.0
        var rawRadiusYZ = yzPlaneScale > 0 ? gizmoSize / yzPlaneScale : 1.0
        var rawRadiusZX = zxPlaneScale > 0 ? gizmoSize / zxPlaneScale : 1.0

        // Apply temporal smoothing to eliminate jitter during camera movement
        var radiusXY, radiusYZ, radiusZX
        if (previousRadii) {
            radiusXY = lerp(previousRadii.xy, rawRadiusXY, smoothingFactor)
            radiusYZ = lerp(previousRadii.yz, rawRadiusYZ, smoothingFactor)
            radiusZX = lerp(previousRadii.zx, rawRadiusZX, smoothingFactor)
        } else {
            radiusXY = rawRadiusXY
            radiusYZ = rawRadiusYZ
            radiusZX = rawRadiusZX
        }

        // Generate circle points for each plane
        var circlePoints = {
            xy: generateCirclePoints(targetPosition, axes.x, axes.y, radiusXY, segments, projector),
            yz: generateCirclePoints(targetPosition, axes.y, axes.z, radiusYZ, segments, projector),
            zx: generateCirclePointsZX(targetPosition, axes.x, axes.z, radiusZX, segments, projector)
        }

        // Apply per-plane screen-space clamping as safety limit
        var planeData = [
            {key: 'xy', points: circlePoints.xy, radius: radiusXY, axis1: axes.x, axis2: axes.y},
            {key: 'yz', points: circlePoints.yz, radius: radiusYZ, axis1: axes.y, axis2: axes.z},
            {key: 'zx', points: circlePoints.zx, radius: radiusZX, axis1: axes.x, axis2: axes.z}
        ]

        for (var p = 0; p < planeData.length; p++) {
            var plane = planeData[p]
            var maxDist = 0

            // Measure screen-space extent for this plane
            for (var j = 0; j < plane.points.length; j++) {
                var dx = plane.points[j].x - center.x
                var dy = plane.points[j].y - center.y
                var dist = Math.sqrt(dx * dx + dy * dy)
                maxDist = Math.max(maxDist, dist)
            }

            // If this circle exceeds maximum, scale existing points
            if (maxDist > maxScreenRadius) {
                var clampScale = maxScreenRadius / maxDist
                for (var s = 0; s < plane.points.length; s++) {
                    var pt = plane.points[s]
                    plane.points[s] = Qt.point(
                        center.x + (pt.x - center.x) * clampScale,
                        center.y + (pt.y - center.y) * clampScale
                    )
                }
                if (plane.key === 'xy') radiusXY = plane.radius * clampScale
                else if (plane.key === 'yz') radiusYZ = plane.radius * clampScale
                else if (plane.key === 'zx') radiusZX = plane.radius * clampScale
            }
        }

        return {
            center: center,
            circles: circlePoints,
            radii: {
                xy: radiusXY,
                yz: radiusYZ,
                zx: radiusZX
            }
        }
    }

    /**
     * Projects a unit axis vector to screen space and measures its length
     * @param center - vector3d world-space center point
     * @param axis - vector3d unit axis direction
     * @param projector - Projector object
     * @returns real screen-space length
     */
    function projectAxisToScreen(center, axis, projector, centerScreen) {
        var testPoint = Qt.vector3d(
            center.x + axis.x,
            center.y + axis.y,
            center.z + axis.z
        )

        var testScreen = GizmoProjection.projectWorldToScreen(testPoint, projector)

        var dx = testScreen.x - centerScreen.x
        var dy = testScreen.y - centerScreen.y
        return Math.sqrt(dx * dx + dy * dy)
    }

    /**
     * Generates circle points in a plane defined by two axes
     * Uses precomputed unit circle template for performance (avoids per-frame trig)
     * @param center - vector3d world-space center
     * @param axis1 - vector3d first axis (X-like)
     * @param axis2 - vector3d second axis (Y-like)
     * @param radius - real world-space radius
     * @param segments - int number of segments
     * @param projector - Projector object
     * @returns Array of screen-space points
     */
    function generateCirclePoints(center, axis1, axis2, radius, segments, projector) {
        var points = []
        var template = GeometryTemplates.getUnitCircle(segments)

        for (var i = 0; i < template.length; i++) {
            var c = template[i].cos
            var s = template[i].sin
            var wx = center.x + axis1.x * c * radius + axis2.x * s * radius
            var wy = center.y + axis1.y * c * radius + axis2.y * s * radius
            var wz = center.z + axis1.z * c * radius + axis2.z * s * radius
            points.push(GizmoProjection.projectWorldToScreen(Qt.vector3d(wx, wy, wz), projector))
        }

        return points
    }

    /**
     * Generates circle points for ZX plane with swapped sin/cos order
     * Uses precomputed unit circle template for performance (avoids per-frame trig)
     * This matches the original RotationGizmo's ZX plane parametrization
     * @param center - vector3d world-space center
     * @param axisX - vector3d X axis
     * @param axisZ - vector3d Z axis
     * @param radius - real world-space radius
     * @param segments - int number of segments
     * @param projector - Projector object
     * @returns Array of screen-space points
     */
    function generateCirclePointsZX(center, axisX, axisZ, radius, segments, projector) {
        var points = []
        var template = GeometryTemplates.getUnitCircle(segments)

        for (var i = 0; i < template.length; i++) {
            var c = template[i].cos
            var s = template[i].sin
            // Note: sin on X, cos on Z (matches original)
            var wx = center.x + axisX.x * s * radius + axisZ.x * c * radius
            var wy = center.y + axisX.y * s * radius + axisZ.y * c * radius
            var wz = center.z + axisX.z * s * radius + axisZ.z * c * radius
            points.push(GizmoProjection.projectWorldToScreen(Qt.vector3d(wx, wy, wz), projector))
        }

        return points
    }

    /**
     * Calculates the angle on a rotation plane that faces the camera
     * @param targetPosition - vector3d gizmo center
     * @param planeNormal - vector3d plane normal direction
     * @param referenceAxis - vector3d reference axis for angle measurement
     * @param projector - Projector object
     * @returns real angle in radians (0 to 2π)
     */
    function calculateCameraFacingAngle(targetPosition, planeNormal, referenceAxis, projector) {
        // Get direction from target to camera
        var cameraPos = GizmoProjection.getCameraPosition(projector)
        var targetToCamera = Qt.vector3d(
            cameraPos.x - targetPosition.x,
            cameraPos.y - targetPosition.y,
            cameraPos.z - targetPosition.z
        )

        // Project onto the rotation plane by removing normal component
        var dotProduct = targetToCamera.x * planeNormal.x +
                        targetToCamera.y * planeNormal.y +
                        targetToCamera.z * planeNormal.z

        var projectedDir = Qt.vector3d(
            targetToCamera.x - planeNormal.x * dotProduct,
            targetToCamera.y - planeNormal.y * dotProduct,
            targetToCamera.z - planeNormal.z * dotProduct
        )

        // Normalize the projected direction
        var length = Math.sqrt(
            projectedDir.x * projectedDir.x +
            projectedDir.y * projectedDir.y +
            projectedDir.z * projectedDir.z
        )

        if (length < 0.001) return 0  // Camera aligned with plane normal

        projectedDir = Qt.vector3d(
            projectedDir.x / length,
            projectedDir.y / length,
            projectedDir.z / length
        )

        // Calculate angle relative to reference axis using atan2
        // Get perpendicular axis: planeNormal × referenceAxis
        var perpAxis = Qt.vector3d(
            planeNormal.y * referenceAxis.z - planeNormal.z * referenceAxis.y,
            planeNormal.z * referenceAxis.x - planeNormal.x * referenceAxis.z,
            planeNormal.x * referenceAxis.y - planeNormal.y * referenceAxis.x
        )

        // Dot products give us cosine and sine of the angle
        var cosAngle = projectedDir.x * referenceAxis.x +
                      projectedDir.y * referenceAxis.y +
                      projectedDir.z * referenceAxis.z

        var sinAngle = projectedDir.x * perpAxis.x +
                      projectedDir.y * perpAxis.y +
                      projectedDir.z * perpAxis.z

        var angle = Math.atan2(sinAngle, cosAngle)

        // Normalize to [0, 2π]
        while (angle < 0) angle += Math.PI * 2
        while (angle >= Math.PI * 2) angle -= Math.PI * 2

        return angle
    }
}

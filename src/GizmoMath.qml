pragma Singleton

import QtQuick

QtObject {
    // ========================================
    // Coordinate Space Conversion Functions
    // ========================================

    function worldToScreen(view3d, position) {
        if (!view3d) return Qt.point(0, 0)
        return view3d.mapFrom3DScene(position)
    }

    function screenToWorld(view3d, screenPos) {
        if (!view3d) return Qt.vector3d(0, 0, 0)
        return view3d.mapTo3DScene(screenPos)
    }

    // ========================================
    // Vector Math Helper Functions
    // ========================================

    function dotProduct(a, b) {
        return a.x * b.x + a.y * b.y + a.z * b.z
    }

    function crossProduct(a, b) {
        return Qt.vector3d(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }

    function normalize(v) {
        var len = Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
        if (len < 0.0001) return Qt.vector3d(0, 0, 1)
        return Qt.vector3d(v.x / len, v.y / len, v.z / len)
    }

    function vectorSubtract(a, b) {
        return Qt.vector3d(a.x - b.x, a.y - b.y, a.z - b.z)
    }

    function vectorAdd(a, b) {
        return Qt.vector3d(a.x + b.x, a.y + b.y, a.z + b.z)
    }

    function vectorScale(v, s) {
        return Qt.vector3d(v.x * s, v.y * s, v.z * s)
    }

    function vectorLength(v) {
        return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    }

    // ========================================
    // Camera Ray Construction
    // ========================================

    // Construct a camera ray through a screen point
    // Returns object with {origin, direction} in world space
    function getCameraRay(view3d, screenPos) {
        if (!view3d) {
            return {
                origin: Qt.vector3d(0, 0, 0),
                direction: Qt.vector3d(0, 0, -1)
            }
        }

        // Get two points along the ray at different depths
        var nearPoint = view3d.mapTo3DScene(screenPos)
        var farPoint = view3d.mapTo3DScene(Qt.vector3d(screenPos.x, screenPos.y, 100))

        // Calculate ray direction (from near to far, away from camera)
        // Note: Qt's mapTo3DScene appears to use inverted depth
        var dx = nearPoint.x - farPoint.x
        var dy = nearPoint.y - farPoint.y
        var dz = nearPoint.z - farPoint.z
        var length = Math.sqrt(dx * dx + dy * dy + dz * dz)

        if (length < 0.0001) {
            return {
                origin: nearPoint,
                direction: Qt.vector3d(0, 0, -1)
            }
        }

        return {
            origin: nearPoint,
            direction: Qt.vector3d(dx / length, dy / length, dz / length)
        }
    }

    // ========================================
    // Ray-Geometry Intersection Functions
    // ========================================

    // Calculate closest point on an axis to a ray
    // Returns the scalar t such that axisOrigin + t*axisDir is closest to the ray
    function closestPointOnAxisToRay(rayOrigin, rayDir, axisOrigin, axisDir) {
        // Vector from axis origin to ray origin
        var wx = rayOrigin.x - axisOrigin.x
        var wy = rayOrigin.y - axisOrigin.y
        var wz = rayOrigin.z - axisOrigin.z

        // Dot products
        var a = rayDir.x * rayDir.x + rayDir.y * rayDir.y + rayDir.z * rayDir.z  // |R|²
        var b = rayDir.x * axisDir.x + rayDir.y * axisDir.y + rayDir.z * axisDir.z  // R·A
        var c = axisDir.x * axisDir.x + axisDir.y * axisDir.y + axisDir.z * axisDir.z  // |A|²
        var d = rayDir.x * wx + rayDir.y * wy + rayDir.z * wz  // R·w
        var e = axisDir.x * wx + axisDir.y * wy + axisDir.z * wz  // A·w

        var denom = a * c - b * b

        // Check if ray and axis are parallel
        if (Math.abs(denom) < 0.001) {
            // Parallel case: project w onto axis
            return e / c
        }

        // Calculate parameter t for the axis
        return (b * d - a * e) / denom
    }

    // Ray-plane intersection
    // Returns intersection point in world space, or null if ray is parallel to plane
    function intersectRayPlane(rayOrigin, rayDir, planeOrigin, planeNormal) {
        var denom = dotProduct(rayDir, planeNormal)

        // Ray is parallel to plane
        if (Math.abs(denom) < 0.0001) {
            return null
        }

        var diff = vectorSubtract(planeOrigin, rayOrigin)
        var t = dotProduct(diff, planeNormal) / denom

        // Calculate intersection point: rayOrigin + t * rayDir
        return vectorAdd(rayOrigin, vectorScale(rayDir, t))
    }

    // ========================================
    // Snap Helper Functions
    // ========================================

    // Snap a delta/relative value to the nearest increment
    // Used for relative snapping (snapToAbsolute: false)
    function snapValue(value, increment) {
        if (increment <= 0) return value
        return Math.round(value / increment) * increment
    }

    // Snap an absolute value to the nearest world grid position
    // Used for world-space snapping (snapToAbsolute: true)
    function snapValueAbsolute(value, increment) {
        if (increment <= 0) return value
        return Math.round(value / increment) * increment
    }

    // ========================================
    // Angle Utilities
    // ========================================

    function normalizeAngleDelta(delta) {
        while (delta > Math.PI) delta -= Math.PI * 2
        while (delta < -Math.PI) delta += Math.PI * 2
        return delta
    }

    function calculatePlaneAngle(point, center, planeNormal, referenceAxis) {
        // Get vector from center to point
        var toPoint = vectorSubtract(point, center)

        // Project onto plane (remove component along normal)
        var normalComponent = dotProduct(toPoint, planeNormal)
        var projected = vectorSubtract(toPoint, vectorScale(planeNormal, normalComponent))

        // Construct orthonormal basis for the plane
        var xAxis = normalize(referenceAxis)
        var yAxis = normalize(crossProduct(planeNormal, xAxis))

        // Calculate angle using atan2 with plane-local coordinates
        var x = dotProduct(projected, xAxis)
        var y = dotProduct(projected, yAxis)

        return Math.atan2(y, x)
    }

    // ========================================
    // Quaternion Helper Functions
    // ========================================

    function quaternionFromAxisAngle(axis, angleDegrees) {
        // Convert degrees to radians
        var angleRadians = angleDegrees * (Math.PI / 180)
        var halfAngle = angleRadians / 2
        var sinHalf = Math.sin(halfAngle)
        var cosHalf = Math.cos(halfAngle)

        // Quaternion: w + xi + yj + zk (scalar, x, y, z)
        return Qt.quaternion(
            cosHalf,                 // scalar (w)
            axis.x * sinHalf,        // x
            axis.y * sinHalf,        // y
            axis.z * sinHalf         // z
        )
    }

    /**
     * Transform (rotate) a vector by a quaternion
     * @param vec - Vector3d to transform
     * @param quat - Quaternion rotation to apply
     * @returns Rotated vector3d
     */
    function transformVectorByQuaternion(vec, quat) {
        // Quaternion-vector multiplication: q * v * q^(-1)
        // For unit quaternions, q^(-1) = q* (conjugate)

        // Extract quaternion components (w, x, y, z)
        var w = quat.scalar
        var qx = quat.x
        var qy = quat.y
        var qz = quat.z

        // Calculate q * v (treating v as pure quaternion with w=0)
        var tw = -qx * vec.x - qy * vec.y - qz * vec.z
        var tx = w * vec.x + qy * vec.z - qz * vec.y
        var ty = w * vec.y + qz * vec.x - qx * vec.z
        var tz = w * vec.z + qx * vec.y - qy * vec.x

        // Calculate (q * v) * q^(-1) where q^(-1) = (w, -qx, -qy, -qz)
        return Qt.vector3d(
            tx * w + tw * (-qx) + ty * (-qz) - tz * (-qy),
            ty * w + tw * (-qy) + tz * (-qx) - tx * (-qz),
            tz * w + tw * (-qz) + tx * (-qy) - ty * (-qx)
        )
    }

    /**
     * Get local coordinate axes from a node's rotation quaternion
     * @param rotation - Quaternion representing the node's rotation
     * @returns Object with {x, y, z} vector3d local axes
     */
    function getLocalAxes(rotation) {
        return {
            x: transformVectorByQuaternion(Qt.vector3d(1, 0, 0), rotation),
            y: transformVectorByQuaternion(Qt.vector3d(0, 1, 0), rotation),
            z: transformVectorByQuaternion(Qt.vector3d(0, 0, 1), rotation)
        }
    }

    // ========================================
    // 2D Hit Detection Geometry Functions
    // ========================================

    /**
     * Calculate distance from point to line segment in 2D
     * @param point - The test point {x, y}
     * @param lineStart - Segment start {x, y}
     * @param lineEnd - Segment end {x, y}
     * @returns Distance in pixels
     */
    function distanceToLineSegment2D(point, lineStart, lineEnd) {
        var dx = lineEnd.x - lineStart.x
        var dy = lineEnd.y - lineStart.y

        var lengthSquared = dx * dx + dy * dy

        // Degenerate case: line segment is a point
        if (lengthSquared < 0.0001) {
            var dpx = point.x - lineStart.x
            var dpy = point.y - lineStart.y
            return Math.sqrt(dpx * dpx + dpy * dpy)
        }

        // Project point onto line: t = ((P-A)·(B-A)) / |B-A|²
        var t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / lengthSquared

        // Clamp to segment bounds [0, 1]
        t = Math.max(0, Math.min(1, t))

        // Calculate closest point on segment
        var closestX = lineStart.x + t * dx
        var closestY = lineStart.y + t * dy

        // Distance from point to closest point
        var distX = point.x - closestX
        var distY = point.y - closestY

        return Math.sqrt(distX * distX + distY * distY)
    }

    /**
     * Test if point is inside a 2D quadrilateral
     * @param point - The test point {x, y}
     * @param corners - Array of 4 corner points [{x, y}, {x, y}, {x, y}, {x, y}]
     * @returns true if point is inside quad
     */
    function pointInQuad2D(point, corners) {
        if (!corners || corners.length !== 4) {
            return false
        }

        // Ray-crossing algorithm: count intersections with edges
        var crossings = 0
        var x = point.x
        var y = point.y

        for (var i = 0; i < 4; i++) {
            var j = (i + 1) % 4
            var x1 = corners[i].x
            var y1 = corners[i].y
            var x2 = corners[j].x
            var y2 = corners[j].y

            // Check if ray crosses edge
            if (((y1 <= y && y < y2) || (y2 <= y && y < y1)) &&
                (x < (x2 - x1) * (y - y1) / (y2 - y1) + x1)) {
                crossings++
            }
        }

        // Odd number of crossings = inside
        return (crossings % 2) === 1
    }

    /**
     * Calculate minimum distance from point to a polyline (series of connected segments)
     * @param point - The test point {x, y}
     * @param polylinePoints - Array of points [{x, y}, ...] forming connected segments
     * @returns Minimum distance in pixels
     */
    function distanceToPolyline2D(point, polylinePoints) {
        if (!polylinePoints || polylinePoints.length < 2) {
            return Infinity
        }

        var minDistance = Infinity

        // Test distance to each segment
        for (var i = 0; i < polylinePoints.length - 1; i++) {
            var dist = distanceToLineSegment2D(point, polylinePoints[i], polylinePoints[i + 1])
            minDistance = Math.min(minDistance, dist)
        }

        return minDistance
    }
}

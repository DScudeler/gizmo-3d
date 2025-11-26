// ScaleGeometryCalculator.qml - Pure geometry calculation for scale gizmo
// Decouples geometry computation from rendering to enable unit testing

pragma Singleton
import QtQuick
import Gizmo3D

QtObject {
    /**
     * Calculates arrow and handle geometry for scale gizmo
     * @param config - Configuration object:
     *   {
     *     projector: Projector object implementing GizmoProjection interface
     *     targetPosition: vector3d - Center position of gizmo in world space
     *     axes: {x, y, z} - Axis directions (world or local)
     *     gizmoSize: real - Base screen-space size in pixels
     *     maxScreenSize: real - Maximum screen-space extent in pixels
     *     arrowStartRatio: real - Start ratio for arrow (0.0-1.0)
     *     arrowEndRatio: real - End ratio for arrow (0.0-1.0)
     *   }
     * @returns Geometry object or null if invalid config:
     *   {
     *     center: point - Screen-space center
     *     xStart: point, xEnd: point - X arrow endpoints
     *     yStart: point, yEnd: point - Y arrow endpoints
     *     zStart: point, zEnd: point - Z arrow endpoints
     *   }
     */
    function calculateHandleGeometry(config) {
        if (!config || !config.projector || !config.targetPosition || !config.axes) {
            console.error("ScaleGeometryCalculator: Invalid config")
            return null
        }

        var projector = config.projector
        var targetPosition = config.targetPosition
        var axes = config.axes
        var gizmoSize = config.gizmoSize || 100.0
        var maxScreenSize = config.maxScreenSize || 150.0
        var arrowStartRatio = config.arrowStartRatio !== undefined ? config.arrowStartRatio : 0.0
        var arrowEndRatio = config.arrowEndRatio !== undefined ? config.arrowEndRatio : 1.0

        // Project target position to screen
        var center = GizmoProjection.projectWorldToScreen(targetPosition, projector)

        // Calculate world-space axis endpoints
        var xEnd = GizmoMath.vectorAdd(targetPosition, axes.x)
        var yEnd = GizmoMath.vectorAdd(targetPosition, axes.y)
        var zEnd = GizmoMath.vectorAdd(targetPosition, axes.z)

        // Project endpoints to screen space
        var xScreen = GizmoProjection.projectWorldToScreen(xEnd, projector)
        var yScreen = GizmoProjection.projectWorldToScreen(yEnd, projector)
        var zScreen = GizmoProjection.projectWorldToScreen(zEnd, projector)

        // Calculate screen-space directions
        var xDir = Qt.point(xScreen.x - center.x, xScreen.y - center.y)
        var yDir = Qt.point(yScreen.x - center.x, yScreen.y - center.y)
        var zDir = Qt.point(zScreen.x - center.x, zScreen.y - center.y)

        // Normalize and scale to gizmoSize
        var xLen = Math.sqrt(xDir.x * xDir.x + xDir.y * xDir.y)
        var yLen = Math.sqrt(yDir.x * yDir.x + yDir.y * yDir.y)
        var zLen = Math.sqrt(zDir.x * zDir.x + zDir.y * zDir.y)

        if (xLen > 0) xDir = Qt.point(xDir.x / xLen * gizmoSize, xDir.y / xLen * gizmoSize)
        if (yLen > 0) yDir = Qt.point(yDir.x / yLen * gizmoSize, yDir.y / yLen * gizmoSize)
        if (zLen > 0) zDir = Qt.point(zDir.x / zLen * gizmoSize, zDir.y / zLen * gizmoSize)

        // Apply screen-space clamping to prevent oversized handles
        var maxDist = Math.max(
            Math.sqrt(xDir.x * xDir.x + xDir.y * xDir.y),
            Math.sqrt(yDir.x * yDir.x + yDir.y * yDir.y),
            Math.sqrt(zDir.x * zDir.x + zDir.y * zDir.y)
        )

        var clampScale = 1.0
        if (maxDist > maxScreenSize) {
            clampScale = maxScreenSize / maxDist
            xDir = Qt.point(xDir.x * clampScale, xDir.y * clampScale)
            yDir = Qt.point(yDir.x * clampScale, yDir.y * clampScale)
            zDir = Qt.point(zDir.x * clampScale, zDir.y * clampScale)
        }

        // Calculate actual arrow endpoints based on ratios
        var xStart = Qt.point(
            center.x + xDir.x * arrowStartRatio,
            center.y + xDir.y * arrowStartRatio
        )
        var xActualEnd = Qt.point(
            center.x + xDir.x * arrowEndRatio,
            center.y + xDir.y * arrowEndRatio
        )

        var yStart = Qt.point(
            center.x + yDir.x * arrowStartRatio,
            center.y + yDir.y * arrowStartRatio
        )
        var yActualEnd = Qt.point(
            center.x + yDir.x * arrowEndRatio,
            center.y + yDir.y * arrowEndRatio
        )

        var zStart = Qt.point(
            center.x + zDir.x * arrowStartRatio,
            center.y + zDir.y * arrowStartRatio
        )
        var zActualEnd = Qt.point(
            center.x + zDir.x * arrowEndRatio,
            center.y + zDir.y * arrowEndRatio
        )

        return {
            center: center,
            xStart: xStart,
            xEnd: xActualEnd,
            yStart: yStart,
            yEnd: yActualEnd,
            zStart: zStart,
            zEnd: zActualEnd
        }
    }
}

// TranslationGeometryCalculator.qml - Pure geometry calculation for translation gizmo
// Decouples geometry computation from rendering to enable unit testing

pragma Singleton
import QtQuick
import Gizmo3D

QtObject {
    /**
     * Calculates arrow and plane geometry for translation gizmo
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
     *     planes: {
     *       xy: [point, point, point, point] - XY plane corners
     *       xz: [point, point, point, point] - XZ plane corners
     *       yz: [point, point, point, point] - YZ plane corners
     *     }
     *   }
     */
    function calculateArrowGeometry(config) {
        if (!config || !config.projector || !config.targetPosition || !config.axes) {
            console.error("TranslationGeometryCalculator: Invalid config")
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

        // Apply screen-space clamping to prevent oversized arrows
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

        // Calculate world-space scale factor for planes
        var avgLen = (xLen + yLen + zLen) / 3
        var worldScale = avgLen > 0 ? gizmoSize / avgLen : 1.0
        worldScale *= clampScale

        // Calculate plane geometry
        var planeOffset = worldScale * 0.4
        var planeSize = worldScale * 0.3

        // XY plane corners
        var xyCenter = GizmoMath.vectorAdd(
            GizmoMath.vectorAdd(targetPosition, GizmoMath.vectorScale(axes.x, planeOffset)),
            GizmoMath.vectorScale(axes.y, planeOffset)
        )
        var xyCorners = calculatePlaneCorners(xyCenter, axes.x, axes.y, planeSize, projector)

        // XZ plane corners
        var xzCenter = GizmoMath.vectorAdd(
            GizmoMath.vectorAdd(targetPosition, GizmoMath.vectorScale(axes.x, planeOffset)),
            GizmoMath.vectorScale(axes.z, planeOffset)
        )
        var xzCorners = calculatePlaneCorners(xzCenter, axes.x, axes.z, planeSize, projector)

        // YZ plane corners
        var yzCenter = GizmoMath.vectorAdd(
            GizmoMath.vectorAdd(targetPosition, GizmoMath.vectorScale(axes.y, planeOffset)),
            GizmoMath.vectorScale(axes.z, planeOffset)
        )
        var yzCorners = calculatePlaneCorners(yzCenter, axes.y, axes.z, planeSize, projector)

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
            zEnd: zActualEnd,
            planes: {
                xy: xyCorners,
                xz: xzCorners,
                yz: yzCorners
            }
        }
    }

    /**
     * Calculates plane corners in world space and projects to screen space
     * @param center - vector3d plane center in world space
     * @param axis1 - vector3d first axis direction
     * @param axis2 - vector3d second axis direction
     * @param size - real plane size in world units
     * @param projector - Projector object
     * @returns Array of 4 screen-space points (corners)
     */
    function calculatePlaneCorners(center, axis1, axis2, size, projector) {
        var halfSize = size / 2

        // Calculate world-space corners
        var corners = [
            GizmoMath.vectorAdd(
                GizmoMath.vectorAdd(center, GizmoMath.vectorScale(axis1, halfSize)),
                GizmoMath.vectorScale(axis2, halfSize)
            ),
            GizmoMath.vectorAdd(
                GizmoMath.vectorSubtract(center, GizmoMath.vectorScale(axis1, halfSize)),
                GizmoMath.vectorScale(axis2, halfSize)
            ),
            GizmoMath.vectorSubtract(
                GizmoMath.vectorSubtract(center, GizmoMath.vectorScale(axis1, halfSize)),
                GizmoMath.vectorScale(axis2, halfSize)
            ),
            GizmoMath.vectorSubtract(
                GizmoMath.vectorAdd(center, GizmoMath.vectorScale(axis1, halfSize)),
                GizmoMath.vectorScale(axis2, halfSize)
            )
        ]

        // Project to screen space
        return corners.map(function(corner) {
            return GizmoProjection.projectWorldToScreen(corner, projector)
        })
    }

    /**
     * Snaps planar movement delta to grid
     * @param delta - vector3d raw translation delta
     * @param plane - int plane identifier (1=XY, 2=XZ, 3=YZ)
     * @param startPos - vector3d drag start position (for absolute snapping)
     * @param snapIncrement - real snap grid size
     * @param snapToAbsolute - bool true for world grid, false for relative
     * @returns vector3d snapped delta
     */
    function snapPlaneMovement(delta, plane, startPos, snapIncrement, snapToAbsolute) {
        var snappedX = delta.x
        var snappedY = delta.y
        var snappedZ = delta.z

        if (snapToAbsolute) {
            // Snap to world grid
            if (plane === GizmoEnums.Plane.XY) {  // XY plane
                snappedX = GizmoMath.snapValueAbsolute(startPos.x + delta.x, snapIncrement) - startPos.x
                snappedY = GizmoMath.snapValueAbsolute(startPos.y + delta.y, snapIncrement) - startPos.y
                snappedZ = 0
            } else if (plane === GizmoEnums.Plane.XZ) {  // XZ plane
                snappedX = GizmoMath.snapValueAbsolute(startPos.x + delta.x, snapIncrement) - startPos.x
                snappedY = 0
                snappedZ = GizmoMath.snapValueAbsolute(startPos.z + delta.z, snapIncrement) - startPos.z
            } else if (plane === GizmoEnums.Plane.YZ) {  // YZ plane
                snappedX = 0
                snappedY = GizmoMath.snapValueAbsolute(startPos.y + delta.y, snapIncrement) - startPos.y
                snappedZ = GizmoMath.snapValueAbsolute(startPos.z + delta.z, snapIncrement) - startPos.z
            }
        } else {
            // Snap relative to drag start
            if (plane === GizmoEnums.Plane.XY) {  // XY plane
                snappedX = GizmoMath.snapValue(delta.x, snapIncrement)
                snappedY = GizmoMath.snapValue(delta.y, snapIncrement)
                snappedZ = 0
            } else if (plane === GizmoEnums.Plane.XZ) {  // XZ plane
                snappedX = GizmoMath.snapValue(delta.x, snapIncrement)
                snappedY = 0
                snappedZ = GizmoMath.snapValue(delta.z, snapIncrement)
            } else if (plane === GizmoEnums.Plane.YZ) {  // YZ plane
                snappedX = 0
                snappedY = GizmoMath.snapValue(delta.y, snapIncrement)
                snappedZ = GizmoMath.snapValue(delta.z, snapIncrement)
            }
        }

        return Qt.vector3d(snappedX, snappedY, snappedZ)
    }
}

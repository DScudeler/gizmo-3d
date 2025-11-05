import QtQuick
import QtQuick3D

Item {
    id: root

    // Properties
    property View3D view3d: null
    property Node targetNode: null
    property real gizmoSize: 100.0
    property vector3d targetPosition: targetNode ? targetNode.position : Qt.vector3d(0, 0, 0)

    // Active axis: 0 = none, 1 = X, 2 = Y, 3 = Z
    property int activeAxis: 0

    // Colors for each axis
    readonly property color xAxisColor: activeAxis === 1 ? "#ff6666" : "#ff0000"
    readonly property color yAxisColor: activeAxis === 2 ? "#66ff66" : "#00ff00"
    readonly property color zAxisColor: activeAxis === 3 ? "#6666ff" : "#0000ff"

    anchors.fill: parent

    // Convert 3D position to 2D screen coordinates
    function worldToScreen(position) {
        if (!view3d) return Qt.point(0, 0)
        return view3d.mapFrom3DScene(position)
    }

    // Convert 2D screen coordinates to 3D world position on the camera plane
    function screenToWorld(screenPos) {
        if (!view3d) return Qt.vector3d(0, 0, 0)
        return view3d.mapTo3DScene(screenPos)
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            if (!view3d || !targetNode) return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // Get screen position of target
            var center = worldToScreen(targetPosition)

            // Get camera direction to calculate arrow directions
            var cameraPos = view3d.camera ? view3d.camera.position : Qt.vector3d(0, 0, 10)

            // Calculate axis endpoints in world space
            var xEnd = Qt.vector3d(targetPosition.x + 1, targetPosition.y, targetPosition.z)
            var yEnd = Qt.vector3d(targetPosition.x, targetPosition.y + 1, targetPosition.z)
            var zEnd = Qt.vector3d(targetPosition.x, targetPosition.y, targetPosition.z + 1)

            // Convert to screen space
            var xScreen = worldToScreen(xEnd)
            var yScreen = worldToScreen(yEnd)
            var zScreen = worldToScreen(zEnd)

            // Calculate normalized directions
            var xDir = Qt.point(xScreen.x - center.x, xScreen.y - center.y)
            var yDir = Qt.point(yScreen.x - center.x, yScreen.y - center.y)
            var zDir = Qt.point(zScreen.x - center.x, zScreen.y - center.y)

            // Normalize and scale
            var xLen = Math.sqrt(xDir.x * xDir.x + xDir.y * xDir.y)
            var yLen = Math.sqrt(yDir.x * yDir.x + yDir.y * yDir.y)
            var zLen = Math.sqrt(zDir.x * zDir.x + zDir.y * zDir.y)

            if (xLen > 0) xDir = Qt.point(xDir.x / xLen * gizmoSize, xDir.y / yLen * gizmoSize)
            if (yLen > 0) yDir = Qt.point(yDir.x / yLen * gizmoSize, yDir.y / yLen * gizmoSize)
            if (zLen > 0) zDir = Qt.point(zDir.x / zLen * gizmoSize, zDir.y / zLen * gizmoSize)

            // Draw X axis (red)
            drawArrow(ctx, center, Qt.point(center.x + xDir.x, center.y + xDir.y), xAxisColor, 3)

            // Draw Y axis (green)
            drawArrow(ctx, center, Qt.point(center.x + yDir.x, center.y + yDir.y), yAxisColor, 3)

            // Draw Z axis (blue)
            drawArrow(ctx, center, Qt.point(center.x + zDir.x, center.y + zDir.y), zAxisColor, 3)
        }

        function drawArrow(ctx, start, end, color, lineWidth) {
            ctx.strokeStyle = color
            ctx.fillStyle = color
            ctx.lineWidth = lineWidth
            ctx.lineCap = "round"

            // Draw line
            ctx.beginPath()
            ctx.moveTo(start.x, start.y)
            ctx.lineTo(end.x, end.y)
            ctx.stroke()

            // Draw arrowhead
            var angle = Math.atan2(end.y - start.y, end.x - start.x)
            var headLength = 15
            var headAngle = Math.PI / 6

            ctx.beginPath()
            ctx.moveTo(end.x, end.y)
            ctx.lineTo(
                end.x - headLength * Math.cos(angle - headAngle),
                end.y - headLength * Math.sin(angle - headAngle)
            )
            ctx.lineTo(
                end.x - headLength * Math.cos(angle + headAngle),
                end.y - headLength * Math.sin(angle + headAngle)
            )
            ctx.closePath()
            ctx.fill()
        }
    }

    // Mouse interaction
    MouseArea {
        anchors.fill: parent

        property point lastPos: Qt.point(0, 0)
        property vector3d dragStartPos: Qt.vector3d(0, 0, 0)

        onPressed: (mouse) => {
            lastPos = Qt.point(mouse.x, mouse.y)
            if (targetNode) {
                dragStartPos = targetNode.position
            }

            // Determine which axis was clicked (simple distance check)
            var center = worldToScreen(targetPosition)
            var dist = Math.sqrt(Math.pow(mouse.x - center.x, 2) + Math.pow(mouse.y - center.y, 2))

            if (dist < gizmoSize) {
                // Simple axis detection based on angle from center
                var angle = Math.atan2(mouse.y - center.y, mouse.x - center.x)
                // This is simplified - proper detection would check distance to each arrow
                activeAxis = 1 // For now, just activate X axis
                canvas.requestPaint()
            }
        }

        onPositionChanged: (mouse) => {
            if (!pressed || !targetNode || activeAxis === 0) return

            var delta = Qt.point(mouse.x - lastPos.x, mouse.y - lastPos.y)

            // Map screen space delta to 3D movement
            // This is a simplified version - proper implementation would project onto axis
            var currentWorldPos = screenToWorld(Qt.point(mouse.x, mouse.y))
            var lastWorldPos = screenToWorld(lastPos)

            var worldDelta = Qt.vector3d(
                currentWorldPos.x - lastWorldPos.x,
                currentWorldPos.y - lastWorldPos.y,
                currentWorldPos.z - lastWorldPos.z
            )

            // Apply movement based on active axis
            if (activeAxis === 1) {
                targetNode.position = Qt.vector3d(
                    targetNode.position.x + worldDelta.x,
                    targetNode.position.y,
                    targetNode.position.z
                )
            } else if (activeAxis === 2) {
                targetNode.position = Qt.vector3d(
                    targetNode.position.x,
                    targetNode.position.y + worldDelta.y,
                    targetNode.position.z
                )
            } else if (activeAxis === 3) {
                targetNode.position = Qt.vector3d(
                    targetNode.position.x,
                    targetNode.position.y,
                    targetNode.position.z + worldDelta.z
                )
            }

            lastPos = Qt.point(mouse.x, mouse.y)
            canvas.requestPaint()
        }

        onReleased: {
            activeAxis = 0
            canvas.requestPaint()
        }
    }

    // Repaint when target position changes
    Connections {
        target: targetNode
        function onPositionChanged() {
            canvas.requestPaint()
        }
    }

    // Repaint when view3d camera changes
    Connections {
        target: view3d ? view3d.camera : null
        function onPositionChanged() {
            canvas.requestPaint()
        }
        function onRotationChanged() {
            canvas.requestPaint()
        }
    }

    Component.onCompleted: {
        canvas.requestPaint()
    }
}

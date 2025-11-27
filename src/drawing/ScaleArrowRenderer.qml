// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes

/**
 * ScaleArrowRenderer - Arrow with square end for scale gizmo
 *
 * Renders an arrow from start to end point with a square handle at the end.
 * Uses Qt's scene graph for optimal performance.
 *
 * Usage:
 *   ScaleArrowRenderer {
 *       startPoint: Qt.point(100, 100)
 *       endPoint: Qt.point(200, 100)
 *       color: "red"
 *       lineWidth: 3
 *   }
 */
Item {
    id: root

    // Arrow geometry
    property point startPoint: Qt.point(0, 0)
    property point endPoint: Qt.point(0, 0)

    // Styling
    property color color: "#ff0000"
    property real lineWidth: 4
    property real squareSize: 12
    property int capStyle: ShapePath.RoundCap

    // Computed properties
    readonly property real angle: Math.atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
    readonly property point shaftEnd: Qt.point(
        endPoint.x - squareSize / 2.0 * Math.cos(angle),
        endPoint.y - squareSize / 2.0 * Math.sin(angle)
    )
    readonly property real halfSize: squareSize / 2

    // Combined shape (shaft + square handle) - single Shape for performance
    Shape {
        anchors.fill: parent
        antialiasing: true

        // Arrow shaft
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: root.capStyle

            startX: root.startPoint.x
            startY: root.startPoint.y

            PathLine {
                x: root.shaftEnd.x
                y: root.shaftEnd.y
            }
        }

        // Square handle at end
        ShapePath {
            strokeColor: root.color
            strokeWidth: 1
            fillColor: root.color

            startX: root.endPoint.x - root.halfSize
            startY: root.endPoint.y - root.halfSize

            PathLine { x: root.endPoint.x + root.halfSize; y: root.endPoint.y - root.halfSize }
            PathLine { x: root.endPoint.x + root.halfSize; y: root.endPoint.y + root.halfSize }
            PathLine { x: root.endPoint.x - root.halfSize; y: root.endPoint.y + root.halfSize }
            // Path implicitly closes back to startX/startY for fill
        }
    }
}

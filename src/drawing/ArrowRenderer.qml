// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes

/**
 * ArrowRenderer - Hardware-accelerated arrow rendering using QtQuick.Shapes
 *
 * Renders an arrow from start to end point with a triangular arrowhead.
 * Uses Qt's scene graph for optimal performance.
 *
 * Usage:
 *   ArrowRenderer {
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
    property real headLength: 15
    property real headAngle: Math.PI / 6
    property int capStyle: ShapePath.RoundCap
    property int joinStyle: ShapePath.RoundJoin

    // Computed properties
    readonly property real angle: Math.atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
    readonly property point shaftEnd: Qt.point(
        endPoint.x - headLength / 2.0 * Math.cos(angle),
        endPoint.y - headLength / 2.0 * Math.sin(angle)
    )
    readonly property point headLeft: Qt.point(
        endPoint.x - headLength * Math.cos(angle - headAngle),
        endPoint.y - headLength * Math.sin(angle - headAngle)
    )
    readonly property point headRight: Qt.point(
        endPoint.x - headLength * Math.cos(angle + headAngle),
        endPoint.y - headLength * Math.sin(angle + headAngle)
    )

    // Arrow shaft
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: root.capStyle
            joinStyle: root.joinStyle

            startX: root.startPoint.x
            startY: root.startPoint.y

            PathLine {
                x: root.shaftEnd.x
                y: root.shaftEnd.y
            }
        }
    }

    // Arrowhead (filled triangle)
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.color

            startX: root.endPoint.x
            startY: root.endPoint.y

            PathLine {
                x: root.headLeft.x
                y: root.headLeft.y
            }
            PathLine {
                x: root.headRight.x
                y: root.headRight.y
            }
            PathLine {
                x: root.endPoint.x
                y: root.endPoint.y
            }
        }
    }
}

// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes

/**
 * SquareHandleRenderer - Hardware-accelerated square handle rendering
 *
 * Renders a filled square centered at a point.
 * Uses Qt's scene graph for optimal performance.
 *
 * Usage:
 *   SquareHandleRenderer {
 *       center: Qt.point(100, 100)
 *       color: "yellow"
 *       size: 12
 *   }
 */
Item {
    id: root

    // Square geometry
    property point center: Qt.point(0, 0)

    // Styling
    property color color: "#ffff00"
    property real size: 12
    property int strokeWidth: 1

    // Computed properties
    readonly property real halfSize: size / 2

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.strokeWidth
            fillColor: root.color
            joinStyle: ShapePath.MiterJoin

            startX: root.center.x - root.halfSize
            startY: root.center.y - root.halfSize

            PathLine {
                x: root.center.x + root.halfSize
                y: root.center.y - root.halfSize
            }
            PathLine {
                x: root.center.x + root.halfSize
                y: root.center.y + root.halfSize
            }
            PathLine {
                x: root.center.x - root.halfSize
                y: root.center.y + root.halfSize
            }
            PathLine {
                x: root.center.x - root.halfSize
                y: root.center.y - root.halfSize
            }
        }
    }
}

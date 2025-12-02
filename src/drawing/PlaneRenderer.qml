// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes

/**
 * PlaneRenderer - Hardware-accelerated quad/plane rendering using QtQuick.Shapes
 *
 * Renders a filled quad with outline from 4 corner points.
 * Uses Qt's scene graph for optimal performance.
 *
 * Usage:
 *   PlaneRenderer {
 *       corners: [{x: 0, y: 0}, {x: 100, y: 0}, {x: 100, y: 100}, {x: 0, y: 100}]
 *       color: "yellow"
 *       active: false
 *   }
 */
Item {
    id: root

    // Quad geometry (array of exactly 4 corner points)
    property var corners: []

    // Styling
    property color color: "#ffff00"
    property bool active: false

    // Alpha and line width based on active state
    property real inactiveAlpha: 0.3
    property real activeAlpha: 0.5
    property int inactiveLineWidth: 2
    property int activeLineWidth: 3

    // Computed properties
    readonly property real currentAlpha: active ? activeAlpha : inactiveAlpha
    readonly property int currentLineWidth: active ? activeLineWidth : inactiveLineWidth
    readonly property bool hasValidCorners: corners && corners.length === 4

    // Filled quad
    Shape {
        anchors.fill: parent
        visible: root.hasValidCorners
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.currentLineWidth
            fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, root.currentAlpha)
            joinStyle: ShapePath.MiterJoin

            startX: root.hasValidCorners ? root.corners[0].x : 0
            startY: root.hasValidCorners ? root.corners[0].y : 0

            PathLine {
                x: root.hasValidCorners ? root.corners[1].x : 0
                y: root.hasValidCorners ? root.corners[1].y : 0
            }
            PathLine {
                x: root.hasValidCorners ? root.corners[2].x : 0
                y: root.hasValidCorners ? root.corners[2].y : 0
            }
            PathLine {
                x: root.hasValidCorners ? root.corners[3].x : 0
                y: root.hasValidCorners ? root.corners[3].y : 0
            }
            PathLine {
                x: root.hasValidCorners ? root.corners[0].x : 0
                y: root.hasValidCorners ? root.corners[0].y : 0
            }
        }
    }
}

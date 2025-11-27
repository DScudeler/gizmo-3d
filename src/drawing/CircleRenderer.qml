// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick
import QtQuick.Shapes

/**
 * CircleRenderer - Hardware-accelerated circle/arc rendering using QtQuick.Shapes
 *
 * Renders a polyline circle (supports perspective-projected ellipses),
 * optional partial arc, and optional filled wedge.
 * Uses Qt's scene graph for optimal performance.
 *
 * Usage:
 *   CircleRenderer {
 *       points: [...] // Array of {x, y} points
 *       center: Qt.point(100, 100)
 *       color: "red"
 *       lineWidth: 3
 *   }
 */
Item {
    id: root

    // Circle geometry (array of points forming polyline)
    property var points: []
    property point center: Qt.point(0, 0)

    // Styling
    property color color: "#ff0000"
    property real lineWidth: 2
    property real fillAlpha: 0.5
    property int capStyle: ShapePath.RoundCap
    property int joinStyle: ShapePath.RoundJoin

    // Arc rendering options
    property bool partialArc: false
    property real arcCenter: 0.0  // Center angle in radians
    property real arcRange: Math.PI  // Angular range in radians

    // Filled wedge options
    property bool filled: false
    property real arcStart: 0.0  // Start angle for fill in radians
    property real arcEnd: 0.0    // End angle for fill in radians

    // Internal: computed arc indices for partial arc rendering
    readonly property var arcIndices: {
        if (!points || points.length === 0) return { start: 0, end: 0 }

        var halfRange = arcRange / 2
        var startAngle = arcCenter - halfRange
        var endAngle = arcCenter + halfRange

        // Normalize angles to [0, 2π]
        while (startAngle < 0) startAngle += Math.PI * 2
        while (endAngle < 0) endAngle += Math.PI * 2
        while (startAngle >= Math.PI * 2) startAngle -= Math.PI * 2
        while (endAngle >= Math.PI * 2) endAngle -= Math.PI * 2

        var startIdx = Math.floor((startAngle / (Math.PI * 2)) * (points.length - 1))
        var endIdx = Math.floor((endAngle / (Math.PI * 2)) * (points.length - 1))

        return { start: startIdx, end: endIdx }
    }

    // Internal: computed indices for filled wedge
    readonly property var wedgeIndices: {
        if (!points || points.length === 0) return { start: 0, end: 0 }

        var normalizedStart = arcStart
        var normalizedEnd = arcEnd

        while (normalizedStart < 0) normalizedStart += Math.PI * 2
        while (normalizedEnd < 0) normalizedEnd += Math.PI * 2
        while (normalizedStart >= Math.PI * 2) normalizedStart -= Math.PI * 2
        while (normalizedEnd >= Math.PI * 2) normalizedEnd -= Math.PI * 2

        var startIdx = Math.floor((normalizedStart / (Math.PI * 2)) * (points.length - 1))
        var endIdx = Math.floor((normalizedEnd / (Math.PI * 2)) * (points.length - 1))

        return { start: startIdx, end: endIdx }
    }

    // Computed SVG path data for the polyline
    readonly property string polylinePath: {
        if (!points || points.length === 0) return ""

        var segments = []
        if (partialArc) {
            var startIdx = arcIndices.start
            var endIdx = arcIndices.end

            if (startIdx < points.length) {
                segments.push("M " + points[startIdx].x + " " + points[startIdx].y)

                if (endIdx < startIdx) {
                    // Wrap around
                    for (var i = startIdx + 1; i < points.length; i++) {
                        segments.push("L " + points[i].x + " " + points[i].y)
                    }
                    for (var j = 0; j <= endIdx; j++) {
                        segments.push("L " + points[j].x + " " + points[j].y)
                    }
                } else {
                    for (var k = startIdx + 1; k <= endIdx; k++) {
                        segments.push("L " + points[k].x + " " + points[k].y)
                    }
                }
            }
        } else {
            // Full circle
            if (points.length > 0) {
                segments.push("M " + points[0].x + " " + points[0].y)
                for (var m = 1; m < points.length; m++) {
                    segments.push("L " + points[m].x + " " + points[m].y)
                }
            }
        }

        return segments.join(" ")
    }

    // Computed path data for filled wedge
    readonly property string wedgePath: {
        if (!points || points.length === 0 || !filled) return ""

        var startIdx = wedgeIndices.start
        var endIdx = wedgeIndices.end

        var segments = ["M " + center.x + " " + center.y]

        if (startIdx < points.length) {
            segments.push("L " + points[startIdx].x + " " + points[startIdx].y)

            if (endIdx < startIdx) {
                // Wrap around
                for (var i = startIdx + 1; i < points.length; i++) {
                    segments.push("L " + points[i].x + " " + points[i].y)
                }
                for (var j = 0; j <= endIdx; j++) {
                    segments.push("L " + points[j].x + " " + points[j].y)
                }
            } else {
                for (var k = startIdx + 1; k <= endIdx; k++) {
                    segments.push("L " + points[k].x + " " + points[k].y)
                }
            }
        }

        segments.push("Z")  // Close path back to center
        return segments.join(" ")
    }

    // Filled wedge (rendered behind outline)
    Shape {
        anchors.fill: parent
        visible: root.filled && root.points.length > 0
        antialiasing: true

        ShapePath {
            strokeColor: "transparent"
            fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, root.fillAlpha)

            PathSvg {
                path: root.wedgePath
            }
        }
    }

    // Circle/arc outline
    Shape {
        anchors.fill: parent
        visible: root.points.length > 0
        antialiasing: true

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: root.capStyle
            joinStyle: root.joinStyle

            PathSvg {
                path: root.polylinePath
            }
        }
    }
}

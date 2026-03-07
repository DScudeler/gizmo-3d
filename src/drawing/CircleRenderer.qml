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
    property bool antialiasing: true

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

        var twoPi = Math.PI * 2
        startAngle = ((startAngle % twoPi) + twoPi) % twoPi
        endAngle = ((endAngle % twoPi) + twoPi) % twoPi

        var startIdx = Math.floor((startAngle / twoPi) * (points.length - 1))
        var endIdx = Math.floor((endAngle / twoPi) * (points.length - 1))

        return { start: startIdx, end: endIdx }
    }

    // Internal: computed indices for filled wedge
    readonly property var wedgeIndices: {
        if (!points || points.length === 0) return { start: 0, end: 0 }

        var twoPi = Math.PI * 2
        var normalizedStart = ((arcStart % twoPi) + twoPi) % twoPi
        var normalizedEnd = ((arcEnd % twoPi) + twoPi) % twoPi

        var startIdx = Math.floor((normalizedStart / twoPi) * (points.length - 1))
        var endIdx = Math.floor((normalizedEnd / twoPi) * (points.length - 1))

        return { start: startIdx, end: endIdx }
    }

    // Computed point list for the polyline outline
    readonly property var outlinePoints: {
        if (!points || points.length === 0) return []

        var result = []
        if (partialArc) {
            var startIdx = arcIndices.start
            var endIdx = arcIndices.end

            if (startIdx < points.length) {
                if (endIdx < startIdx) {
                    // Wrap around
                    for (var i = startIdx; i < points.length; i++) {
                        result.push(Qt.point(points[i].x, points[i].y))
                    }
                    for (var j = 0; j <= endIdx; j++) {
                        result.push(Qt.point(points[j].x, points[j].y))
                    }
                } else {
                    for (var k = startIdx; k <= endIdx; k++) {
                        result.push(Qt.point(points[k].x, points[k].y))
                    }
                }
            }
        } else {
            // Full circle
            for (var m = 0; m < points.length; m++) {
                result.push(Qt.point(points[m].x, points[m].y))
            }
        }

        return result
    }

    // Computed point list for filled wedge
    readonly property var wedgePoints: {
        if (!points || points.length === 0 || !filled) return []

        var startIdx = wedgeIndices.start
        var endIdx = wedgeIndices.end

        var result = [Qt.point(center.x, center.y)]

        if (startIdx < points.length) {
            if (endIdx < startIdx) {
                // Wrap around
                for (var i = startIdx; i < points.length; i++) {
                    result.push(Qt.point(points[i].x, points[i].y))
                }
                for (var j = 0; j <= endIdx; j++) {
                    result.push(Qt.point(points[j].x, points[j].y))
                }
            } else {
                for (var k = startIdx; k <= endIdx; k++) {
                    result.push(Qt.point(points[k].x, points[k].y))
                }
            }
        }

        // Close path back to center
        result.push(Qt.point(center.x, center.y))
        return result
    }

    // Filled wedge (rendered behind outline)
    Shape {
        anchors.fill: parent
        visible: root.filled && root.points.length > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, root.fillAlpha)

            PathPolyline {
                path: root.wedgePoints
            }
        }
    }

    // Circle/arc outline
    Shape {
        anchors.fill: parent
        visible: root.points.length > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: root.capStyle
            joinStyle: root.joinStyle

            PathPolyline {
                path: root.outlinePoints
            }
        }
    }
}

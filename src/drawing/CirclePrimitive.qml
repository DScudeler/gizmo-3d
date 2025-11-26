// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick

/**
 * CirclePrimitive - Reusable circle and arc drawing component
 *
 * Provides stateless drawing functions for rendering circles, arcs, and filled wedges
 * in Canvas 2D context. Operates in screen space (2D pixel coordinates).
 *
 * The circle is represented as an array of points (pre-computed polyline),
 * allowing support for arbitrary 3D circle projections (e.g., ellipses in perspective).
 *
 * Usage:
 *   CirclePrimitive {
 *       id: circle
 *       fillAlpha: 0.5
 *   }
 *
 *   Canvas {
 *       onPaint: {
 *           var ctx = getContext("2d")
 *           var points = [...] // Pre-computed circle points
 *           circle.drawCircle(ctx, points, "red", 3)
 *       }
 *   }
 */
QtObject {
    id: root

    /**
     * Alpha transparency for filled arc segments (pie slices)
     * Default: 0.5 (50% opacity, matches original RotationGizmo)
     */
    property real fillAlpha: 0.5

    /**
     * Line cap style for circle/arc outlines
     * Values: "butt", "round", "square"
     * Default: "round" (matches original)
     */
    property string lineCap: "round"

    /**
     * Line join style for circle/arc outlines
     * Values: "miter", "round", "bevel"
     * Default: "round" (matches original)
     */
    property string lineJoin: "round"

    /**
     * Draw a full circle outline as a polyline
     *
     * @param ctx - Canvas 2D context
     * @param points - Array of {x, y} points forming the circle (closed loop)
     * @param color - Circle color (string or Qt color)
     * @param lineWidth - Width of the circle outline in pixels
     */
    function drawCircle(ctx, points, color, lineWidth) {
        if (!points || points.length === 0) return

        ctx.strokeStyle = color
        ctx.lineWidth = lineWidth
        ctx.lineCap = root.lineCap
        ctx.lineJoin = root.lineJoin

        ctx.beginPath()
        ctx.moveTo(points[0].x, points[0].y)

        for (var i = 1; i < points.length; i++) {
            ctx.lineTo(points[i].x, points[i].y)
        }

        ctx.stroke()
    }

    /**
     * Draw a partial arc outline (subset of circle points)
     *
     * @param ctx - Canvas 2D context
     * @param points - Array of {x, y} points forming the circle
     * @param arcCenter - Center angle of the arc in radians [0, 2π]
     * @param arcRange - Angular range of the arc in radians
     * @param color - Arc color (string or Qt color)
     * @param lineWidth - Width of the arc outline in pixels
     */
    function drawArc(ctx, points, arcCenter, arcRange, color, lineWidth) {
        if (!points || points.length === 0) return

        ctx.strokeStyle = color
        ctx.lineWidth = lineWidth
        ctx.lineCap = root.lineCap
        ctx.lineJoin = root.lineJoin

        // Calculate arc range: arcCenter ± arcRange/2
        var halfRange = arcRange / 2
        var startAngle = arcCenter - halfRange
        var endAngle = arcCenter + halfRange

        // Normalize angles to [0, 2π]
        while (startAngle < 0) startAngle += Math.PI * 2
        while (endAngle < 0) endAngle += Math.PI * 2
        while (startAngle >= Math.PI * 2) startAngle -= Math.PI * 2
        while (endAngle >= Math.PI * 2) endAngle -= Math.PI * 2

        // Map angles to point indices
        var startIdx = Math.floor((startAngle / (Math.PI * 2)) * (points.length - 1))
        var endIdx = Math.floor((endAngle / (Math.PI * 2)) * (points.length - 1))

        ctx.beginPath()
        ctx.moveTo(points[startIdx].x, points[startIdx].y)

        if (endIdx < startIdx) {
            // Handle wrap-around: draw from startIdx to end of array, then from 0 to endIdx
            for (var i = startIdx; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y)
            }
            for (var j = 0; j <= endIdx; j++) {
                ctx.lineTo(points[j].x, points[j].y)
            }
        } else {
            // Normal case: draw from startIdx to endIdx
            for (var k = startIdx; k <= endIdx; k++) {
                ctx.lineTo(points[k].x, points[k].y)
            }
        }

        ctx.stroke()
    }

    /**
     * Draw a filled arc segment (pie slice/wedge from center to arc perimeter)
     *
     * @param ctx - Canvas 2D context
     * @param points - Array of {x, y} points forming the circle
     * @param center - Center point {x, y} of the wedge (typically circle center)
     * @param arcStart - Start angle of the arc in radians [0, 2π]
     * @param arcEnd - End angle of the arc in radians [0, 2π]
     * @param color - Fill color (string or Qt color)
     */
    function drawFilledWedge(ctx, points, center, arcStart, arcEnd, color) {
        if (!points || points.length === 0 || !center) return

        // Normalize angles to [0, 2π]
        var normalizedStart = arcStart
        var normalizedEnd = arcEnd

        while (normalizedStart < 0) normalizedStart += Math.PI * 2
        while (normalizedEnd < 0) normalizedEnd += Math.PI * 2
        while (normalizedStart >= Math.PI * 2) normalizedStart -= Math.PI * 2
        while (normalizedEnd >= Math.PI * 2) normalizedEnd -= Math.PI * 2

        // Map angles to point indices
        var startIdx = Math.floor((normalizedStart / (Math.PI * 2)) * (points.length - 1))
        var endIdx = Math.floor((normalizedEnd / (Math.PI * 2)) * (points.length - 1))

        // Set fill color with transparency
        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, root.fillAlpha)

        ctx.beginPath()

        // Start at center
        ctx.moveTo(center.x, center.y)

        // Line to start of arc
        ctx.lineTo(points[startIdx].x, points[startIdx].y)

        // Draw arc perimeter
        if (endIdx < startIdx) {
            // Handle wrap-around: draw from startIdx to end, then from 0 to endIdx
            for (var i = startIdx; i < points.length; i++) {
                ctx.lineTo(points[i].x, points[i].y)
            }
            for (var j = 0; j <= endIdx; j++) {
                ctx.lineTo(points[j].x, points[j].y)
            }
        } else {
            // Normal case: draw from startIdx to endIdx
            for (var k = startIdx; k <= endIdx; k++) {
                ctx.lineTo(points[k].x, points[k].y)
            }
        }

        // Close path (line back to center) and fill
        ctx.fill()
    }

    /**
     * Combined drawing function matching original RotationGizmo.drawCircle() signature
     * Draws circle outline and optionally a filled wedge
     *
     * @param ctx - Canvas 2D context
     * @param points - Array of {x, y} points forming the circle
     * @param center - Center point {x, y} (required for filled wedge)
     * @param color - Color (string or Qt color)
     * @param lineWidth - Width of the outline in pixels
     * @param filled - Whether to draw filled wedge (default: false)
     * @param arcStart - Start angle for filled wedge in radians
     * @param arcEnd - End angle for filled wedge in radians
     * @param geometryName - Unused (legacy parameter for compatibility)
     * @param partialArc - Whether to draw partial arc outline instead of full circle
     * @param arcCenter - Center angle for partial arc in radians
     * @param arcRange - Angular range for partial arc in radians
     */
    function draw(ctx, points, center, color, lineWidth, filled, arcStart, arcEnd, geometryName, partialArc, arcCenter, arcRange) {
        if (!points || points.length === 0) return

        // Draw filled arc segment if requested
        if (filled && arcStart !== undefined && arcEnd !== undefined && center) {
            drawFilledWedge(ctx, points, center, arcStart, arcEnd, color)
        }

        // Draw circle outline (full or partial)
        if (partialArc && arcCenter !== undefined && arcRange !== undefined) {
            drawArc(ctx, points, arcCenter, arcRange, color, lineWidth)
        } else {
            drawCircle(ctx, points, color, lineWidth)
        }
    }
}

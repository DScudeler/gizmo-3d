// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick

/**
 * ArrowPrimitive - Reusable arrow drawing component
 *
 * Provides stateless drawing functions for rendering arrows in Canvas 2D context.
 * Operates in screen space (2D pixel coordinates).
 *
 * Usage:
 *   ArrowPrimitive {
 *       id: arrow
 *       headLength: 20
 *       headAngle: Math.PI / 4
 *   }
 *
 *   Canvas {
 *       onPaint: {
 *           var ctx = getContext("2d")
 *           arrow.draw(ctx, start, end, "red", 3)
 *       }
 *   }
 */
QtObject {
    id: root

    /**
     * Length of the arrowhead in pixels
     * Default: 15 (matches original TranslationGizmo)
     */
    property real headLength: 15

    /**
     * Angle of the arrowhead in radians
     * Default: Math.PI / 6 (30 degrees, matches original)
     */
    property real headAngle: Math.PI / 6

    /**
     * Line cap style for the arrow shaft
     * Values: "butt", "round", "square"
     * Default: "round" (matches original)
     */
    property string lineCap: "round"

    /**
     * Draw an arrow from start to end point with triangular arrowhead
     *
     * @param ctx - Canvas 2D context
     * @param start - Start point {x, y} in screen coordinates
     * @param end - End point {x, y} in screen coordinates
     * @param color - Arrow color (string or Qt color)
     * @param lineWidth - Width of the arrow shaft in pixels
     */
    function draw(ctx, start, end, color, lineWidth) {
        ctx.strokeStyle = color
        ctx.fillStyle = color
        ctx.lineWidth = lineWidth
        ctx.lineCap = root.lineCap

        // Calculate angle from start to end
        var angle = Math.atan2(end.y - start.y, end.x - start.x)

        // Draw arrow shaft (line from start to near-end, accounting for arrowhead)
        ctx.beginPath()
        ctx.moveTo(start.x, start.y)
        ctx.lineTo(
            end.x - root.headLength / 2.0 * Math.cos(angle),
            end.y - root.headLength / 2.0 * Math.sin(angle)
        )
        ctx.stroke()

        // Draw triangular arrowhead at end point
        ctx.beginPath()
        ctx.moveTo(end.x, end.y)
        ctx.lineTo(
            end.x - root.headLength * Math.cos(angle - root.headAngle),
            end.y - root.headLength * Math.sin(angle - root.headAngle)
        )
        ctx.lineTo(
            end.x - root.headLength * Math.cos(angle + root.headAngle),
            end.y - root.headLength * Math.sin(angle + root.headAngle)
        )
        ctx.closePath()
        ctx.fill()
    }

    /**
     * Draw an arrow with a square handle at the endpoint instead of a triangular head
     * Used by ScaleGizmo for axis scale handles
     *
     * @param ctx - Canvas 2D context
     * @param start - Start point {x, y} in screen coordinates
     * @param end - End point {x, y} in screen coordinates
     * @param color - Arrow color (string or Qt color)
     * @param lineWidth - Width of the arrow shaft in pixels
     * @param squareSize - Size of the square handle in pixels (default: 12)
     */
    function drawWithSquare(ctx, start, end, color, lineWidth, squareSize) {
        if (squareSize === undefined) squareSize = 12

        ctx.strokeStyle = color
        ctx.fillStyle = color
        ctx.lineWidth = lineWidth
        ctx.lineCap = root.lineCap

        // Calculate angle from start to end
        var angle = Math.atan2(end.y - start.y, end.x - start.x)

        // Draw arrow shaft (line from start to near-end, accounting for square)
        ctx.beginPath()
        ctx.moveTo(start.x, start.y)
        ctx.lineTo(
            end.x - squareSize / 2.0 * Math.cos(angle),
            end.y - squareSize / 2.0 * Math.sin(angle)
        )
        ctx.stroke()

        // Draw square handle at endpoint
        var halfSize = squareSize / 2
        ctx.fillRect(
            end.x - halfSize,
            end.y - halfSize,
            squareSize,
            squareSize
        )
    }
}

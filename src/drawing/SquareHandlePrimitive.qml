// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick

/**
 * SquareHandlePrimitive - Reusable square handle drawing component
 *
 * Provides stateless drawing functions for rendering filled square handles
 * in Canvas 2D context. Operates in screen space (2D pixel coordinates).
 *
 * Usage:
 *   SquareHandlePrimitive {
 *       id: square
 *       defaultSize: 12
 *   }
 *
 *   Canvas {
 *       onPaint: {
 *           var ctx = getContext("2d")
 *           square.draw(ctx, center, "yellow")
 *       }
 *   }
 */
QtObject {
    id: root

    /**
     * Default size of square handle in pixels
     * Default: 12 (matches original ScaleGizmo)
     */
    property real defaultSize: 12

    /**
     * Line width for square outline
     * Default: 1 pixel (matches original)
     */
    property int lineWidth: 1

    /**
     * Draw a filled square handle centered at a point
     *
     * @param ctx - Canvas 2D context
     * @param center - Center point {x, y} in screen coordinates
     * @param color - Square color (string or Qt color)
     * @param customSize - Optional custom size in pixels (uses defaultSize if undefined)
     */
    function draw(ctx, center, color, customSize) {
        var size = (customSize !== undefined) ? customSize : root.defaultSize
        var halfSize = size / 2

        ctx.fillStyle = color
        ctx.strokeStyle = color
        ctx.lineWidth = root.lineWidth

        ctx.beginPath()
        ctx.rect(center.x - halfSize, center.y - halfSize, size, size)
        ctx.fill()
        ctx.stroke()
    }
}

// Copyright (C) 2025
// SPDX-License-Identifier: MIT

import QtQuick

/**
 * PlanePrimitive - Reusable quad/plane drawing component
 *
 * Provides stateless drawing functions for rendering filled quads with outlines
 * in Canvas 2D context. Operates in screen space (2D pixel coordinates).
 *
 * Usage:
 *   PlanePrimitive {
 *       id: plane
 *       activeAlpha: 0.5
 *       inactiveAlpha: 0.3
 *   }
 *
 *   Canvas {
 *       onPaint: {
 *           var ctx = getContext("2d")
 *           var corners = [{x, y}, {x, y}, {x, y}, {x, y}]
 *           plane.draw(ctx, corners, "blue", true)
 *       }
 *   }
 */
QtObject {
    id: root

    /**
     * Alpha transparency for inactive plane fill
     * Default: 0.3 (30% opacity, matches original TranslationGizmo)
     */
    property real inactiveAlpha: 0.3

    /**
     * Alpha transparency for active plane fill
     * Default: 0.5 (50% opacity, matches original TranslationGizmo)
     */
    property real activeAlpha: 0.5

    /**
     * Line width for inactive plane outline
     * Default: 2 pixels (matches original)
     */
    property int inactiveLineWidth: 2

    /**
     * Line width for active plane outline
     * Default: 3 pixels (matches original)
     */
    property int activeLineWidth: 3

    /**
     * Draw a filled quad/plane with outline
     *
     * @param ctx - Canvas 2D context
     * @param corners - Array of exactly 4 corner points {x, y} in screen coordinates
     * @param color - Plane color (string or Qt color)
     * @param active - Whether the plane is active (affects alpha and line width)
     */
    function draw(ctx, corners, color, active) {
        if (!corners || corners.length !== 4) return

        // Determine alpha and line width based on active state
        var alpha = active ? root.activeAlpha : root.inactiveAlpha
        var lineWidth = active ? root.activeLineWidth : root.inactiveLineWidth

        // Draw filled plane with transparency
        ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, alpha)
        ctx.beginPath()
        ctx.moveTo(corners[0].x, corners[0].y)
        for (var i = 1; i < 4; i++) {
            ctx.lineTo(corners[i].x, corners[i].y)
        }
        ctx.closePath()
        ctx.fill()

        // Draw outline
        ctx.strokeStyle = color
        ctx.lineWidth = lineWidth
        ctx.stroke()
    }
}

// GeometryTemplates.qml - Precomputed geometry templates for performance optimization
// Precomputes static shape geometry (unit circles, etc.) to avoid per-frame trig calculations

pragma Singleton
import QtQuick

QtObject {
    // Default segment count for circles (matches RotationGizmo's request, so the
    // precomputed unitCircle below is the one actually used at runtime — the cache hit)
    readonly property int defaultSegments: 48

    // Precomputed unit circle with cos/sin values for each segment
    // 49 points for 48 segments (includes closing point at angle 2π = 0)
    readonly property var unitCircle: _generateUnitCircle(defaultSegments)

    // Internal: generates unit circle template at initialization time
    function _generateUnitCircle(segments) {
        var points = []
        for (var i = 0; i <= segments; i++) {
            var angle = (i / segments) * Math.PI * 2
            points.push({
                cos: Math.cos(angle),
                sin: Math.sin(angle)
            })
        }
        return points
    }

    /**
     * Gets unit circle template, optionally generating custom segment count
     * @param segments - Number of segments (default: 48, returns the cached template)
     * @returns Array of {cos, sin} objects for each point
     */
    function getUnitCircle(segments) {
        if (segments === undefined || segments === defaultSegments) {
            return unitCircle
        }
        // Generate custom segment count (not cached, use sparingly)
        return _generateUnitCircle(segments)
    }
}

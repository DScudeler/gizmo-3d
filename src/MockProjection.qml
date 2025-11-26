// MockProjection.qml - Test implementation with deterministic projection
// Provides simple orthographic or perspective projection for unit testing

pragma Singleton
import QtQuick

QtObject {
    /**
     * Creates a mock projector with configurable behavior
     * @param config - Configuration object:
     *   {
     *     type: "orthographic" | "perspective" (default: orthographic)
     *     cameraPosition: vector3d (default: 0,0,10)
     *     cameraForward: vector3d (default: 0,0,-1)
     *     viewportSize: size (default: 800x600)
     *     fov: real (for perspective, default: 45 degrees)
     *     scale: real (for orthographic, default: 100 pixels per unit)
     *   }
     * @returns Projector object compatible with GizmoProjection interface
     */
    function createProjector(config) {
        config = config || {}

        var projType = config.type || "orthographic"
        var camPos = config.cameraPosition || Qt.vector3d(0, 0, 10)
        var camForward = config.cameraForward || Qt.vector3d(0, 0, -1)
        var viewportSize = config.viewportSize || Qt.size(800, 600)
        var fov = config.fov || 45
        var scale = config.scale || 100 // pixels per world unit

        return {
            type: projType,
            cameraPosition: camPos,
            cameraForward: camForward,
            viewportSize: viewportSize,
            fov: fov,
            scale: scale,

            projectWorldToScreen: function(worldPos) {
                if (this.type === "orthographic") {
                    return this._projectOrthographic(worldPos)
                } else {
                    return this._projectPerspective(worldPos)
                }
            },

            _projectOrthographic: function(worldPos) {
                // Simple orthographic projection along Z axis
                // X and Y map directly, scaled by the scale factor
                var centerX = this.viewportSize.width / 2
                var centerY = this.viewportSize.height / 2

                // Transform world coordinates relative to camera
                var relativePos = Qt.vector3d(
                    worldPos.x - this.cameraPosition.x,
                    worldPos.y - this.cameraPosition.y,
                    worldPos.z - this.cameraPosition.z
                )

                // Project to screen (Y is flipped in screen space)
                var screenX = centerX + relativePos.x * this.scale
                var screenY = centerY - relativePos.y * this.scale
                var depth = relativePos.z

                return Qt.vector3d(screenX, screenY, depth)
            },

            _projectPerspective: function(worldPos) {
                // Simple perspective projection
                var centerX = this.viewportSize.width / 2
                var centerY = this.viewportSize.height / 2

                // Transform world coordinates relative to camera
                var relativePos = Qt.vector3d(
                    worldPos.x - this.cameraPosition.x,
                    worldPos.y - this.cameraPosition.y,
                    worldPos.z - this.cameraPosition.z
                )

                // Perspective divide (project onto Z=1 plane)
                var depth = -relativePos.z // Negative Z is in front of camera
                if (depth < 0.1) depth = 0.1 // Avoid division by zero

                var fovScale = Math.tan(this.fov * Math.PI / 180 / 2)
                var screenX = centerX + (relativePos.x / depth) * centerX / fovScale
                var screenY = centerY - (relativePos.y / depth) * centerY / fovScale

                return Qt.vector3d(screenX, screenY, depth)
            },

            projectScreenToWorld: function(screenPos) {
                if (this.type === "orthographic") {
                    return this._unprojectOrthographic(screenPos)
                } else {
                    return this._unprojectPerspective(screenPos)
                }
            },

            _unprojectOrthographic: function(screenPos) {
                // Inverse of orthographic projection onto Z=0 plane
                var centerX = this.viewportSize.width / 2
                var centerY = this.viewportSize.height / 2

                var worldX = (screenPos.x - centerX) / this.scale + this.cameraPosition.x
                var worldY = -(screenPos.y - centerY) / this.scale + this.cameraPosition.y
                var worldZ = this.cameraPosition.z - 10 // Project onto plane 10 units in front

                return Qt.vector3d(worldX, worldY, worldZ)
            },

            _unprojectPerspective: function(screenPos) {
                // Inverse of perspective projection onto Z=-10 plane
                var centerX = this.viewportSize.width / 2
                var centerY = this.viewportSize.height / 2

                var depth = 10 // Distance to projection plane
                var fovScale = Math.tan(this.fov * Math.PI / 180 / 2)

                var worldX = (screenPos.x - centerX) * fovScale * depth / centerX + this.cameraPosition.x
                var worldY = -(screenPos.y - centerY) * fovScale * depth / centerY + this.cameraPosition.y
                var worldZ = this.cameraPosition.z - depth

                return Qt.vector3d(worldX, worldY, worldZ)
            },

            getCameraRay: function(screenPos) {
                var origin = this.cameraPosition
                var target = this.projectScreenToWorld(screenPos)

                var direction = Qt.vector3d(
                    target.x - origin.x,
                    target.y - origin.y,
                    target.z - origin.z
                )

                // Normalize
                var length = Math.sqrt(direction.x * direction.x +
                                      direction.y * direction.y +
                                      direction.z * direction.z)
                if (length > 0.0001) {
                    direction = Qt.vector3d(
                        direction.x / length,
                        direction.y / length,
                        direction.z / length
                    )
                }

                return {
                    origin: origin,
                    direction: direction
                }
            },

            getCameraPosition: function() {
                return this.cameraPosition
            },

            getCameraForward: function() {
                return this.cameraForward
            }
        }
    }
}

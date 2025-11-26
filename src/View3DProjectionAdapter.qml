// View3DProjectionAdapter.qml - Production implementation using Qt Quick 3D's View3D
// This adapter wraps View3D to provide projection services through the GizmoProjection interface

pragma Singleton
import QtQuick
import QtQuick3D

QtObject {
    /**
     * Creates a projector object that wraps a View3D instance
     * @param view3d - The View3D component to wrap
     * @returns Projector object compatible with GizmoProjection interface
     */
    function createProjector(view3d) {
        if (!view3d) {
            console.error("View3DProjectionAdapter: view3d is null")
            return null
        }

        if (!view3d.camera) {
            console.error("View3DProjectionAdapter: view3d.camera is null")
            return null
        }

        return {
            view3d: view3d,

            projectWorldToScreen: function(worldPos) {
                return this.view3d.mapFrom3DScene(worldPos)
            },

            projectScreenToWorld: function(screenPos) {
                return this.view3d.mapTo3DScene(Qt.point(screenPos.x, screenPos.y))
            },

            getCameraRay: function(screenPos) {
                // Get two points along the ray (near and far)
                var nearWorld = this.view3d.mapTo3DScene(Qt.point(screenPos.x, screenPos.y))

                // Use camera position as origin
                var cameraPos = this.view3d.camera.scenePosition

                // Calculate direction from camera to near point
                var direction = Qt.vector3d(
                    nearWorld.x - cameraPos.x,
                    nearWorld.y - cameraPos.y,
                    nearWorld.z - cameraPos.z
                )

                // Normalize direction
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
                    origin: cameraPos,
                    direction: direction
                }
            },

            getCameraPosition: function() {
                return this.view3d.camera.scenePosition
            },

            getCameraForward: function() {
                // Get camera's forward direction from its rotation
                // In Qt Quick 3D, forward is -Z in local space
                var rotation = this.view3d.camera.sceneRotation

                // Transform -Z vector by camera rotation
                var localForward = Qt.vector3d(0, 0, -1)

                // Convert quaternion to rotation (simple approach for forward vector)
                var x = rotation.x
                var y = rotation.y
                var z = rotation.z
                var w = rotation.scalar

                var forward = Qt.vector3d(
                    2 * (x * z + w * y),
                    2 * (y * z - w * x),
                    1 - 2 * (x * x + y * y)
                )

                // Normalize
                var length = Math.sqrt(forward.x * forward.x +
                                      forward.y * forward.y +
                                      forward.z * forward.z)
                if (length > 0.0001) {
                    forward = Qt.vector3d(
                        forward.x / length,
                        forward.y / length,
                        forward.z / length
                    )
                }

                return forward
            }
        }
    }
}

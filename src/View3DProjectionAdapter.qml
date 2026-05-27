// View3DProjectionAdapter.qml - Production implementation using Qt Quick 3D's View3D
// This adapter wraps View3D to provide projection services through the GizmoProjection interface

pragma Singleton
import QtQuick
import QtQuick3D

QtObject {
    property var _cachedProjector: null      // holds the JS projector object (not a View3D)
    property View3D _cachedView3d: null       // typed so the QtQuick3D import is used and checked

    /**
     * Creates a projector object that wraps a View3D instance.
     * The returned object's methods capture `view3d` by closure (not `this`), so they
     * remain valid however they are later invoked, and stay statically type-checkable.
     * @param view3d - The View3D component to wrap
     * @returns Projector object compatible with GizmoProjection interface
     */
    function createProjector(view3d: View3D): var {
        if (!view3d) {
            console.error("View3DProjectionAdapter: view3d is null")
            return null
        }

        if (!view3d.camera) {
            console.error("View3DProjectionAdapter: view3d.camera is null")
            return null
        }

        if (view3d === _cachedView3d && _cachedProjector && view3d.camera) {
            return _cachedProjector
        }

        var projector = {
            view3d: view3d,

            projectWorldToScreen: function(worldPos) {
                return view3d.mapFrom3DScene(worldPos)
            },

            projectScreenToWorld: function(screenPos) {
                return view3d.mapTo3DScene(Qt.point(screenPos.x, screenPos.y))
            },

            getCameraRay: function(screenPos) {
                // Get two points along the ray (near and far)
                var nearWorld = view3d.mapTo3DScene(Qt.point(screenPos.x, screenPos.y))

                // Use camera position as origin
                var cameraPos = view3d.camera.scenePosition

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
                return view3d.camera.scenePosition
            },

            getCameraForward: function() {
                // Get camera's forward direction from its rotation
                // In Qt Quick 3D, forward is -Z in local space
                var rotation = view3d.camera.sceneRotation

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

        _cachedView3d = view3d
        _cachedProjector = projector
        return projector
    }
}

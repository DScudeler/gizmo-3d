// GizmoProjection.qml - Abstract interface for coordinate projection
// This interface decouples gizmo geometry calculations from View3D,
// enabling testability with mock implementations.

pragma Singleton
import QtQuick

QtObject {
    // View state structure for projection operations
    // {
    //     cameraPosition: vector3d - Camera position in world space
    //     viewMatrix: matrix4x4 - View transformation matrix (optional)
    //     projectionMatrix: matrix4x4 - Projection matrix (optional)
    //     viewportSize: size - Viewport dimensions
    // }

    /**
     * Projects a 3D world position to 2D screen coordinates
     * @param worldPos - vector3d in world space
     * @param projector - Object implementing projectWorldToScreen(worldPos)
     * @returns vector3d with x,y as screen coordinates, z as depth
     */
    function projectWorldToScreen(worldPos, projector) {
        if (!projector || typeof projector.projectWorldToScreen !== 'function') {
            console.error("GizmoProjection: Invalid projector object")
            return Qt.vector3d(0, 0, 0)
        }
        return projector.projectWorldToScreen(worldPos)
    }

    /**
     * Projects a 2D screen position to 3D world coordinates on a plane
     * @param screenPos - point in screen space
     * @param projector - Object implementing projectScreenToWorld(screenPos)
     * @returns vector3d in world space
     */
    function projectScreenToWorld(screenPos, projector) {
        if (!projector || typeof projector.projectScreenToWorld !== 'function') {
            console.error("GizmoProjection: Invalid projector object")
            return Qt.vector3d(0, 0, 0)
        }
        return projector.projectScreenToWorld(screenPos)
    }

    /**
     * Constructs a ray from the camera through a screen position
     * @param screenPos - point in screen space
     * @param projector - Object implementing getCameraRay(screenPos)
     * @returns { origin: vector3d, direction: vector3d }
     */
    function getCameraRay(screenPos, projector) {
        if (!projector || typeof projector.getCameraRay !== 'function') {
            console.error("GizmoProjection: Invalid projector object")
            return { origin: Qt.vector3d(0, 0, 0), direction: Qt.vector3d(0, 0, 1) }
        }
        return projector.getCameraRay(screenPos)
    }

    /**
     * Gets the camera position in world space
     * @param projector - Object implementing getCameraPosition()
     * @returns vector3d camera position
     */
    function getCameraPosition(projector) {
        if (!projector || typeof projector.getCameraPosition !== 'function') {
            console.error("GizmoProjection: Invalid projector object")
            return Qt.vector3d(0, 0, 0)
        }
        return projector.getCameraPosition()
    }

    /**
     * Gets the camera forward direction in world space
     * @param projector - Object implementing getCameraForward()
     * @returns vector3d normalized forward direction
     */
    function getCameraForward(projector) {
        if (!projector || typeof projector.getCameraForward !== 'function') {
            console.error("GizmoProjection: Invalid projector object")
            return Qt.vector3d(0, 0, -1)
        }
        return projector.getCameraForward()
    }
}

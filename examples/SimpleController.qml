import QtQuick
import QtQuick3D
import Gizmo3D

/**
 * SimpleController - Bridges gizmo signals to target node manipulation
 *
 * This component demonstrates the recommended "Controller Pattern" for using
 * Gizmo3D transformation gizmos. It decouples the gizmo UI from scene manipulation
 * logic, enabling integration with external frameworks.
 *
 * Usage:
 *   SimpleController {
 *       gizmo: myTranslationGizmo
 *       targetNode: myCube
 *   }
 *
 * The controller:
 * - Stores initial state when manipulation starts
 * - Receives delta signals from gizmos
 * - Updates the target node, which triggers automatic gizmo redraws
 *
 * Supports TranslationGizmo, RotationGizmo, ScaleGizmo, and GlobalGizmo.
 */
Item {
    id: root

    // Required properties
    required property Item gizmo
    required property Node targetNode

    // Internal state for tracking drag operations
    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)
    property vector3d dragStartScale: Qt.vector3d(1, 1, 1)

    // Translation signal connections
    Connections {
        target: root.gizmo
        ignoreUnknownSignals: true

        function onAxisTranslationStarted(axis) {
            root.dragStartPos = root.targetNode.position
        }

        function onAxisTranslationDelta(axis, transformMode, delta, snapActive) {
            // Convert axis number to 3D direction based on transform mode
            var axisDirection
            if (transformMode === GizmoEnums.TransformMode.Local) {
                // Calculate local axes from target node's rotation
                var localAxes = GizmoMath.getLocalAxes(root.targetNode.rotation)
                axisDirection = axis === GizmoEnums.Axis.X ? localAxes.x
                             : axis === GizmoEnums.Axis.Y ? localAxes.y
                             : localAxes.z
            } else {
                // World mode: use global X/Y/Z axes
                axisDirection = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                             : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                             : Qt.vector3d(0, 0, 1)
            }

            // Apply translation along the axis direction
            var deltaVec = Qt.vector3d(
                axisDirection.x * delta,
                axisDirection.y * delta,
                axisDirection.z * delta
            )
            root.targetNode.position = Qt.vector3d(
                root.dragStartPos.x + deltaVec.x,
                root.dragStartPos.y + deltaVec.y,
                root.dragStartPos.z + deltaVec.z
            )
        }

        function onPlaneTranslationStarted(plane) {
            root.dragStartPos = root.targetNode.position
        }

        function onPlaneTranslationDelta(plane, transformMode, delta, snapActive) {
            // Delta is already in world space for all modes, just apply it
            root.targetNode.position = Qt.vector3d(
                root.dragStartPos.x + delta.x,
                root.dragStartPos.y + delta.y,
                root.dragStartPos.z + delta.z
            )
        }
    }

    // Rotation signal connections
    Connections {
        target: root.gizmo
        ignoreUnknownSignals: true

        function onRotationStarted(axis) {
            root.dragStartRot = root.targetNode.rotation
        }

        function onRotationDelta(axis, transformMode, angleDegrees, snapActive) {
            // Convert axis number to 3D direction based on transform mode
            var axisDirection
            if (transformMode === GizmoEnums.TransformMode.Local) {
                // Use local axes from DRAG START rotation, not current rotation
                // This ensures the axis remains consistent throughout the drag operation
                var localAxes = GizmoMath.getLocalAxes(root.dragStartRot)
                axisDirection = axis === GizmoEnums.Axis.X ? localAxes.x
                             : axis === GizmoEnums.Axis.Y ? localAxes.y
                             : localAxes.z
            } else {
                // World mode: use global X/Y/Z axes
                axisDirection = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                             : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                             : Qt.vector3d(0, 0, 1)
            }

            // Apply rotation around the axis direction
            let deltaQuat = GizmoMath.quaternionFromAxisAngle(axisDirection, angleDegrees)
            root.targetNode.rotation = deltaQuat.times(root.dragStartRot)
        }
    }

    // Scale signal connections
    Connections {
        target: root.gizmo
        ignoreUnknownSignals: true

        function onScaleStarted(axis) {
            root.dragStartScale = root.targetNode.scale
        }

        function onScaleDelta(axis, transformMode, scaleFactor, snapActive) {
            // Scale is axis-aligned regardless of transform mode
            if (axis === GizmoEnums.Axis.Uniform) {
                // Uniform scaling
                root.targetNode.scale = Qt.vector3d(
                    root.dragStartScale.x * scaleFactor,
                    root.dragStartScale.y * scaleFactor,
                    root.dragStartScale.z * scaleFactor
                )
            } else {
                // Axis-constrained scaling
                if (axis === GizmoEnums.Axis.X) {
                    root.targetNode.scale = Qt.vector3d(
                        root.dragStartScale.x * scaleFactor,
                        root.dragStartScale.y,
                        root.dragStartScale.z
                    )
                } else if (axis === GizmoEnums.Axis.Y) {
                    root.targetNode.scale = Qt.vector3d(
                        root.dragStartScale.x,
                        root.dragStartScale.y * scaleFactor,
                        root.dragStartScale.z
                    )
                } else if (axis === GizmoEnums.Axis.Z) {
                    root.targetNode.scale = Qt.vector3d(
                        root.dragStartScale.x,
                        root.dragStartScale.y,
                        root.dragStartScale.z * scaleFactor
                    )
                }
            }
        }
    }
}

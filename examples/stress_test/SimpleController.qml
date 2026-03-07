import QtQuick
import QtQuick3D
import Gizmo3D

Item {
    id: root

    required property Item gizmo
    required property Node targetNode

    property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
    property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)
    property vector3d dragStartScale: Qt.vector3d(1, 1, 1)

    Connections {
        target: root.gizmo
        ignoreUnknownSignals: true

        function onAxisTranslationStarted(axis) {
            root.dragStartPos = root.targetNode.position
        }

        function onAxisTranslationDelta(axis, transformMode, delta, snapActive) {
            var axisDirection
            if (transformMode === GizmoEnums.TransformMode.Local) {
                var localAxes = GizmoMath.getLocalAxes(root.targetNode.sceneRotation)
                axisDirection = axis === GizmoEnums.Axis.X ? localAxes.x
                             : axis === GizmoEnums.Axis.Y ? localAxes.y
                             : localAxes.z
            } else {
                axisDirection = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                             : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                             : Qt.vector3d(0, 0, 1)
            }
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
            var deltaVec
            if (transformMode === GizmoEnums.TransformMode.Local) {
                var localAxes = GizmoMath.getLocalAxes(root.targetNode.sceneRotation)
                deltaVec = Qt.vector3d(
                    localAxes.x.x * delta.x + localAxes.y.x * delta.y + localAxes.z.x * delta.z,
                    localAxes.x.y * delta.x + localAxes.y.y * delta.y + localAxes.z.y * delta.z,
                    localAxes.x.z * delta.x + localAxes.y.z * delta.y + localAxes.z.z * delta.z
                )
            } else {
                deltaVec = delta
            }
            root.targetNode.position = Qt.vector3d(
                root.dragStartPos.x + deltaVec.x,
                root.dragStartPos.y + deltaVec.y,
                root.dragStartPos.z + deltaVec.z
            )
        }
    }

    Connections {
        target: root.gizmo
        ignoreUnknownSignals: true

        function onRotationStarted(axis) {
            root.dragStartRot = root.targetNode.sceneRotation
        }

        function onRotationDelta(axis, transformMode, angleDegrees, snapActive) {
            var axisDirection
            if (transformMode === GizmoEnums.TransformMode.Local) {
                var localAxes = GizmoMath.getLocalAxes(root.dragStartRot)
                axisDirection = axis === GizmoEnums.Axis.X ? localAxes.x
                             : axis === GizmoEnums.Axis.Y ? localAxes.y
                             : localAxes.z
            } else {
                axisDirection = axis === GizmoEnums.Axis.X ? Qt.vector3d(1, 0, 0)
                             : axis === GizmoEnums.Axis.Y ? Qt.vector3d(0, 1, 0)
                             : Qt.vector3d(0, 0, 1)
            }
            let deltaQuat = GizmoMath.quaternionFromAxisAngle(axisDirection, angleDegrees)
            root.targetNode.rotation = deltaQuat.times(root.dragStartRot)
        }
    }

    Connections {
        target: root.gizmo
        ignoreUnknownSignals: true

        function onScaleStarted(axis) {
            root.dragStartScale = root.targetNode.scale
        }

        function onScaleDelta(axis, transformMode, scaleFactor, snapActive) {
            if (axis === GizmoEnums.Axis.Uniform) {
                root.targetNode.scale = Qt.vector3d(
                    root.dragStartScale.x * scaleFactor,
                    root.dragStartScale.y * scaleFactor,
                    root.dragStartScale.z * scaleFactor
                )
            } else if (axis === GizmoEnums.Axis.X) {
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

import QtQuick
import QtQuick3D
import Gizmo3D

/**
 * GlobalGizmo - Combined transformation gizmo with translation and rotation modes
 *
 * This component combines TranslationGizmo and RotationGizmo into a unified interface,
 * allowing mode switching between translation and rotation operations. It factors out
 * common properties and forwards signals from both child gizmos.
 *
 * Usage:
 *   GlobalGizmo {
 *       view3d: myView3D
 *       targetNode: myCube
 *       mode: "translate"  // or "rotate" or "both"
 *   }
 *
 * The GlobalGizmo:
 * - Manages two child gizmos (TranslationGizmo and RotationGizmo)
 * - Binds common properties (view3d, targetNode, snapEnabled, snapToAbsolute)
 * - Forwards all signals from both gizmos for controller integration
 * - Provides mode control to switch between translation and rotation
 */
Item {
    id: root

    // Common properties factorized from both gizmos
    property View3D view3d: null
    property Node targetNode: null
    property bool snapEnabled: false
    property bool snapToAbsolute: true

    // Transform mode: GizmoEnums.TransformMode.World or GizmoEnums.TransformMode.Local
    property int transformMode: GizmoEnums.TransformMode.World

    // Gizmo-specific size properties
    property real gizmoSize: 80.0

    // Translation-specific snap property
    property real snapIncrement: 1.0

    // Rotation-specific snap property
    property real snapAngle: 15.0

    // Scale-specific snap property
    property real scaleSnapIncrement: 0.1

    // Mode control: "translate", "rotate", "scale", or "all"
    property string mode: "translate"

    // Forward activeAxis from active gizmo
    readonly property int activeAxis: {
        if (mode === "translate") return translationGizmo.activeAxis
        if (mode === "rotate") return rotationGizmo.activeAxis
        if (mode === "scale") return scaleGizmo.activeAxis
        // For "all" mode, return first non-None activeAxis
        if (scaleGizmo.activeAxis !== GizmoEnums.Axis.None) return scaleGizmo.activeAxis
        if (translationGizmo.activeAxis !== GizmoEnums.Axis.None) return translationGizmo.activeAxis
        if (rotationGizmo.activeAxis !== GizmoEnums.Axis.None) return rotationGizmo.activeAxis
        return GizmoEnums.Axis.None
    }
    readonly property int activePlane: translationGizmo.activePlane

    readonly property bool isActive: {
        return translationGizmo.isActive || rotationGizmo.isActive || scaleGizmo.isActive
    }

    // Translation signals (forwarded from TranslationGizmo)
    signal axisTranslationStarted(int axis)
    signal axisTranslationDelta(int axis, int transformMode, real delta, bool snapActive)
    signal axisTranslationEnded(int axis)
    signal planeTranslationStarted(int plane)
    signal planeTranslationDelta(int plane, int transformMode, vector3d delta, bool snapActive)
    signal planeTranslationEnded(int plane)

    // Rotation signals (forwarded from RotationGizmo)
    signal rotationStarted(int axis)
    signal rotationDelta(int axis, int transformMode, real angleDegrees, bool snapActive)
    signal rotationEnded(int axis)

    // Scale signals (forwarded from ScaleGizmo)
    signal scaleStarted(int axis)
    signal scaleDelta(int axis, int transformMode, real scaleFactor, bool snapActive)
    signal scaleEnded(int axis)

    // Computed property: are we in composite mode with multiple gizmos sharing arrow space?
    readonly property bool isCompositeMode: mode === "all"

    // Coordinating FrameAnimation - updates all visible child gizmos with ONE shared projector
    FrameAnimation {
        id: coordinatorAnimation
        running: root.visible && root.view3d && root.targetNode

        onTriggered: {
            // Update geometry every frame - no dirty check to avoid sync issues
            // between QML property updates and View3D internal state
            var projector = View3DProjectionAdapter.createProjector(root.view3d)
            if (!projector) return

            // Update all visible child gizmos with shared projector
            if (scaleGizmo.visible) {
                scaleGizmo.updateGeometry(projector)
            }
            if (translationGizmo.visible) {
                translationGizmo.updateGeometry(projector)
            }
            if (rotationGizmo.visible) {
                rotationGizmo.updateGeometry(projector)
            }
        }
    }

    // ScaleGizmo child
    ScaleGizmo {
        id: scaleGizmo
        anchors.fill: parent
        visible: root.mode === "scale" || root.mode === "all"
        z: root.mode === "all" ? 0 : 0

        // Parent manages geometry updates via coordinating FrameAnimation
        managedByParent: true

        // Bind common properties
        view3d: root.view3d
        targetNode: root.targetNode
        snapEnabled: root.snapEnabled
        snapToAbsolute: root.snapToAbsolute
        transformMode: root.transformMode

        // Bind scale-specific properties
        gizmoSize: root.gizmoSize
        snapIncrement: root.scaleSnapIncrement

        // Set arrow ratios for composite mode
        arrowStartRatio: 0.0
        arrowEndRatio: root.isCompositeMode ? 0.5 : 1.0
    }

    // TranslationGizmo child
    TranslationGizmo {
        id: translationGizmo
        anchors.fill: parent
        visible: root.mode === "translate" || root.mode === "both" || root.mode === "all"
        z: root.mode === "both" || root.mode === "all" ? 0 : 0

        // Parent manages geometry updates via coordinating FrameAnimation
        managedByParent: true

        // Bind common properties
        view3d: root.view3d
        targetNode: root.targetNode
        snapEnabled: root.snapEnabled
        snapToAbsolute: root.snapToAbsolute
        transformMode: root.transformMode

        // Bind translation-specific properties
        gizmoSize: root.gizmoSize * 1.3
        snapIncrement: root.snapIncrement

        // Set arrow ratios for composite mode
        arrowStartRatio: root.isCompositeMode ? 0.5 : 0.0
        arrowEndRatio: 1.0
    }

    // RotationGizmo child
    RotationGizmo {
        id: rotationGizmo
        anchors.fill: parent
        visible: root.mode === "rotate" || root.mode === "both" || root.mode === "all"
        z: root.mode === "both" || root.mode === "all" ? 1 : 0  // Rotation on top when multiple visible

        // Parent manages geometry updates via coordinating FrameAnimation
        managedByParent: true

        // Bind common properties
        view3d: root.view3d
        targetNode: root.targetNode
        snapEnabled: root.snapEnabled
        snapToAbsolute: root.snapToAbsolute
        transformMode: root.transformMode

        // Bind rotation-specific properties
        gizmoSize: root.gizmoSize
        snapAngle: root.snapAngle
    }

    // Forward translation signals
    Connections {
        target: translationGizmo

        function onAxisTranslationStarted(axis) {
            root.axisTranslationStarted(axis)
        }

        function onAxisTranslationDelta(axis, transformMode, delta, snapActive) {
            root.axisTranslationDelta(axis, transformMode, delta, snapActive)
        }

        function onAxisTranslationEnded(axis) {
            root.axisTranslationEnded(axis)
        }

        function onPlaneTranslationStarted(plane) {
            root.planeTranslationStarted(plane)
        }

        function onPlaneTranslationDelta(plane, transformMode, delta, snapActive) {
            root.planeTranslationDelta(plane, transformMode, delta, snapActive)
        }

        function onPlaneTranslationEnded(plane) {
            root.planeTranslationEnded(plane)
        }
    }

    // Forward rotation signals
    Connections {
        target: rotationGizmo

        function onRotationStarted(axis) {
            root.rotationStarted(axis)
        }

        function onRotationDelta(axis, transformMode, angleDegrees, snapActive) {
            root.rotationDelta(axis, transformMode, angleDegrees, snapActive)
        }

        function onRotationEnded(axis) {
            root.rotationEnded(axis)
        }
    }

    // Forward scale signals
    Connections {
        target: scaleGizmo

        function onScaleStarted(axis) {
            root.scaleStarted(axis)
        }

        function onScaleDelta(axis, transformMode, scaleFactor, snapActive) {
            root.scaleDelta(axis, transformMode, scaleFactor, snapActive)
        }

        function onScaleEnded(axis) {
            root.scaleEnded(axis)
        }
    }
}

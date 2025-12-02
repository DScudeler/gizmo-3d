import QtQuick
import QtQuick3D
import Gizmo3D

Item {
    id: root

    // Signals for manipulation commands
    signal rotationStarted(int axis)
    signal rotationDelta(int axis, int transformMode, real angleDegrees, bool snapActive)
    signal rotationEnded(int axis)

    // Required properties
    property View3D view3d: null
    property Node targetNode: null
    property real gizmoSize: 80.0
    property real maxScreenRadius: 100.0  // Maximum screen-space radius in pixels
    property real inactiveArcRange: 80.0  // Visible arc range in degrees when inactive (±40°)

    // Transform mode: GizmoEnums.TransformMode.World or GizmoEnums.TransformMode.Local
    property int transformMode: GizmoEnums.TransformMode.World

    // State tracking
    property int activeAxis: GizmoEnums.Axis.None  // YZ plane (X-rotation), ZX plane (Y-rotation), XY plane (Z-rotation)
    property vector3d targetPosition: targetNode ? targetNode.scenePosition : Qt.vector3d(0, 0, 0)
    property bool isActive: activeAxis !== GizmoEnums.Axis.None

    // Computed local/world axes based on transform mode
    readonly property var currentAxes: {
        if (transformMode === GizmoEnums.TransformMode.Local && targetNode) {
            return GizmoMath.getLocalAxes(targetNode.sceneRotation)
        } else {
            return {
                x: Qt.vector3d(1, 0, 0),
                y: Qt.vector3d(0, 1, 0),
                z: Qt.vector3d(0, 0, 1)
            }
        }
    }

    // Snap configuration
    property bool snapEnabled: false
    property real snapAngle: 15.0  // Snap increment in degrees
    property bool snapToAbsolute: true  // true=snap to world angles, false=snap relative to drag start

    // Rotation tracking
    property real dragStartAngle: 0.0
    property real currentAngle: 0.0
    property var dragStartAxes: null  // Axes at drag start for stable wedge rendering

    // Color properties with highlighting
    readonly property color xAxisColor: activeAxis === GizmoEnums.Axis.X ? "#ff6666" : "#ff0000"
    readonly property color yAxisColor: activeAxis === GizmoEnums.Axis.Y ? "#66ff66" : "#00ff00"
    readonly property color zAxisColor: activeAxis === GizmoEnums.Axis.Z ? "#6666ff" : "#0000ff"

    anchors.fill: parent

    // Performance optimization: drag state and caching
    property bool isDragging: false
    property var cachedProjector: null
    property var lastHitTestGeometry: null

    // External control flag - when true, parent manages geometry updates via FrameAnimation
    property bool managedByParent: false

    // Geometry property - updated by FrameAnimation or parent coordinator
    property var geometry: null

    // Camera-facing angles for partial arc rendering - updated by FrameAnimation
    property real yzFacingAngle: 0
    property real zxFacingAngle: 0
    property real xyFacingAngle: 0

    // Previous frame radii for temporal smoothing to eliminate jitter
    property var _previousRadii: null

    visible: targetNode !== null && view3d !== null

    // Internal FrameAnimation for standalone operation (disabled when managed by parent)
    FrameAnimation {
        id: internalAnimation
        running: !root.managedByParent && root.visible && root.view3d && root.targetNode

        onTriggered: {
            // Update geometry every frame - no dirty check to avoid sync issues
            // between QML property updates and View3D internal state
            var projector = View3DProjectionAdapter.createProjector(root.view3d)
            if (projector) {
                root.updateGeometry(projector)
            }
        }
    }

    /**
     * Updates geometry and facing angles using the provided projector.
     * Called by parent coordinator (GlobalGizmo) or internal FrameAnimation.
     * Uses ONE shared projector for all calculations (was 4 projectors before).
     * @param projector - Shared projector object from View3DProjectionAdapter
     */
    function updateGeometry(projector) {
        if (!view3d || !view3d.camera || !targetNode) {
            geometry = null
            return
        }

        // Use drag start axes during active rotation for stable wedge rendering
        var axesToUse = (activeAxis !== GizmoEnums.Axis.None && dragStartAxes) ? dragStartAxes : currentAxes

        // Calculate main geometry with temporal smoothing
        var newGeometry = RotationGeometryCalculator.calculateCircleGeometry({
            projector: projector,
            targetPosition: targetNode.scenePosition,
            axes: axesToUse,
            gizmoSize: gizmoSize,
            maxScreenRadius: maxScreenRadius,
            segments: 64,
            previousRadii: _previousRadii,
            smoothingFactor: 0.3
        })

        geometry = newGeometry
        // Save radii for next frame smoothing
        if (newGeometry && newGeometry.radii) {
            _previousRadii = newGeometry.radii
        }

        // Calculate all 3 facing angles with the SAME projector (was 3 separate projectors)
        yzFacingAngle = RotationGeometryCalculator.calculateCameraFacingAngle(
            targetNode.scenePosition, currentAxes.x, currentAxes.y, projector
        )
        zxFacingAngle = RotationGeometryCalculator.calculateCameraFacingAngle(
            targetNode.scenePosition, currentAxes.y, currentAxes.z, projector
        )
        xyFacingAngle = RotationGeometryCalculator.calculateCameraFacingAngle(
            targetNode.scenePosition, currentAxes.z, currentAxes.x, projector
        )
    }

    // Helper for hit testing - needs fresh geometry calculation
    function calculateCircleGeometry() {
        if (!view3d || !view3d.camera || !targetNode) return null
        var projector = View3DProjectionAdapter.createProjector(view3d)
        if (!projector) return null
        var axesToUse = (activeAxis !== GizmoEnums.Axis.None && dragStartAxes) ? dragStartAxes : currentAxes
        return RotationGeometryCalculator.calculateCircleGeometry({
            projector: projector,
            targetPosition: targetNode.scenePosition,
            axes: axesToUse,
            gizmoSize: gizmoSize,
            maxScreenRadius: maxScreenRadius,
            segments: 64
        })
    }

    // ========================================
    // Helper Functions
    // ========================================

    // Calculate the angle on a rotation plane that faces the camera (uses geometry calculator)
    function calculateCameraFacingAngle(planeNormal, referenceAxis) {
        if (!view3d || !view3d.camera || !targetNode) return 0
        var projector = View3DProjectionAdapter.createProjector(view3d)
        if (!projector) return 0
        return RotationGeometryCalculator.calculateCameraFacingAngle(
            targetNode.scenePosition, planeNormal, referenceAxis, projector
        )
    }

    // ========================================
    // Rendering Layer - QtQuick.Shapes based
    // ========================================

    Item {
        id: renderLayer
        anchors.fill: parent

        property real arcRangeRadians: root.inactiveArcRange * (Math.PI / 180)

        // YZ plane (X-axis rotation) - Red
        CircleRenderer {
            anchors.fill: parent
            points: root.geometry ? root.geometry.circles.yz : []
            center: root.geometry ? root.geometry.center : Qt.point(0, 0)
            color: root.xAxisColor
            lineWidth: root.activeAxis === GizmoEnums.Axis.X ? 4 : 2

            // Full circle with fill when active, partial arc when inactive
            partialArc: root.activeAxis !== GizmoEnums.Axis.X
            arcCenter: root.yzFacingAngle
            arcRange: renderLayer.arcRangeRadians

            filled: root.activeAxis === GizmoEnums.Axis.X
            arcStart: root.dragStartAngle
            arcEnd: root.currentAngle
        }

        // ZX plane (Y-axis rotation) - Green
        CircleRenderer {
            anchors.fill: parent
            points: root.geometry ? root.geometry.circles.zx : []
            center: root.geometry ? root.geometry.center : Qt.point(0, 0)
            color: root.yAxisColor
            lineWidth: root.activeAxis === GizmoEnums.Axis.Y ? 4 : 2

            partialArc: root.activeAxis !== GizmoEnums.Axis.Y
            arcCenter: root.zxFacingAngle
            arcRange: renderLayer.arcRangeRadians

            filled: root.activeAxis === GizmoEnums.Axis.Y
            arcStart: root.dragStartAngle
            arcEnd: root.currentAngle
        }

        // XY plane (Z-axis rotation) - Blue
        CircleRenderer {
            anchors.fill: parent
            points: root.geometry ? root.geometry.circles.xy : []
            center: root.geometry ? root.geometry.center : Qt.point(0, 0)
            color: root.zAxisColor
            lineWidth: root.activeAxis === GizmoEnums.Axis.Z ? 4 : 2

            partialArc: root.activeAxis !== GizmoEnums.Axis.Z
            arcCenter: root.xyFacingAngle
            arcRange: renderLayer.arcRangeRadians

            filled: root.activeAxis === GizmoEnums.Axis.Z
            arcStart: root.dragStartAngle
            arcEnd: root.currentAngle
        }
    }

    // ========================================
    // Geometric Hit Detection
    // ========================================

    // Helper function to check if a hit point is within the visible arc range
    function isHitWithinArcRange(mouseX, mouseY, planeNormal, referenceAxis) {
        // Get ray from mouse position
        var ray = GizmoMath.getCameraRay(view3d, Qt.point(mouseX, mouseY))

        // Intersect ray with rotation plane
        var intersection = GizmoMath.intersectRayPlane(ray.origin, ray.direction, targetPosition, planeNormal)

        if (!intersection) return false

        // Calculate angle of hit point relative to reference axis
        var hitAngle = GizmoMath.calculatePlaneAngle(intersection, targetPosition, planeNormal, referenceAxis)

        // Calculate camera-facing angle for this plane
        var facingAngle = calculateCameraFacingAngle(planeNormal, referenceAxis)

        // Calculate angular difference (normalized to [-π, π])
        var angleDiff = GizmoMath.normalizeAngleDelta(hitAngle - facingAngle)

        // Check if within ±(inactiveArcRange/2) degrees
        var halfRangeRadians = (inactiveArcRange / 2) * (Math.PI / 180)

        return Math.abs(angleDiff) <= halfRangeRadians
    }

    // Geometric hit detection using circle geometry
    // Caches geometry to avoid recalculating on press
    function getHitAxis(x, y) {
        lastHitTestGeometry = calculateCircleGeometry()
        if (!lastHitTestGeometry) {
            return GizmoEnums.Axis.None
        }
        var geom = lastHitTestGeometry

        var mousePos = Qt.point(x, y)
        var hitThreshold = 8  // pixels (half of old lineWidth=15, tuned for accuracy)

        // Test each circle - use currentAxes for local mode support
        var axes = currentAxes
        var circleTests = [
            {axis: GizmoEnums.Axis.X, points: geom.circles.yz, planeNormal: axes.x, refAxis: axes.y},  // X-rotation (YZ plane)
            {axis: GizmoEnums.Axis.Y, points: geom.circles.zx, planeNormal: axes.y, refAxis: axes.z},  // Y-rotation (ZX plane)
            {axis: GizmoEnums.Axis.Z, points: geom.circles.xy, planeNormal: axes.z, refAxis: axes.x}   // Z-rotation (XY plane)
        ]

        var closestAxis = GizmoEnums.Axis.None
        var closestDistance = Infinity

        for (var i = 0; i < circleTests.length; i++) {
            var test = circleTests[i]
            var distance = GizmoMath.distanceToPolyline2D(mousePos, test.points)

            if (distance <= hitThreshold && distance < closestDistance) {
                // Check if hit is within visible arc range when inactive
                if (activeAxis === GizmoEnums.Axis.None) {  // Currently inactive
                    if (isHitWithinArcRange(x, y, test.planeNormal, test.refAxis)) {
                        closestDistance = distance
                        closestAxis = test.axis
                    }
                } else if (activeAxis === test.axis) {
                    // Active circle: full circle is hittable
                    closestDistance = distance
                    closestAxis = test.axis
                }
            }
        }

        return closestAxis
    }

    // ========================================
    // Mouse Interaction
    // ========================================

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: root.activeAxis !== GizmoEnums.Axis.None

        property quaternion dragStartRotation: Qt.quaternion(1, 0, 0, 0)
        property vector3d dragPlaneNormal: Qt.vector3d(0, 0, 0)
        property vector3d dragReferenceAxis: Qt.vector3d(0, 0, 0)

        onPressed: (mouse) => {
            if (root.targetNode) {
                dragStartRotation = root.targetNode.rotation
            }

            // Pixel-perfect hit detection
            root.activeAxis = root.getHitAxis(mouse.x, mouse.y)

            if (root.activeAxis !== GizmoEnums.Axis.None) {
                // Start drag - cache projector
                root.isDragging = true
                root.cachedProjector = View3DProjectionAdapter.createProjector(root.view3d)

                // Store axes at drag start for stable circle geometry during drag
                root.dragStartAxes = root.currentAxes

                // Determine plane normal and reference axis based on which circle was hit
                // Use current axes for local mode
                var axes = root.currentAxes
                if (root.activeAxis === GizmoEnums.Axis.X) {  // YZ plane (X-axis rotation)
                    dragPlaneNormal = axes.x
                    dragReferenceAxis = axes.y
                } else if (root.activeAxis === GizmoEnums.Axis.Y) {  // ZX plane (Y-axis rotation)
                    dragPlaneNormal = axes.y
                    dragReferenceAxis = axes.z  // Aligns with cos(0) in circle generation
                } else if (root.activeAxis === GizmoEnums.Axis.Z) {  // XY plane (Z-axis rotation)
                    dragPlaneNormal = axes.z
                    dragReferenceAxis = axes.x
                }

                // Calculate initial angle
                var ray = GizmoMath.getCameraRay(root.view3d, Qt.point(mouse.x, mouse.y))
                var intersection = GizmoMath.intersectRayPlane(ray.origin, ray.direction, root.targetPosition, dragPlaneNormal)

                if (intersection) {
                    root.dragStartAngle = GizmoMath.calculatePlaneAngle(intersection, root.targetPosition, dragPlaneNormal, dragReferenceAxis)
                    root.currentAngle = root.dragStartAngle
                }

                // Emit started signal
                root.rotationStarted(root.activeAxis)

                mouse.accepted = true
                preventStealing = true
            } else {
                mouse.accepted = false
            }
        }

        onPositionChanged: (mouse) => {
            if (!pressed || !root.targetNode || root.activeAxis === GizmoEnums.Axis.None) {
                return
            }

            mouse.accepted = true

            // Get current mouse position in 3D
            var ray = GizmoMath.getCameraRay(root.view3d, Qt.point(mouse.x, mouse.y))
            var intersection = GizmoMath.intersectRayPlane(ray.origin, ray.direction, root.targetPosition, dragPlaneNormal)

            if (!intersection) {
                console.warn("RotationGizmo: Ray-plane intersection failed (ray parallel to plane)")
                return
            }

            // Calculate current angle
            root.currentAngle = GizmoMath.calculatePlaneAngle(intersection, root.targetPosition, dragPlaneNormal, dragReferenceAxis)

            // Calculate rotation delta
            var deltaAngle = GizmoMath.normalizeAngleDelta(root.currentAngle - root.dragStartAngle)
            var deltaDegrees = deltaAngle * (180 / Math.PI)

            // Apply snap if enabled
            var snappedDeltaDegrees = deltaDegrees
            if (root.snapEnabled) {
                if (root.snapToAbsolute) {
                    // Snap to world angles: snap the absolute angle, then compute delta
                    var dragStartDegrees = root.dragStartAngle * (180 / Math.PI)
                    var currentAbsoluteDegrees = dragStartDegrees + deltaDegrees
                    var snappedAbsoluteDegrees = GizmoMath.snapValueAbsolute(currentAbsoluteDegrees, root.snapAngle)
                    snappedDeltaDegrees = snappedAbsoluteDegrees - dragStartDegrees
                } else {
                    // Snap relative to drag start (existing behavior)
                    snappedDeltaDegrees = GizmoMath.snapValue(deltaDegrees, root.snapAngle)
                }
            }

            // Update currentAngle for visual feedback to reflect snapped rotation
            if (root.snapEnabled) {
                root.currentAngle = root.dragStartAngle + (snappedDeltaDegrees * (Math.PI / 180))
            }

            // Emit delta signal with transform mode
            root.rotationDelta(root.activeAxis, root.transformMode, snappedDeltaDegrees, root.snapEnabled)
            // Note: updateGeometry() removed - geometry is cached at drag start,
            // visual feedback (wedge fill) is driven by currentAngle property binding
        }

        onReleased: (mouse) => {
            if (root.activeAxis !== GizmoEnums.Axis.None) {
                // Emit ended signal
                root.rotationEnded(root.activeAxis)
                mouse.accepted = true
            } else {
                mouse.accepted = false
            }
            root.activeAxis = GizmoEnums.Axis.None
            root.dragStartAngle = 0.0
            root.currentAngle = 0.0
            root.dragStartAxes = null  // Clear stored axes
            preventStealing = false

            // End drag - clear cached projector
            root.isDragging = false
            root.cachedProjector = null
        }
    }

    // Legacy API compatibility - no-op since geometry is now reactive
    function repaintGizmo() {
        // Geometry updates automatically via property bindings
    }
}

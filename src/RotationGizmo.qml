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
    property vector3d targetPosition: targetNode ? targetNode.position : Qt.vector3d(0, 0, 0)
    property bool isActive: activeAxis !== GizmoEnums.Axis.None

    // Computed local/world axes based on transform mode
    readonly property var currentAxes: {
        if (transformMode === GizmoEnums.TransformMode.Local && targetNode) {
            return GizmoMath.getLocalAxes(targetNode.rotation)
        } else {
            return {
                x: Qt.vector3d(1, 0, 0),
                y: Qt.vector3d(0, 1, 0),
                z: Qt.vector3d(0, 0, 1)
            }
        }
    }

    // Handle targetNode changes to trigger repaint (binding handles position updates)
    onTargetNodeChanged: {
        repaintGizmo()
    }

    // Handle transform mode changes to trigger repaint (world/local switch)
    onTransformModeChanged: {
        repaintGizmo()
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

    // When false, internal canvas is hidden (for shared canvas in GlobalGizmo)
    property bool useInternalCanvas: true


    // ========================================
    // Circle Geometry Calculation
    // ========================================

    // Calculate the angle on a rotation plane that faces the camera (uses geometry calculator)
    function calculateCameraFacingAngle(planeNormal, referenceAxis) {
        if (!view3d || !view3d.camera) return 0

        var projector = View3DProjectionAdapter.createProjector(view3d)
        if (!projector) return 0

        return RotationGeometryCalculator.calculateCameraFacingAngle(
            targetPosition, planeNormal, referenceAxis, projector
        )
    }

    function calculateCircleGeometry() {
        if (!view3d || !view3d.camera || !targetNode) return null

        var projector = View3DProjectionAdapter.createProjector(view3d)
        if (!projector) return null

        // Use drag start axes during active rotation for stable wedge rendering
        // This ensures the filled wedge origin stays fixed at the click position
        var axesToUse = (activeAxis !== GizmoEnums.Axis.None && dragStartAxes) ? dragStartAxes : currentAxes

        return RotationGeometryCalculator.calculateCircleGeometry({
            projector: projector,
            targetPosition: targetPosition,
            axes: axesToUse,
            gizmoSize: gizmoSize,
            maxScreenRadius: maxScreenRadius,
            segments: 64
        })
    }


    // ========================================
    // Drawing Primitives
    // ========================================

    CirclePrimitive {
        id: circlePrimitive
        fillAlpha: 0.5
        lineCap: "round"
        lineJoin: "round"
    }

    // Draw gizmo to an external context (for shared canvas in GlobalGizmo)
    function drawToContext(ctx) {
        var geometry = calculateCircleGeometry()
        if (!geometry) return

        // Enable anti-aliasing for smooth appearance
        ctx.antialias = true
        ctx.imageSmoothingEnabled = true

        // Calculate camera-facing angles for each plane (used for partial arc rendering when inactive)
        // Use currentAxes to support local mode - angles must match circle geometry
        var axes = currentAxes
        var yzFacingAngle = calculateCameraFacingAngle(axes.x, axes.y)  // YZ plane, Y reference
        var zxFacingAngle = calculateCameraFacingAngle(axes.y, axes.z)  // ZX plane, Z reference
        var xyFacingAngle = calculateCameraFacingAngle(axes.z, axes.x)  // XY plane, X reference

        var arcRangeRadians = inactiveArcRange * (Math.PI / 180)

        // Draw circles with active arc highlighting
        // YZ plane (X-axis rotation) - Red
        if (activeAxis === GizmoEnums.Axis.X) {
            // Active: full circle with filled rotation arc
            circlePrimitive.draw(ctx, geometry.circles.yz, geometry.center, xAxisColor, 4, true,
                      dragStartAngle, currentAngle, "YZ-plane(X-RED-ACTIVE)", false)
        } else {
            // Inactive: partial arc facing camera
            circlePrimitive.draw(ctx, geometry.circles.yz, geometry.center, "#ff0000", 2, false,
                      undefined, undefined, "YZ-plane(X-RED-inactive)", true, yzFacingAngle, arcRangeRadians)
        }

        // ZX plane (Y-axis rotation) - Green
        if (activeAxis === GizmoEnums.Axis.Y) {
            // Active: full circle with filled rotation arc
            circlePrimitive.draw(ctx, geometry.circles.zx, geometry.center, yAxisColor, 4, true,
                      dragStartAngle, currentAngle, "ZX-plane(Y-GREEN-ACTIVE)", false)
        } else {
            // Inactive: partial arc facing camera
            circlePrimitive.draw(ctx, geometry.circles.zx, geometry.center, "#00ff00", 2, false,
                      undefined, undefined, "ZX-plane(Y-GREEN-inactive)", true, zxFacingAngle, arcRangeRadians)
        }

        // XY plane (Z-axis rotation) - Blue
        if (activeAxis === GizmoEnums.Axis.Z) {
            // Active: full circle with filled rotation arc
            circlePrimitive.draw(ctx, geometry.circles.xy, geometry.center, zAxisColor, 4, true,
                      dragStartAngle, currentAngle, "XY-plane(Z-BLUE-ACTIVE)", false)
        } else {
            // Inactive: partial arc facing camera
            circlePrimitive.draw(ctx, geometry.circles.xy, geometry.center, "#0000ff", 2, false,
                      undefined, undefined, "XY-plane(Z-BLUE-inactive)", true, xyFacingAngle, arcRangeRadians)
        }
    }

    // ========================================
    // Visible Canvas (only used in standalone mode)
    // ========================================

    Canvas {
        id: canvas
        anchors.fill: parent
        visible: root.useInternalCanvas
        renderStrategy: Canvas.Threaded
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d", { alpha: true })
            ctx.reset()
            ctx.clearRect(0, 0, width, height)
            root.drawToContext(ctx)
        }
    }

    // ========================================
    // Hit-Test Canvas (Hidden)
    // ========================================

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
    function getHitAxis(x, y) {
        var geometry = calculateCircleGeometry()
        if (!geometry) {
            return GizmoEnums.Axis.None
        }

        var mousePos = Qt.point(x, y)
        var hitThreshold = 8  // pixels (half of old lineWidth=15, tuned for accuracy)

        // Test each circle - use currentAxes for local mode support
        var axes = root.currentAxes
        var circleTests = [
            {axis: GizmoEnums.Axis.X, points: geometry.circles.yz, planeNormal: axes.x, refAxis: axes.y},  // X-rotation (YZ plane)
            {axis: GizmoEnums.Axis.Y, points: geometry.circles.zx, planeNormal: axes.y, refAxis: axes.z},  // Y-rotation (ZX plane)
            {axis: GizmoEnums.Axis.Z, points: geometry.circles.xy, planeNormal: axes.z, refAxis: axes.x}   // Z-rotation (XY plane)
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
                root.repaintGizmo()
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
            root.repaintGizmo()
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
            root.repaintGizmo()
        }
    }

    // ========================================
    // Repaint Trigger Function
    // ========================================

    function repaintGizmo() {
        if (useInternalCanvas) {
            canvas.requestPaint()
        }
    }

    // Property bindings for repaint triggers (declarative approach)
    onTargetPositionChanged: repaintGizmo()
    onCurrentAxesChanged: repaintGizmo()

    // Repaint when view3d camera changes (only when using internal canvas)
    Connections {
        target: root.view3d && root.useInternalCanvas ? root.view3d.camera : null
        function onPositionChanged() {
            root.repaintGizmo()
        }
        function onRotationChanged() {
            root.repaintGizmo()
        }
    }

    Component.onCompleted: {
        repaintGizmo()
    }
}

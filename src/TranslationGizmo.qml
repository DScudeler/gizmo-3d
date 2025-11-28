import QtQuick
import QtQuick3D
import Gizmo3D

Item {
    id: root

    // Signals for manipulation commands
    signal axisTranslationStarted(int axis)
    signal axisTranslationDelta(int axis, int transformMode, real delta, bool snapActive)
    signal axisTranslationEnded(int axis)

    signal planeTranslationStarted(int plane)
    signal planeTranslationDelta(int plane, int transformMode, vector3d delta, bool snapActive)
    signal planeTranslationEnded(int plane)

    // Properties
    property View3D view3d: null
    property Node targetNode: null
    property real gizmoSize: 100.0
    property real maxScreenSize: 150.0  // Maximum screen-space extent in pixels
    property vector3d targetPosition: targetNode ? targetNode.position : Qt.vector3d(0, 0, 0)
    property real lineWidth: 4

    // Transform mode: GizmoEnums.TransformMode.World or GizmoEnums.TransformMode.Local
    property int transformMode: GizmoEnums.TransformMode.World

    // Arrow rendering ratios (0.0 to 1.0) - controls which portion of the arrow to draw
    property real arrowStartRatio: 0.0  // Start from center by default
    property real arrowEndRatio: 1.0    // End at full length by default

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

    // Active handles: axis or plane
    property int activeAxis: GizmoEnums.Axis.None
    property int activePlane: GizmoEnums.Plane.None

    property bool isActive: activeAxis !== GizmoEnums.Axis.None || activePlane !== GizmoEnums.Plane.None

    // Snap properties
    property bool snapEnabled: false
    property real snapIncrement: 1.0
    property bool snapToAbsolute: true  // true=snap to world grid, false=snap relative to drag start

    // Colors for each axis
    readonly property color xAxisColor: activeAxis === GizmoEnums.Axis.X ? "#ff6666" : "#ff0000"
    readonly property color yAxisColor: activeAxis === GizmoEnums.Axis.Y ? "#66ff66" : "#00ff00"
    readonly property color zAxisColor: activeAxis === GizmoEnums.Axis.Z ? "#6666ff" : "#0000ff"

    // Colors for each plane
    readonly property color xyPlaneColor: activePlane === GizmoEnums.Plane.XY ? "#ffff99" : "#ffff00"
    readonly property color xzPlaneColor: activePlane === GizmoEnums.Plane.XZ ? "#ff99ff" : "#ff00ff"
    readonly property color yzPlaneColor: activePlane === GizmoEnums.Plane.YZ ? "#99ffff" : "#00ffff"

    // When false, internal canvas is hidden (for shared canvas in GlobalGizmo)
    property bool useInternalCanvas: true

    anchors.fill: parent

    // Helper function to calculate arrow geometry and plane handles (uses new geometry calculator)
    function calculateGizmoGeometry() {
        if (!view3d || !view3d.camera || !targetNode) return null

        // Create projector on-demand
        var projector = View3DProjectionAdapter.createProjector(view3d)
        if (!projector) return null

        return TranslationGeometryCalculator.calculateArrowGeometry({
            projector: projector,
            targetPosition: targetPosition,
            axes: currentAxes,
            gizmoSize: gizmoSize,
            maxScreenSize: maxScreenSize,
            arrowStartRatio: arrowStartRatio,
            arrowEndRatio: arrowEndRatio
        })
    }

    // Snap planar movement to grid (uses geometry calculator)
    function snapPlaneMovement(delta, plane, startPos) {
        return TranslationGeometryCalculator.snapPlaneMovement(
            delta, plane, startPos, snapIncrement, snapToAbsolute
        )
    }

    // Drawing primitives
    ArrowPrimitive {
        id: arrowPrimitive
        headLength: 15
        headAngle: Math.PI / 6
        lineCap: "round"
    }

    PlanePrimitive {
        id: planePrimitive
        inactiveAlpha: 0.3
        activeAlpha: 0.5
        inactiveLineWidth: 2
        activeLineWidth: 3
    }

    // Draw gizmo to an external context (for shared canvas in GlobalGizmo)
    function drawToContext(ctx) {
        var geometry = calculateGizmoGeometry()
        if (!geometry) return

        // Draw planes first (so arrows are on top)
        // XY plane (yellow)
        if (geometry.planes.xy.length === 4) {
            planePrimitive.draw(ctx, geometry.planes.xy, xyPlaneColor, activePlane === GizmoEnums.Plane.XY)
        }

        // XZ plane (magenta)
        if (geometry.planes.xz.length === 4) {
            planePrimitive.draw(ctx, geometry.planes.xz, xzPlaneColor, activePlane === GizmoEnums.Plane.XZ)
        }

        // YZ plane (cyan)
        if (geometry.planes.yz.length === 4) {
            planePrimitive.draw(ctx, geometry.planes.yz, yzPlaneColor, activePlane === GizmoEnums.Plane.YZ)
        }

        // Draw X axis (red)
        arrowPrimitive.draw(ctx, geometry.xStart, geometry.xEnd, xAxisColor, lineWidth)

        // Draw Y axis (green)
        arrowPrimitive.draw(ctx, geometry.yStart, geometry.yEnd, yAxisColor, lineWidth)

        // Draw Z axis (blue)
        arrowPrimitive.draw(ctx, geometry.zStart, geometry.zEnd, zAxisColor, lineWidth)
    }

    // Visible canvas for rendering (only used in standalone mode)
    Canvas {
        id: canvas
        anchors.fill: parent
        visible: root.useInternalCanvas
        renderStrategy: Canvas.Threaded
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d", { alpha: true })
            ctx.clearRect(0, 0, width, height)
            root.drawToContext(ctx)
        }
    }

    // Geometric hit detection using screen-space geometry (uses HitTester)
    function getHitRegion(x, y) {
        var geometry = calculateGizmoGeometry()
        return HitTester.testTranslationGizmoHit(Qt.point(x, y), geometry, 10)
    }

    // Mouse interaction
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: root.activeAxis !== GizmoEnums.Axis.None || root.activePlane !== GizmoEnums.Plane.None

        property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
        property real initialT: 0.0  // Initial projection parameter for axis drag
        property vector3d dragPlaneNormal: Qt.vector3d(0, 0, 0)  // Plane normal for planar drag
        property vector3d dragStartIntersection: Qt.vector3d(0, 0, 0)  // Initial plane intersection point

        onPressed: (mouse) => {
            if (root.targetNode) {
                dragStartPos = root.targetNode.position
            }

            // Pixel-perfect hit detection using color picking
            var hitInfo = root.getHitRegion(mouse.x, mouse.y)

            if (hitInfo.type === "axis") {
                root.activeAxis = hitInfo.axis
                root.activePlane = GizmoEnums.Plane.None

                // Calculate initial projection offset for axis dragging
                var ray = GizmoMath.getCameraRay(root.view3d, Qt.point(mouse.x, mouse.y))
                var axes = root.currentAxes
                var axisDir = Qt.vector3d(0, 0, 0)
                if (root.activeAxis === GizmoEnums.Axis.X) {
                    axisDir = axes.x
                } else if (root.activeAxis === GizmoEnums.Axis.Y) {
                    axisDir = axes.y
                } else if (root.activeAxis === GizmoEnums.Axis.Z) {
                    axisDir = axes.z
                }
                initialT = -GizmoMath.closestPointOnAxisToRay(ray.origin, ray.direction, dragStartPos, axisDir)

                // Emit started signal
                root.axisTranslationStarted(root.activeAxis)

                mouse.accepted = true
                preventStealing = true
                root.repaintGizmo()
            } else if (hitInfo.type === "plane") {
                root.activeAxis = GizmoEnums.Axis.None
                root.activePlane = hitInfo.plane

                // Store plane normal for ray intersection (use current axes for local mode)
                var axes2 = root.currentAxes
                if (root.activePlane === GizmoEnums.Plane.XY) {  // XY plane (normal is Z)
                    dragPlaneNormal = axes2.z
                } else if (root.activePlane === GizmoEnums.Plane.XZ) {  // XZ plane (normal is Y)
                    dragPlaneNormal = axes2.y
                } else if (root.activePlane === GizmoEnums.Plane.YZ) {  // YZ plane (normal is X)
                    dragPlaneNormal = axes2.x
                }

                // Calculate and store initial intersection point
                var initialRay = GizmoMath.getCameraRay(root.view3d, Qt.point(mouse.x, mouse.y))
                var initialIntersection = GizmoMath.intersectRayPlane(initialRay.origin, initialRay.direction, dragStartPos, dragPlaneNormal)
                if (initialIntersection) {
                    dragStartIntersection = initialIntersection
                }

                // Emit started signal
                root.planeTranslationStarted(root.activePlane)

                mouse.accepted = true
                preventStealing = true
                root.repaintGizmo()
            } else {
                // No hit - allow camera control
                root.activeAxis = GizmoEnums.Axis.None
                root.activePlane = GizmoEnums.Plane.None
                mouse.accepted = false
            }
        }

        onPositionChanged: (mouse) => {
            if (!pressed || !root.targetNode || (root.activeAxis === GizmoEnums.Axis.None && root.activePlane === GizmoEnums.Plane.None)) {
                return
            }

            mouse.accepted = true

            if (root.activePlane !== GizmoEnums.Plane.None) {
                // Plane drag logic
                var ray = GizmoMath.getCameraRay(root.view3d, Qt.point(mouse.x, mouse.y))
                var intersection = GizmoMath.intersectRayPlane(ray.origin, ray.direction, dragStartPos, dragPlaneNormal)

                if (intersection) {
                    // Calculate delta from initial intersection to current intersection
                    var delta = GizmoMath.vectorSubtract(intersection, dragStartIntersection)

                    // Apply snap to both components
                    if (root.snapEnabled) {
                        delta = root.snapPlaneMovement(delta, root.activePlane, dragStartPos)
                    }

                    // Emit delta signal with transform mode
                    root.planeTranslationDelta(root.activePlane, root.transformMode, delta, root.snapEnabled)
                }
            } else if (root.activeAxis !== GizmoEnums.Axis.None) {
                // Axis drag logic
                var ray2 = GizmoMath.getCameraRay(root.view3d, Qt.point(mouse.x, mouse.y))

                // Determine axis direction based on active axis (use current axes for local mode)
                var axes3 = root.currentAxes
                var axisDir = Qt.vector3d(0, 0, 0)
                if (root.activeAxis === GizmoEnums.Axis.X) {
                    axisDir = axes3.x
                } else if (root.activeAxis === GizmoEnums.Axis.Y) {
                    axisDir = axes3.y
                } else if (root.activeAxis === GizmoEnums.Axis.Z) {
                    axisDir = axes3.z
                }

                // Calculate closest point on the axis to the ray
                var t = -GizmoMath.closestPointOnAxisToRay(ray2.origin, ray2.direction, dragStartPos, axisDir)

                // Calculate displacement relative to initial click position
                var rawDeltaT = t - initialT
                var deltaT = rawDeltaT

                // Apply snapping if enabled
                if (root.snapEnabled) {
                    if (root.snapToAbsolute) {
                        // Snap to world grid: snap the absolute position, then compute delta
                        var axisIndex = root.activeAxis - 1  // 0=X, 1=Y, 2=Z
                        var currentAbsolute = dragStartPos[["x", "y", "z"][axisIndex]] + rawDeltaT
                        var snappedAbsolute = GizmoMath.snapValueAbsolute(currentAbsolute, root.snapIncrement)
                        deltaT = snappedAbsolute - dragStartPos[["x", "y", "z"][axisIndex]]
                    } else {
                        // Snap relative to drag start (existing behavior)
                        deltaT = GizmoMath.snapValue(rawDeltaT, root.snapIncrement)
                    }
                }

                // Emit delta signal with transform mode
                root.axisTranslationDelta(root.activeAxis, root.transformMode, deltaT, root.snapEnabled)
            }

            root.repaintGizmo()
        }

        onReleased: (mouse) => {
            if (root.activeAxis !== GizmoEnums.Axis.None || root.activePlane !== GizmoEnums.Plane.None) {
                // Emit ended signal
                if (root.activeAxis !== GizmoEnums.Axis.None) {
                    root.axisTranslationEnded(root.activeAxis)
                } else if (root.activePlane !== GizmoEnums.Plane.None) {
                    root.planeTranslationEnded(root.activePlane)
                }
                mouse.accepted = true
            } else {
                mouse.accepted = false
            }
            root.activeAxis = GizmoEnums.Axis.None
            root.activePlane = GizmoEnums.Plane.None
            preventStealing = false
            root.repaintGizmo()
        }
    }

    // Helper function to repaint canvas
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

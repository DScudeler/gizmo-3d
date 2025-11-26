import QtQuick
import QtQuick3D
import Gizmo3D

Item {
    id: root

    // Signals for manipulation commands
    signal scaleStarted(int axis)
    signal scaleDelta(int axis, int transformMode, real scaleFactor, bool snapActive)
    signal scaleEnded(int axis)

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

    // Handle targetNode changes to trigger repaint
    onTargetNodeChanged: {
        repaintGizmo()
    }

    // Handle transform mode changes to trigger repaint (world/local switch)
    onTransformModeChanged: {
        repaintGizmo()
    }

    // Active axis
    property int activeAxis: GizmoEnums.Axis.None
    property bool isActive: activeAxis !== GizmoEnums.Axis.None

    // Snap properties
    property bool snapEnabled: false
    property real snapIncrement: 0.1  // Scale snap increment (0.1 = 10% steps)
    property bool snapToAbsolute: true

    // Colors for each axis
    readonly property color xAxisColor: activeAxis === GizmoEnums.Axis.X ? "#ff6666" : "#ff0000"
    readonly property color yAxisColor: activeAxis === GizmoEnums.Axis.Y ? "#66ff66" : "#00ff00"
    readonly property color zAxisColor: activeAxis === GizmoEnums.Axis.Z ? "#6666ff" : "#0000ff"
    readonly property color uniformColor: activeAxis === GizmoEnums.Axis.Uniform ? "#ffff66" : "#ffff00"

    anchors.fill: parent

    // Helper function to calculate arrow geometry (uses geometry calculator)
    function calculateGizmoGeometry() {
        if (!view3d || !view3d.camera || !targetNode) return null

        var projector = View3DProjectionAdapter.createProjector(view3d)
        if (!projector) return null

        return ScaleGeometryCalculator.calculateHandleGeometry({
            projector: projector,
            targetPosition: targetPosition,
            axes: currentAxes,
            gizmoSize: gizmoSize,
            maxScreenSize: maxScreenSize,
            arrowStartRatio: arrowStartRatio,
            arrowEndRatio: arrowEndRatio
        })
    }

    // Drawing primitives
    ArrowPrimitive {
        id: arrowPrimitive
        lineCap: "round"
    }

    SquareHandlePrimitive {
        id: squareHandlePrimitive
        defaultSize: 12
        lineWidth: 1
    }

    // Visible canvas for rendering
    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Threaded
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var geometry = root.calculateGizmoGeometry()
            if (!geometry) return

            var ctx = getContext("2d", { alpha: true })
            ctx.clearRect(0, 0, width, height)

            // Draw uniform scale handle at center
            squareHandlePrimitive.draw(ctx, geometry.center, root.uniformColor, 8)

            // Draw X axis (red) with square end
            arrowPrimitive.drawWithSquare(ctx, geometry.xStart, geometry.xEnd, root.xAxisColor, root.lineWidth, 12)

            // Draw Y axis (green) with square end
            arrowPrimitive.drawWithSquare(ctx, geometry.yStart, geometry.yEnd, root.yAxisColor, root.lineWidth, 12)

            // Draw Z axis (blue) with square end
            arrowPrimitive.drawWithSquare(ctx, geometry.zStart, geometry.zEnd, root.zAxisColor, root.lineWidth, 12)
        }
    }

    // Geometric hit detection (uses HitTester)
    function getHitRegion(x, y) {
        var geometry = calculateGizmoGeometry()
        var result = HitTester.testScaleGizmoHit(Qt.point(x, y), geometry, 10, 12)

        // Convert result format to match expected API
        if (result.type === "center") {
            return {type: "uniform"}
        }
        return result
    }

    // Mouse interaction
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: root.activeAxis !== GizmoEnums.Axis.None

        property vector3d dragStartScale: Qt.vector3d(1, 1, 1)
        property real dragStartDistance: 0.0  // Initial distance for scaling calculation
        property vector3d dragStartPos: Qt.vector3d(0, 0, 0)
        property point dragStartScreenPos: Qt.point(0, 0)  // Screen position at drag start
        property point screenAxisDir: Qt.point(0, 0)  // Screen-space axis direction (normalized)
        property real arrowScreenLength: 0  // Visual arrow length in screen space
        property vector3d worldAxisDir: Qt.vector3d(0, 0, 0)  // 3D world axis direction for local mode

        onPressed: (mouse) => {
            if (root.targetNode) {
                dragStartScale = root.targetNode.scale
                dragStartPos = root.targetNode.position
            }

            var hitInfo = root.getHitRegion(mouse.x, mouse.y)

            if (hitInfo.type === "axis") {
                root.activeAxis = hitInfo.axis

                // Calculate screen-space parameters for axis-constrained scaling
                dragStartScreenPos = Qt.point(mouse.x, mouse.y)

                // Use current axes for local mode
                var axes = root.currentAxes
                var axisDir = Qt.vector3d(0, 0, 0)
                if (root.activeAxis === GizmoEnums.Axis.X) {
                    axisDir = axes.x
                } else if (root.activeAxis === GizmoEnums.Axis.Y) {
                    axisDir = axes.y
                } else if (root.activeAxis === GizmoEnums.Axis.Z) {
                    axisDir = axes.z
                }

                // Store world axis direction for signal emission
                worldAxisDir = axisDir

                // Calculate screen-space axis direction and arrow length
                var centerScreen = GizmoMath.worldToScreen(root.view3d, dragStartPos)
                var axisEndWorld = GizmoMath.vectorAdd(dragStartPos, axisDir)
                var axisEndScreen = GizmoMath.worldToScreen(root.view3d, axisEndWorld)

                // Calculate and normalize screen-space axis direction
                var screenDirX = axisEndScreen.x - centerScreen.x
                var screenDirY = axisEndScreen.y - centerScreen.y
                var screenDirLength = Math.sqrt(screenDirX * screenDirX + screenDirY * screenDirY)

                if (screenDirLength > 0) {
                    screenAxisDir = Qt.point(screenDirX / screenDirLength, screenDirY / screenDirLength)
                    arrowScreenLength = screenDirLength * root.gizmoSize * root.arrowEndRatio
                } else {
                    screenAxisDir = Qt.point(1, 0)
                    arrowScreenLength = root.gizmoSize
                }

                root.scaleStarted(root.activeAxis)

                mouse.accepted = true
                preventStealing = true
                root.repaintGizmo()
            } else if (hitInfo.type === "uniform") {
                root.activeAxis = GizmoEnums.Axis.Uniform  // Uniform scaling

                // For uniform scaling, use distance from camera to target
                if (root.view3d && root.view3d.camera) {
                    var cameraPos = root.view3d.camera.scenePosition
                    dragStartDistance = Math.sqrt(
                        Math.pow(cameraPos.x - dragStartPos.x, 2) +
                        Math.pow(cameraPos.y - dragStartPos.y, 2) +
                        Math.pow(cameraPos.z - dragStartPos.z, 2)
                    )
                }

                root.scaleStarted(root.activeAxis)

                mouse.accepted = true
                preventStealing = true
                root.repaintGizmo()
            } else {
                root.activeAxis = GizmoEnums.Axis.None
                mouse.accepted = false
            }
        }

        onPositionChanged: (mouse) => {
            if (!pressed || !root.targetNode || root.activeAxis === GizmoEnums.Axis.None) {
                return
            }

            mouse.accepted = true

            if (root.activeAxis === GizmoEnums.Axis.Uniform) {
                // Uniform scaling based on mouse Y movement
                var screenCenter = GizmoMath.worldToScreen(root.view3d, dragStartPos)
                var deltaY = screenCenter.y - mouse.y  // Positive = mouse moved up = scale up
                var scaleFactor = 1.0 + (deltaY / 100.0)  // 100 pixels = 2x scale

                // Clamp to prevent negative/zero scale
                scaleFactor = Math.max(0.01, scaleFactor)

                // Apply snap if enabled
                if (root.snapEnabled) {
                    if (root.snapToAbsolute) {
                        // Snap to absolute scale values
                        // Uniform scale: use dragStartScale.x as reference (all components equal)
                        var currentAbsoluteScale = dragStartScale.x * scaleFactor
                        var snappedAbsoluteScale = GizmoMath.snapValueAbsolute(currentAbsoluteScale, root.snapIncrement)
                        scaleFactor = snappedAbsoluteScale / dragStartScale.x
                    } else {
                        // Snap relative to drag start (existing behavior)
                        scaleFactor = GizmoMath.snapValue(scaleFactor, root.snapIncrement)
                    }
                }

                // Emit uniform scale delta with transform mode
                root.scaleDelta(root.activeAxis, root.transformMode, scaleFactor, root.snapEnabled)
            } else {
                // Axis-constrained scaling using screen-space projection
                var currentScreenPos = Qt.point(mouse.x, mouse.y)

                // Calculate mouse displacement in screen space
                var displaceX = currentScreenPos.x - dragStartScreenPos.x
                var displaceY = currentScreenPos.y - dragStartScreenPos.y

                // Project displacement onto screen-space axis direction (dot product)
                var projectedDisplacement = displaceX * screenAxisDir.x + displaceY * screenAxisDir.y

                // Calculate scale factor: 1.0 + (projected displacement / arrow length)
                var scaleFactor = 1.0
                if (arrowScreenLength > 0) {
                    scaleFactor = 1.0 + (projectedDisplacement / arrowScreenLength)
                }

                // Clamp to prevent negative/zero scale
                scaleFactor = Math.max(0.01, scaleFactor)

                // Apply snap if enabled
                if (root.snapEnabled) {
                    if (root.snapToAbsolute) {
                        // Snap to absolute scale values
                        var axisIndex = root.activeAxis - 1  // 0=X, 1=Y, 2=Z
                        var currentAbsoluteScale = dragStartScale[["x", "y", "z"][axisIndex]] * scaleFactor
                        var snappedAbsoluteScale = GizmoMath.snapValueAbsolute(currentAbsoluteScale, root.snapIncrement)
                        scaleFactor = snappedAbsoluteScale / dragStartScale[["x", "y", "z"][axisIndex]]
                    } else {
                        // Snap relative to drag start (existing behavior)
                        scaleFactor = GizmoMath.snapValue(scaleFactor, root.snapIncrement)
                    }
                }

                // Emit axis-constrained scale delta with transform mode
                root.scaleDelta(root.activeAxis, root.transformMode, scaleFactor, root.snapEnabled)
            }

            root.repaintGizmo()
        }

        onReleased: (mouse) => {
            if (root.activeAxis !== GizmoEnums.Axis.None) {
                root.scaleEnded(root.activeAxis)
                mouse.accepted = true
            } else {
                mouse.accepted = false
            }
            root.activeAxis = GizmoEnums.Axis.None
            preventStealing = false
            root.repaintGizmo()
        }
    }

    // Helper function to repaint canvas
    function repaintGizmo() {
        canvas.requestPaint()
    }

    // Repaint when target position changes
    Connections {
        target: root.targetNode
        function onPositionChanged() {
            root.repaintGizmo()
        }
        function onScaleChanged() {
            root.repaintGizmo()
        }
    }

    // Repaint when target rotation changes (needed for local mode)
    Connections {
        target: root.targetNode
        enabled: root.transformMode === GizmoEnums.TransformMode.Local
        function onRotationChanged() {
            root.repaintGizmo()
        }
    }

    // Repaint when view3d camera changes
    Connections {
        target: root.view3d ? root.view3d.camera : null
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

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

    // Performance optimization: drag state and caching
    property bool isDragging: false
    property var cachedProjector: null
    property var lastHitTestGeometry: null

    // External control flag - when true, parent manages geometry updates via FrameAnimation
    property bool managedByParent: false

    // Geometry property - updated by FrameAnimation or parent coordinator
    property var geometry: null

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
     * Updates geometry using the provided projector.
     * Called by parent coordinator (GlobalGizmo) or internal FrameAnimation.
     * @param projector - Shared projector object from View3DProjectionAdapter
     */
    function updateGeometry(projector) {
        if (!view3d || !view3d.camera || !targetNode) {
            geometry = null
            return
        }

        geometry = ScaleGeometryCalculator.calculateHandleGeometry({
            projector: projector,
            targetPosition: targetNode.position,
            axes: currentAxes,
            gizmoSize: gizmoSize,
            maxScreenSize: maxScreenSize,
            arrowStartRatio: arrowStartRatio,
            arrowEndRatio: arrowEndRatio
        })
    }

    // Helper for hit testing - needs fresh geometry calculation
    function calculateGizmoGeometry() {
        if (!view3d || !view3d.camera || !targetNode) return null
        var projector = View3DProjectionAdapter.createProjector(view3d)
        if (!projector) return null
        return ScaleGeometryCalculator.calculateHandleGeometry({
            projector: projector,
            targetPosition: targetNode.position,
            axes: currentAxes,
            gizmoSize: gizmoSize,
            maxScreenSize: maxScreenSize,
            arrowStartRatio: arrowStartRatio,
            arrowEndRatio: arrowEndRatio
        })
    }

    // ========================================
    // Rendering Layer - QtQuick.Shapes based
    // ========================================

    Item {
        id: renderLayer
        anchors.fill: parent

        // Uniform scale handle at center
        SquareHandleRenderer {
            anchors.fill: parent
            center: root.geometry ? root.geometry.center : Qt.point(0, 0)
            color: root.uniformColor
            size: 8
        }

        // X axis (red) with square end
        ScaleArrowRenderer {
            anchors.fill: parent
            startPoint: root.geometry ? root.geometry.xStart : Qt.point(0, 0)
            endPoint: root.geometry ? root.geometry.xEnd : Qt.point(0, 0)
            color: root.xAxisColor
            lineWidth: root.lineWidth
            squareSize: 12
        }

        // Y axis (green) with square end
        ScaleArrowRenderer {
            anchors.fill: parent
            startPoint: root.geometry ? root.geometry.yStart : Qt.point(0, 0)
            endPoint: root.geometry ? root.geometry.yEnd : Qt.point(0, 0)
            color: root.yAxisColor
            lineWidth: root.lineWidth
            squareSize: 12
        }

        // Z axis (blue) with square end
        ScaleArrowRenderer {
            anchors.fill: parent
            startPoint: root.geometry ? root.geometry.zStart : Qt.point(0, 0)
            endPoint: root.geometry ? root.geometry.zEnd : Qt.point(0, 0)
            color: root.zAxisColor
            lineWidth: root.lineWidth
            squareSize: 12
        }
    }

    // Geometric hit detection (uses HitTester)
    // Caches geometry to avoid recalculating on press
    function getHitRegion(x, y) {
        lastHitTestGeometry = calculateGizmoGeometry()
        var result = HitTester.testScaleGizmoHit(Qt.point(x, y), lastHitTestGeometry, 10, 12)

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

                // Start drag - cache projector
                root.isDragging = true
                root.cachedProjector = View3DProjectionAdapter.createProjector(root.view3d)

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
            } else if (hitInfo.type === "uniform") {
                root.activeAxis = GizmoEnums.Axis.Uniform  // Uniform scaling

                // Start drag - cache projector
                root.isDragging = true
                root.cachedProjector = View3DProjectionAdapter.createProjector(root.view3d)

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
            // Note: updateGeometry() removed - geometry is cached at drag start,
            // visual feedback (colors) changes during drag via property bindings
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

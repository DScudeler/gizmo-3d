import QtQuick
import QtQuick.Window
import QtQuick3D
import Gizmo3D

Window {
    id: mainWindow
    width: 1600
    height: 1000
    visible: true
    title: "Gizmo3D Benchmark"
    color: "#1a1a2e"

    // Configuration
    property int objectCount: 10000
    property int warmupFrames: 30
    property int measureFrames: 300

    // Phase tracking: 0 = scene-only, 1 = scene+gizmo
    property int phase: 0
    property var phaseNames: ["scene_only", "scene_with_gizmo"]

    // Deterministic hash from index for pseudo-random distribution
    function hash(n) {
        var x = Math.sin(n * 127.1 + 311.7) * 43758.5453
        return x - Math.floor(x)
    }

    // Mesh sources cycling by index
    readonly property var meshTypes: ["#Cube", "#Sphere", "#Cylinder", "#Cone", "#Cube"]

    // Deterministic color from index
    function colorFromIndex(idx) {
        var h = hash(idx * 7 + 13)
        var s = 0.5 + hash(idx * 3 + 7) * 0.5
        var l = 0.35 + hash(idx * 11 + 3) * 0.3
        return Qt.hsla(h, s, l, 1.0)
    }

    // Whether gizmos are active this phase
    property bool gizmoActive: phase === 1

    View3D {
        id: view3d
        anchors.fill: parent
        camera: camera

        environment: SceneEnvironment {
            clearColor: "#1a1a2e"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        // Camera orbit parent - rotated each frame to force geometry recalc
        Node {
            id: cameraOrbit

            PerspectiveCamera {
                id: camera
                position: Qt.vector3d(0, 500, 800)
                eulerRotation.x: -30
                clipFar: 50000
                clipNear: 1
            }
        }

        DirectionalLight {
            eulerRotation.x: -30
            eulerRotation.y: -70
            brightness: 1.0
            ambientColor: Qt.rgba(0.3, 0.3, 0.3, 1.0)
        }

        DirectionalLight {
            eulerRotation.x: 30
            eulerRotation.y: 110
            brightness: 0.5
        }

        // Ground plane
        Model {
            source: "#Rectangle"
            position: Qt.vector3d(0, -10, 0)
            eulerRotation.x: -90
            scale: Qt.vector3d(100, 100, 1)
            materials: PrincipledMaterial {
                baseColor: "#2a2a3e"
                metalness: 0.0
                roughness: 0.9
            }
        }

        // Benchmark target node
        Model {
            id: benchmarkTarget
            source: "#Cube"
            position: Qt.vector3d(0, 50, 0)
            scale: Qt.vector3d(0.5, 0.5, 0.5)
            materials: PrincipledMaterial {
                baseColor: "#ffffff"
                metalness: 0.5
                roughness: 0.3
            }
        }

        // Stress test objects
        Repeater3D {
            model: mainWindow.objectCount

            Model {
                required property int index

                property real gridSize: Math.ceil(Math.cbrt(mainWindow.objectCount))
                property real spacing: 30
                property real ix: index % gridSize
                property real iy: Math.floor(index / gridSize) % gridSize
                property real iz: Math.floor(index / (gridSize * gridSize))

                source: mainWindow.meshTypes[index % 5]

                position: Qt.vector3d(
                    (ix - gridSize / 2) * spacing + (hash(index * 3) - 0.5) * spacing * 0.5,
                    iy * spacing + 10 + (hash(index * 5) - 0.5) * spacing * 0.3,
                    (iz - gridSize / 2) * spacing + (hash(index * 7) - 0.5) * spacing * 0.5
                )

                eulerRotation: Qt.vector3d(
                    hash(index * 13) * 360,
                    hash(index * 17) * 360,
                    hash(index * 23) * 360
                )

                property real s: 0.1 + hash(index * 31) * 0.4
                scale: Qt.vector3d(s, s, s)

                materials: PrincipledMaterial {
                    baseColor: mainWindow.colorFromIndex(index)
                    metalness: 0.3
                    roughness: 0.5
                }
            }
        }
    }

    // ScaleGizmo - matching GlobalGizmo "All" mode
    ScaleGizmo {
        id: scaleGizmo
        anchors.fill: parent
        visible: gizmoActive
        managedByParent: true
        view3d: view3d
        targetNode: benchmarkTarget
        transformMode: GizmoEnums.TransformMode.World
        shapeAntialiasing: true
        gizmoSize: 80
        arrowStartRatio: 0.0
        arrowEndRatio: 0.5
    }

    // TranslationGizmo - matching GlobalGizmo "All" mode
    TranslationGizmo {
        id: translationGizmo
        anchors.fill: parent
        visible: gizmoActive
        managedByParent: true
        view3d: view3d
        targetNode: benchmarkTarget
        transformMode: GizmoEnums.TransformMode.World
        shapeAntialiasing: true
        gizmoSize: 104  // 80 * 1.3
        arrowStartRatio: 0.5
        arrowEndRatio: 1.0
    }

    // RotationGizmo - matching GlobalGizmo "All" mode
    RotationGizmo {
        id: rotationGizmo
        anchors.fill: parent
        visible: gizmoActive
        managedByParent: true
        view3d: view3d
        targetNode: benchmarkTarget
        transformMode: GizmoEnums.TransformMode.World
        shapeAntialiasing: true
        gizmoSize: 80
        z: 1  // Rotation on top, matching GlobalGizmo
    }

    // Benchmark state
    property int frameCount: 0
    property real lastTimestamp: 0
    property var frameTimes: []
    property var geometryTimes: []

    // Store results from both phases
    property var results: []

    // Statistics helpers
    function percentile(arr, p) {
        var sorted = arr.slice().sort(function(a, b) { return a - b })
        var idx = Math.ceil(p / 100.0 * sorted.length) - 1
        return sorted[Math.max(0, idx)]
    }

    function average(arr) {
        var sum = 0
        for (var i = 0; i < arr.length; i++) sum += arr[i]
        return sum / arr.length
    }

    function minimum(arr) {
        var m = arr[0]
        for (var i = 1; i < arr.length; i++) if (arr[i] < m) m = arr[i]
        return m
    }

    function maximum(arr) {
        var m = arr[0]
        for (var i = 1; i < arr.length; i++) if (arr[i] > m) m = arr[i]
        return m
    }

    function computeStats(times) {
        return {
            avg: average(times),
            min: minimum(times),
            max: maximum(times),
            p50: percentile(times, 50),
            p95: percentile(times, 95),
            p99: percentile(times, 99)
        }
    }

    function capturePhaseResults() {
        var ft = computeStats(frameTimes)
        var gt = geometryTimes.length > 0 ? computeStats(geometryTimes) : null
        results.push({
            name: phaseNames[phase],
            measured: frameTimes.length,
            frameTime: ft,
            geometryTime: gt,
            fpsAvg: 1000.0 / ft.avg,
            fpsMin: 1000.0 / ft.max,
            fpsP5:  1000.0 / ft.p95
        })
    }

    function printPhase(r, prefix) {
        console.log(prefix + "measured_frames=" + r.measured)
        console.log(prefix + "frame_time_avg_ms=" + r.frameTime.avg.toFixed(2))
        console.log(prefix + "frame_time_min_ms=" + r.frameTime.min.toFixed(2))
        console.log(prefix + "frame_time_max_ms=" + r.frameTime.max.toFixed(2))
        console.log(prefix + "frame_time_p50_ms=" + r.frameTime.p50.toFixed(2))
        console.log(prefix + "frame_time_p95_ms=" + r.frameTime.p95.toFixed(2))
        console.log(prefix + "frame_time_p99_ms=" + r.frameTime.p99.toFixed(2))
        if (r.geometryTime) {
            console.log(prefix + "geometry_time_avg_ms=" + r.geometryTime.avg.toFixed(2))
            console.log(prefix + "geometry_time_min_ms=" + r.geometryTime.min.toFixed(2))
            console.log(prefix + "geometry_time_max_ms=" + r.geometryTime.max.toFixed(2))
            console.log(prefix + "geometry_time_p50_ms=" + r.geometryTime.p50.toFixed(2))
            console.log(prefix + "geometry_time_p95_ms=" + r.geometryTime.p95.toFixed(2))
            console.log(prefix + "geometry_time_p99_ms=" + r.geometryTime.p99.toFixed(2))
        }
        console.log(prefix + "fps_avg=" + r.fpsAvg.toFixed(2))
        console.log(prefix + "fps_min=" + r.fpsMin.toFixed(2))
        console.log(prefix + "fps_p5=" + r.fpsP5.toFixed(2))
    }

    function printAllResults() {
        var sceneOnly = results[0]
        var withGizmo = results[1]

        console.log("[BENCHMARK] Gizmo3D Performance Benchmark")
        console.log("[BENCHMARK] Scene: " + objectCount + " objects, Mode: All, Transform: World")
        console.log("[BENCHMARK] Window: " + width + "x" + height +
                    ", Warmup: " + warmupFrames + ", Measured: " + measureFrames + " frames per phase")
        console.log("BENCHMARK_RESULTS_START")

        // Phase 1: scene only
        printPhase(sceneOnly, "scene_only.")

        // Phase 2: scene + gizmo
        printPhase(withGizmo, "scene_with_gizmo.")

        // Delta: gizmo overhead
        var ftDelta = withGizmo.frameTime.avg - sceneOnly.frameTime.avg
        var fpsDelta = withGizmo.fpsAvg - sceneOnly.fpsAvg
        console.log("gizmo_overhead_avg_ms=" + ftDelta.toFixed(2))
        console.log("gizmo_overhead_fps=" + fpsDelta.toFixed(2))

        console.log("BENCHMARK_RESULTS_END")
    }

    // Core benchmark loop
    FrameAnimation {
        id: benchmarkLoop
        running: true

        onTriggered: {
            var now = Date.now()

            // Advance camera orbit: full 360 over measured frames
            cameraOrbit.eulerRotation.y = (frameCount / measureFrames) * 360

            // Only run geometry updates during gizmo phase
            var geoTime = 0
            if (gizmoActive) {
                var projector = View3DProjectionAdapter.createProjector(view3d)
                var geoStart = Date.now()
                scaleGizmo.updateGeometry(projector)
                translationGizmo.updateGeometry(projector)
                rotationGizmo.updateGeometry(projector)
                geoTime = Date.now() - geoStart
            }

            // Record measurements after warmup
            if (frameCount >= warmupFrames && lastTimestamp > 0) {
                frameTimes.push(now - lastTimestamp)
                if (gizmoActive)
                    geometryTimes.push(geoTime)
            }

            lastTimestamp = now
            frameCount++

            // Phase complete
            if (frameCount >= warmupFrames + measureFrames) {
                capturePhaseResults()

                if (phase < 1) {
                    // Reset for next phase
                    phase++
                    frameCount = 0
                    lastTimestamp = 0
                    frameTimes = []
                    geometryTimes = []
                } else {
                    // All phases done
                    benchmarkLoop.running = false
                    printAllResults()
                    Qt.quit()
                }
            }
        }
    }

    // Minimal HUD
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        width: hudText.width + 20
        height: hudText.height + 20
        color: "#cc000000"
        radius: 5

        Text {
            id: hudText
            anchors.centerIn: parent
            text: {
                var phaseName = gizmoActive ? "Scene + Gizmo" : "Scene Only"
                var phaseNum = (phase + 1) + "/2"
                if (frameCount < warmupFrames)
                    return "Phase " + phaseNum + " [" + phaseName + "] Warmup: " + frameCount + "/" + warmupFrames
                else
                    return "Phase " + phaseNum + " [" + phaseName + "] Measuring: " + (frameCount - warmupFrames) + "/" + measureFrames
            }
            color: frameCount < warmupFrames ? "#ffff40" : "#40ff40"
            font.pixelSize: 16
            font.family: "monospace"
        }
    }
}

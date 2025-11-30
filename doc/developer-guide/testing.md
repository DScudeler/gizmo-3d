# Testing Guide

Testing patterns and best practices for Gizmo3D.

## Test Architecture

```
tests/
├── C++ Unit Tests (Qt Test Framework)
│   ├── tst_translationgizmo.cpp
│   ├── tst_rotationgizmo.cpp
│   ├── tst_scalegizmo.cpp
│   ├── tst_translationgizmo_snap.cpp
│   ├── tst_rotationgizmo_snap.cpp
│   └── tst_*primitive.cpp
│
├── QML Integration Tests (Qt Quick Test)
│   ├── tst_qml_gizmo.cpp            # Test runner
│   ├── tst_translationgizmo_interaction.qml
│   ├── tst_rotationgizmo_interaction.qml
│   ├── tst_gizmo_controller_integration.qml
│   ├── tst_gizmo_edge_cases.qml
│   ├── tst_gizmo_coordinate_transform.qml
│   ├── tst_gizmo_visual_feedback.qml
│   ├── tst_snap.qml
│   └── tst_rotationgizmo_snap.qml
│
└── UI_TESTS_README.md               # Test documentation
```

## Running Tests

### All Tests via CTest

```bash
# Using preset (recommended)
ctest --preset debug

# Verbose output
ctest --preset debug --verbose

# Parallel execution
ctest --preset debug -j4
```

### Specific Test

```bash
# By name pattern
ctest --preset debug -R TranslationGizmo
ctest --preset debug -R snap
ctest --preset debug -R primitive
```

### Direct Execution

```bash
# C++ test
export QT_QPA_PLATFORM=offscreen
./build/debug/tests/tst_translationgizmo

# QML tests (require display)
export QT_QPA_PLATFORM=xcb
./build/debug/tests/tst_qml_gizmo
```

## Test Categories

### Property Tests

Test component properties and bindings:

```cpp
void TestTranslationGizmo::testProperties() {
    QQmlEngine engine;
    QQmlComponent component(&engine);
    component.setData(R"(
        import QtQuick
        import QtQuick3D
        import Gizmo3D 1.0

        TranslationGizmo {
            gizmoSize: 150.0
            snapEnabled: true
            snapIncrement: 0.5
        }
    )", QUrl());

    QScopedPointer<QObject> gizmo(component.create());
    QVERIFY(gizmo);
    QCOMPARE(gizmo->property("gizmoSize").toReal(), 150.0);
    QCOMPARE(gizmo->property("snapEnabled").toBool(), true);
}
```

### Signal Tests

Test signal emission:

```qml
// tst_translationgizmo_interaction.qml
TestCase {
    name: "TranslationGizmoSignals"

    TranslationGizmo {
        id: gizmo
        view3d: testView3D
        targetNode: testCube
    }

    SignalSpy {
        id: startedSpy
        target: gizmo
        signalName: "axisTranslationStarted"
    }

    function test_signalEmission() {
        // Simulate mouse press on X axis
        mousePress(gizmo, xAxisCenter.x, xAxisCenter.y)
        compare(startedSpy.count, 1)
        compare(startedSpy.signalArguments[0][0], 1) // axis = 1 (X)
    }
}
```

### Geometry Tests

Test coordinate calculations:

```qml
TestCase {
    name: "GeometryCalculation"

    function test_worldToScreen() {
        var screenPoint = GizmoMath.worldToScreen(view3d, Qt.vector3d(0, 0, 0))
        verify(screenPoint !== null)
        verify(screenPoint.x > 0)
        verify(screenPoint.y > 0)
    }

    function test_rayAxisIntersection() {
        var ray = GizmoMath.getCameraRay(view3d, Qt.point(400, 300))
        var result = GizmoMath.closestPointOnAxisToRay(
            ray.origin, ray.direction,
            Qt.vector3d(0, 0, 0),
            Qt.vector3d(1, 0, 0)
        )
        verify(result !== null)
    }
}
```

### Snap Tests

Test snapping behavior:

```qml
TestCase {
    name: "SnapBehavior"

    function test_relativeSnap() {
        var result = GizmoMath.snapValue(1.7, 0.5)
        compare(result, 1.5)
    }

    function test_absoluteSnap() {
        var result = GizmoMath.snapValueAbsolute(1.7, 0.5)
        compare(result, 1.5)
    }

    function test_snapIncrement() {
        gizmo.snapEnabled = true
        gizmo.snapIncrement = 0.25

        // Simulate drag and verify snapped values
    }
}
```

### Controller Integration Tests

Test signal handling patterns:

```qml
TestCase {
    name: "ControllerIntegration"

    property vector3d dragStartPos

    TranslationGizmo {
        id: gizmo
        view3d: testView3D
        targetNode: testCube

        onAxisTranslationStarted: {
            dragStartPos = testCube.position
        }

        onAxisTranslationDelta: function(axis, mode, delta, snap) {
            var pos = dragStartPos
            if (axis === GizmoEnums.Axis.X) pos.x += delta
            testCube.position = pos
        }
    }

    function test_translationController() {
        var initialPos = testCube.position

        // Simulate drag
        mousePress(gizmo, xAxisPoint.x, xAxisPoint.y)
        mouseMove(gizmo, xAxisPoint.x + 50, xAxisPoint.y)
        mouseRelease(gizmo, xAxisPoint.x + 50, xAxisPoint.y)

        // Verify position changed
        verify(testCube.position.x !== initialPos.x)
    }
}
```

## Environment Requirements

### Display Requirements

| Test Type | Display Required | Platform Setting |
|-----------|------------------|------------------|
| Property tests | No | `QT_QPA_PLATFORM=offscreen` |
| Geometry tests | No | `QT_QPA_PLATFORM=offscreen` |
| Interaction tests | **Yes** | `QT_QPA_PLATFORM=xcb` |
| Visual tests | **Yes** | `QT_QPA_PLATFORM=xcb` |

### CI/CD Configuration

For headless CI environments:

```yaml
# GitHub Actions example
test:
  runs-on: ubuntu-latest
  steps:
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y xvfb qt6-base-dev qt6-quick3d-dev

    - name: Run tests
      run: |
        xvfb-run -a ctest --preset debug
```

### Environment Variables

```bash
# Required for tests
export QT_QPA_PLATFORM=offscreen   # Or xcb for interaction tests
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

# Clear snap contamination (Linux)
unset GTK_PATH GIO_MODULE_DIR

# QML module path
export QML2_IMPORT_PATH=/path/to/build/debug/src
```

## Writing New Tests

### C++ Test Template

```cpp
#include <QtTest>
#include <QtQuickTest>
#include <QQmlEngine>
#include <QQmlComponent>

class TestNewGizmo : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();
    void init();
    void cleanup();

    void testProperties();
    void testPropertyDefaults();
    void testPropertyBindings();
};

void TestNewGizmo::testProperties()
{
    QQmlEngine engine;
    engine.addImportPath(QML_IMPORT_PATH);

    QQmlComponent component(&engine);
    component.setData(R"(
        import Gizmo3D 1.0
        NewGizmo { }
    )", QUrl());

    QVERIFY2(component.isReady(), qPrintable(component.errorString()));

    QScopedPointer<QObject> gizmo(component.create());
    QVERIFY(gizmo);

    // Test properties
    QCOMPARE(gizmo->property("someProperty"), expectedValue);
}

QTEST_MAIN(TestNewGizmo)
#include "tst_newgizmo.moc"
```

### QML Test Template

```qml
import QtQuick
import QtQuick3D
import QtTest
import Gizmo3D 1.0

TestCase {
    id: testCase
    name: "NewGizmoTests"
    when: windowShown

    // Test scene
    View3D {
        id: testView3D
        anchors.fill: parent

        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(0, 0, 500)
        }

        Model {
            id: testCube
            source: "#Cube"
            scale: Qt.vector3d(0.5, 0.5, 0.5)
        }
    }

    // Component under test
    NewGizmo {
        id: gizmo
        view3d: testView3D
        targetNode: testCube
    }

    // Signal spies
    SignalSpy {
        id: startedSpy
        target: gizmo
        signalName: "started"
    }

    function init() {
        startedSpy.clear()
        testCube.position = Qt.vector3d(0, 0, 0)
    }

    function test_propertyDefaults() {
        compare(gizmo.gizmoSize, 100.0)
        compare(gizmo.snapEnabled, false)
    }

    function test_signalEmission() {
        // Test implementation
    }
}
```

### CMakeLists.txt Addition

```cmake
# C++ test
qt_add_executable(tst_newgizmo tst_newgizmo.cpp)
target_link_libraries(tst_newgizmo PRIVATE
    Qt6::Test
    Qt6::Quick
    Qt6::Quick3D
    gizmo3d
)
target_compile_definitions(tst_newgizmo PRIVATE
    QML_IMPORT_PATH="${CMAKE_BINARY_DIR}/src"
)
add_test(NAME NewGizmoTest COMMAND tst_newgizmo)

# QML test (add to QML_FILES in tst_qml_gizmo)
```

## Test Best Practices

### Do

- Test one thing per test function
- Use descriptive test names
- Clean up state in `init()`/`cleanup()`
- Use SignalSpy for signal testing
- Test edge cases and error conditions
- Verify both positive and negative cases

### Don't

- Depend on test execution order
- Share mutable state between tests
- Use hardcoded screen coordinates
- Skip cleanup on test failure
- Test implementation details

## Debugging Tests

### Verbose Output

```bash
./build/debug/tests/tst_translationgizmo -v2
```

### Single Test Function

```bash
./build/debug/tests/tst_translationgizmo testProperties
```

### QML Test Debugging

```bash
# Enable QML debugging
export QML_IMPORT_TRACE=1
./build/debug/tests/tst_qml_gizmo
```

## See Also

- [Code Organization](code-organization.md) - Project structure
- [Building](building.md) - Build system details
- [UI_TESTS_README.md](../../tests/UI_TESTS_README.md) - Detailed test documentation

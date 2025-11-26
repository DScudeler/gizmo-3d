#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QSignalSpy>

class TestScaleGizmo : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();
    void init();
    void cleanup();

    // Test cases
    void testComponentCreation();
    void testProperties();
    void testGizmoSize();
    void testTargetNodeBinding();
    void testSignals();
    void testTrivialController();
    void testArrowRatios();

private:
    QQmlEngine *engine = nullptr;
};

void TestScaleGizmo::initTestCase()
{
    engine = new QQmlEngine(this);
}

void TestScaleGizmo::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestScaleGizmo::init()
{
    // Setup before each test
}

void TestScaleGizmo::cleanup()
{
    // Cleanup after each test
}

void TestScaleGizmo::testComponentCreation()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        ScaleGizmo {
            width: 800
            height: 600
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QQuickItem *item = qobject_cast<QQuickItem*>(object);
    QVERIFY(item != nullptr);

    delete object;
}

void TestScaleGizmo::testProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        ScaleGizmo {
            gizmoSize: 150.0
            activeAxis: 1
            snapIncrement: 0.25
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test gizmoSize property
    QVariant gizmoSize = object->property("gizmoSize");
    QVERIFY(gizmoSize.isValid());
    QCOMPARE(gizmoSize.toReal(), 150.0);

    // Test activeAxis property
    QVariant activeAxis = object->property("activeAxis");
    QVERIFY(activeAxis.isValid());
    QCOMPARE(activeAxis.toInt(), 1);

    // Test snapIncrement property
    QVariant snapIncrement = object->property("snapIncrement");
    QVERIFY(snapIncrement.isValid());
    QCOMPARE(snapIncrement.toReal(), 0.25);

    delete object;
}

void TestScaleGizmo::testGizmoSize()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        ScaleGizmo {
            id: gizmo
            gizmoSize: 100.0
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test default size
    QCOMPARE(object->property("gizmoSize").toReal(), 100.0);

    // Test size change
    object->setProperty("gizmoSize", 200.0);
    QCOMPARE(object->property("gizmoSize").toReal(), 200.0);

    delete object;
}

void TestScaleGizmo::testTargetNodeBinding()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import QtQuick3D
        import Gizmo3D

        Item {
            property alias gizmo: gizmo
            property alias target: targetNode

            Node {
                id: targetNode
                position: Qt.vector3d(10, 20, 30)
                scale: Qt.vector3d(1, 1, 1)
            }

            ScaleGizmo {
                id: gizmo
                targetNode: targetNode
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *root = component.create();
    QVERIFY(root != nullptr);

    QObject *gizmo = root->property("gizmo").value<QObject*>();
    QVERIFY(gizmo != nullptr);

    QObject *target = root->property("target").value<QObject*>();
    QVERIFY(target != nullptr);

    // Verify binding
    QCOMPARE(gizmo->property("targetNode").value<QObject*>(), target);

    // Test targetPosition updates with target node position
    QVector3D expectedPos(10, 20, 30);
    QVector3D actualPos = gizmo->property("targetPosition").value<QVector3D>();
    QCOMPARE(actualPos, expectedPos);

    delete root;
}

void TestScaleGizmo::testSignals()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import QtQuick3D
        import Gizmo3D

        Item {
            property alias gizmo: gizmo
            property int startedCount: 0
            property int deltaCount: 0
            property int endedCount: 0
            property int lastAxis: 0
            property real lastScaleFactor: 0.0
            property bool lastSnapActive: false

            ScaleGizmo {
                id: gizmo

                onScaleStarted: function(axis) {
                    startedCount++
                    lastAxis = axis
                }

                onScaleDelta: function(axis, transformMode, scaleFactor, snapActive) {
                    deltaCount++
                    lastAxis = axis
                    lastScaleFactor = scaleFactor
                    lastSnapActive = snapActive
                }

                onScaleEnded: function(axis) {
                    endedCount++
                    lastAxis = axis
                }
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *root = component.create();
    QVERIFY(root != nullptr);

    QObject *gizmo = root->property("gizmo").value<QObject*>();
    QVERIFY(gizmo != nullptr);

    // Test scaleStarted signal
    QMetaObject::invokeMethod(gizmo, "scaleStarted", Q_ARG(int, 1));
    QCOMPARE(root->property("startedCount").toInt(), 1);
    QCOMPARE(root->property("lastAxis").toInt(), 1);

    // Test scaleDelta signal (X-axis in world mode)
    // GizmoEnums.TransformMode.World = 0, GizmoEnums.TransformMode.Local = 1
    QMetaObject::invokeMethod(gizmo, "scaleDelta",
                              Q_ARG(int, 1),
                              Q_ARG(int, 0),  // TransformMode.World
                              Q_ARG(qreal, 1.5),
                              Q_ARG(bool, true));
    QCOMPARE(root->property("deltaCount").toInt(), 1);
    QCOMPARE(root->property("lastScaleFactor").toReal(), 1.5);
    QCOMPARE(root->property("lastSnapActive").toBool(), true);

    // Test scaleEnded signal
    QMetaObject::invokeMethod(gizmo, "scaleEnded", Q_ARG(int, 1));
    QCOMPARE(root->property("endedCount").toInt(), 1);

    delete root;
}

void TestScaleGizmo::testTrivialController()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import QtQuick3D
        import Gizmo3D

        Item {
            property alias gizmo: gizmo
            property alias target: targetNode
            property vector3d dragStartScale: Qt.vector3d(1, 1, 1)

            Node {
                id: targetNode
                position: Qt.vector3d(0, 0, 0)
                scale: Qt.vector3d(1, 1, 1)
            }

            ScaleGizmo {
                id: gizmo
                targetNode: targetNode

                onScaleStarted: function(axis) {
                    dragStartScale = targetNode.scale
                }

                onScaleDelta: function(axis, transformMode, scaleFactor, snapActive) {
                    if (axis === 1) {
                        // X axis scaling
                        targetNode.scale = Qt.vector3d(dragStartScale.x * scaleFactor, dragStartScale.y, dragStartScale.z)
                    } else if (axis === 2) {
                        // Y axis scaling
                        targetNode.scale = Qt.vector3d(dragStartScale.x, dragStartScale.y * scaleFactor, dragStartScale.z)
                    } else if (axis === 3) {
                        // Z axis scaling
                        targetNode.scale = Qt.vector3d(dragStartScale.x, dragStartScale.y, dragStartScale.z * scaleFactor)
                    } else if (axis === 4) {
                        // Uniform scaling
                        targetNode.scale = Qt.vector3d(dragStartScale.x * scaleFactor, dragStartScale.y * scaleFactor, dragStartScale.z * scaleFactor)
                    }
                }
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *root = component.create();
    QVERIFY(root != nullptr);

    QObject *gizmo = root->property("gizmo").value<QObject*>();
    QVERIFY(gizmo != nullptr);

    QObject *target = root->property("target").value<QObject*>();
    QVERIFY(target != nullptr);

    // Simulate X-axis scaling
    // GizmoEnums.TransformMode.World = 0, GizmoEnums.TransformMode.Local = 1
    QMetaObject::invokeMethod(gizmo, "scaleStarted", Q_ARG(int, 1));
    QMetaObject::invokeMethod(gizmo, "scaleDelta",
        Q_ARG(int, 1),
        Q_ARG(int, 0),  // TransformMode.World
        Q_ARG(qreal, 2.0),
        Q_ARG(bool, false));

    QVector3D scale = target->property("scale").value<QVector3D>();
    QCOMPARE(scale.x(), 2.0);
    QCOMPARE(scale.y(), 1.0);
    QCOMPARE(scale.z(), 1.0);

    // Simulate uniform scaling
    QMetaObject::invokeMethod(gizmo, "scaleStarted", Q_ARG(int, 4));
    QMetaObject::invokeMethod(gizmo, "scaleDelta",
        Q_ARG(int, 4),
        Q_ARG(int, 0),  // TransformMode.World
        Q_ARG(qreal, 0.5),
        Q_ARG(bool, false));

    scale = target->property("scale").value<QVector3D>();
    QCOMPARE(scale.x(), 1.0);  // 2.0 * 0.5
    QCOMPARE(scale.y(), 0.5);  // 1.0 * 0.5
    QCOMPARE(scale.z(), 0.5);  // 1.0 * 0.5

    delete root;
}

void TestScaleGizmo::testArrowRatios()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        ScaleGizmo {
            arrowStartRatio: 0.0
            arrowEndRatio: 0.5
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test arrow ratio properties
    QCOMPARE(object->property("arrowStartRatio").toReal(), 0.0);
    QCOMPARE(object->property("arrowEndRatio").toReal(), 0.5);

    // Test changing ratios
    object->setProperty("arrowStartRatio", 0.25);
    object->setProperty("arrowEndRatio", 0.75);
    QCOMPARE(object->property("arrowStartRatio").toReal(), 0.25);
    QCOMPARE(object->property("arrowEndRatio").toReal(), 0.75);

    delete object;
}

QTEST_MAIN(TestScaleGizmo)
#include "tst_scalegizmo.moc"

#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QQuaternion>
#include <QtPlugin>

class TestRotationGizmo : public QObject
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

private:
    QQmlEngine *engine = nullptr;
};

void TestRotationGizmo::initTestCase()
{
    engine = new QQmlEngine(this);

    // Add import path for the Gizmo3D module
    engine->addImportPath(QCoreApplication::applicationDirPath() + "/../src");
}

void TestRotationGizmo::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestRotationGizmo::init()
{
    // Setup before each test
}

void TestRotationGizmo::cleanup()
{
    // Cleanup after each test
}

void TestRotationGizmo::testComponentCreation()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
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

void TestRotationGizmo::testProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
            gizmoSize: 150.0
            activeAxis: 2
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
    QCOMPARE(activeAxis.toInt(), 2);

    delete object;
}

void TestRotationGizmo::testGizmoSize()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
            id: gizmo
            gizmoSize: 80.0
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test default size
    QCOMPARE(object->property("gizmoSize").toReal(), 80.0);

    // Test size change
    object->setProperty("gizmoSize", 120.0);
    QCOMPARE(object->property("gizmoSize").toReal(), 120.0);

    delete object;
}

void TestRotationGizmo::testTargetNodeBinding()
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
                eulerRotation: Qt.vector3d(45, 90, 0)
            }

            RotationGizmo {
                id: gizmo
                targetNode: targetNode
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *gizmo = object->property("gizmo").value<QObject*>();
    QVERIFY(gizmo != nullptr);

    QObject *target = object->property("target").value<QObject*>();
    QVERIFY(target != nullptr);

    // Verify the binding
    QObject *boundTarget = gizmo->property("targetNode").value<QObject*>();
    QCOMPARE(boundTarget, target);

    // Verify target position
    QVector3D targetPos = gizmo->property("targetPosition").value<QVector3D>();
    QCOMPARE(targetPos, QVector3D(10, 20, 30));

    delete object;
}

void TestRotationGizmo::testSignals()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import QtQuick3D
        import Gizmo3D

        Item {
            property alias gizmo: gizmo
            property alias target: targetNode
            property int startedCount: 0
            property int deltaCount: 0
            property int endedCount: 0
            property real lastAngleDelta: 0
            property int lastAxis: 0

            Node {
                id: targetNode
                position: Qt.vector3d(0, 0, 0)
            }

            RotationGizmo {
                id: gizmo
                targetNode: targetNode

                onRotationStarted: function(axis) {
                    parent.startedCount++
                    parent.lastAxis = axis
                }

                onRotationDelta: function(axis, angleDegrees, snapActive) {
                    parent.deltaCount++
                    parent.lastAngleDelta = angleDegrees
                }

                onRotationEnded: function(axis) {
                    parent.endedCount++
                }
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify initial counts
    QCOMPARE(object->property("startedCount").toInt(), 0);
    QCOMPARE(object->property("deltaCount").toInt(), 0);
    QCOMPARE(object->property("endedCount").toInt(), 0);

    delete object;
}

void TestRotationGizmo::testTrivialController()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import QtQuick3D
        import Gizmo3D

        Item {
            property alias gizmo: gizmo
            property alias target: targetNode
            property quaternion dragStartRot: Qt.quaternion(1, 0, 0, 0)

            Node {
                id: targetNode
                position: Qt.vector3d(0, 0, 0)
                rotation: Qt.quaternion(1, 0, 0, 0)
            }

            RotationGizmo {
                id: gizmo
                targetNode: targetNode

                // Trivial controller implementation
                onRotationStarted: function(axis) {
                    parent.dragStartRot = targetNode.rotation
                }

                onRotationDelta: function(axis, transformMode, angleDegrees, snapActive) {
                    let axisVec = axis === 1 ? Qt.vector3d(1, 0, 0)
                                : axis === 2 ? Qt.vector3d(0, 1, 0)
                                : Qt.vector3d(0, 0, 1)
                    let deltaQuat = GizmoMath.quaternionFromAxisAngle(axisVec, angleDegrees)
                    targetNode.rotation = deltaQuat.times(parent.dragStartRot)
                }
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *gizmo = object->property("gizmo").value<QObject*>();
    QVERIFY(gizmo != nullptr);

    QObject *target = object->property("target").value<QObject*>();
    QVERIFY(target != nullptr);

    // Verify initial rotation (identity quaternion)
    QQuaternion initialRot = target->property("rotation").value<QQuaternion>();
    QCOMPARE(initialRot, QQuaternion(1, 0, 0, 0));

    // Simulate rotation signal (Z-axis in world mode)
    // GizmoEnums.TransformMode.World = 0, GizmoEnums.TransformMode.Local = 1
    QMetaObject::invokeMethod(gizmo, "rotationStarted", Q_ARG(int, 3));
    QMetaObject::invokeMethod(gizmo, "rotationDelta",
        Q_ARG(int, 3),
        Q_ARG(int, 0),  // TransformMode.World
        Q_ARG(qreal, 45.0),
        Q_ARG(bool, false));

    // Verify rotation changed (should no longer be identity)
    QQuaternion newRot = target->property("rotation").value<QQuaternion>();
    QVERIFY(newRot != QQuaternion(1, 0, 0, 0));

    delete object;
}

QTEST_MAIN(TestRotationGizmo)
#include "tst_rotationgizmo.moc"

#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QtPlugin>

class TestRotationGizmoSnap : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();
    void init();
    void cleanup();

    // Test cases
    void testSnapEnabledProperty();
    void testSnapAngleProperty();
    void testSnapToAbsoluteProperty();
    void testDefaultValues();
    void testSnapEnabledToggle();
    void testSnapAngleValues();
    void testInvalidSnapAngle();

private:
    QQmlEngine *engine = nullptr;
};

void TestRotationGizmoSnap::initTestCase()
{
    engine = new QQmlEngine(this);

    // Add import path for the Gizmo3D module
    engine->addImportPath(QCoreApplication::applicationDirPath() + "/../src");
}

void TestRotationGizmoSnap::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestRotationGizmoSnap::init()
{
    // Setup before each test
}

void TestRotationGizmoSnap::cleanup()
{
    // Cleanup after each test
}

void TestRotationGizmoSnap::testSnapEnabledProperty()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
            snapEnabled: true
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify snapEnabled property exists and is readable
    QVariant snapEnabled = object->property("snapEnabled");
    QVERIFY(snapEnabled.isValid());
    QCOMPARE(snapEnabled.type(), QVariant::Bool);
    QCOMPARE(snapEnabled.toBool(), true);

    // Verify property is writable
    QVERIFY(object->setProperty("snapEnabled", false));
    QCOMPARE(object->property("snapEnabled").toBool(), false);

    delete object;
}

void TestRotationGizmoSnap::testSnapAngleProperty()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
            snapAngle: 30.0
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify snapAngle property exists and is readable
    QVariant snapAngle = object->property("snapAngle");
    QVERIFY(snapAngle.isValid());
    QVERIFY(snapAngle.canConvert<qreal>());
    QCOMPARE(snapAngle.toReal(), 30.0);

    // Verify property is writable
    QVERIFY(object->setProperty("snapAngle", 45.0));
    QCOMPARE(object->property("snapAngle").toReal(), 45.0);

    delete object;
}

void TestRotationGizmoSnap::testSnapToAbsoluteProperty()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
            snapToAbsolute: false
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify snapToAbsolute property exists and is readable
    QVariant snapToAbsolute = object->property("snapToAbsolute");
    QVERIFY(snapToAbsolute.isValid());
    QCOMPARE(snapToAbsolute.type(), QVariant::Bool);
    QCOMPARE(snapToAbsolute.toBool(), false);

    // Verify property is writable
    QVERIFY(object->setProperty("snapToAbsolute", true));
    QCOMPARE(object->property("snapToAbsolute").toBool(), true);

    delete object;
}

void TestRotationGizmoSnap::testDefaultValues()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify default values
    QCOMPARE(object->property("snapEnabled").toBool(), false);
    QCOMPARE(object->property("snapAngle").toReal(), 15.0);
    QCOMPARE(object->property("snapToAbsolute").toBool(), true);

    delete object;
}

void TestRotationGizmoSnap::testSnapEnabledToggle()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test toggling snapEnabled multiple times
    QCOMPARE(object->property("snapEnabled").toBool(), false);

    object->setProperty("snapEnabled", true);
    QCOMPARE(object->property("snapEnabled").toBool(), true);

    object->setProperty("snapEnabled", false);
    QCOMPARE(object->property("snapEnabled").toBool(), false);

    object->setProperty("snapEnabled", true);
    QCOMPARE(object->property("snapEnabled").toBool(), true);

    delete object;
}

void TestRotationGizmoSnap::testSnapAngleValues()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test various snap angle values (common rotation increments)
    object->setProperty("snapAngle", 1.0);
    QCOMPARE(object->property("snapAngle").toReal(), 1.0);

    object->setProperty("snapAngle", 5.0);
    QCOMPARE(object->property("snapAngle").toReal(), 5.0);

    object->setProperty("snapAngle", 15.0);
    QCOMPARE(object->property("snapAngle").toReal(), 15.0);

    object->setProperty("snapAngle", 30.0);
    QCOMPARE(object->property("snapAngle").toReal(), 30.0);

    object->setProperty("snapAngle", 45.0);
    QCOMPARE(object->property("snapAngle").toReal(), 45.0);

    object->setProperty("snapAngle", 90.0);
    QCOMPARE(object->property("snapAngle").toReal(), 90.0);

    delete object;
}

void TestRotationGizmoSnap::testInvalidSnapAngle()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        RotationGizmo {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test edge cases - these values should be accepted by the property system
    // The snapValue function handles zero/negative values internally
    object->setProperty("snapAngle", 0.0);
    QCOMPARE(object->property("snapAngle").toReal(), 0.0);

    object->setProperty("snapAngle", -15.0);
    QCOMPARE(object->property("snapAngle").toReal(), -15.0);

    delete object;
}

QTEST_MAIN(TestRotationGizmoSnap)
#include "tst_rotationgizmo_snap.moc"

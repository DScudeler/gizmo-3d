#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QtPlugin>

class TestTranslationGizmoSnap : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();
    void init();
    void cleanup();

    // Test cases
    void testSnapEnabledProperty();
    void testSnapIncrementProperty();
    void testSnapToAbsoluteProperty();
    void testDefaultValues();
    void testSnapEnabledToggle();
    void testSnapIncrementValues();
    void testInvalidSnapIncrement();

private:
    QQmlEngine *engine = nullptr;
};

void TestTranslationGizmoSnap::initTestCase()
{
    engine = new QQmlEngine(this);

    // Add import path for the Gizmo3D module
    engine->addImportPath(QCoreApplication::applicationDirPath() + "/../src");
}

void TestTranslationGizmoSnap::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestTranslationGizmoSnap::init()
{
    // Setup before each test
}

void TestTranslationGizmoSnap::cleanup()
{
    // Cleanup after each test
}

void TestTranslationGizmoSnap::testSnapEnabledProperty()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
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

void TestTranslationGizmoSnap::testSnapIncrementProperty()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
            snapIncrement: 5.0
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify snapIncrement property exists and is readable
    QVariant snapIncrement = object->property("snapIncrement");
    QVERIFY(snapIncrement.isValid());
    QVERIFY(snapIncrement.canConvert<qreal>());
    QCOMPARE(snapIncrement.toReal(), 5.0);

    // Verify property is writable
    QVERIFY(object->setProperty("snapIncrement", 10.0));
    QCOMPARE(object->property("snapIncrement").toReal(), 10.0);

    delete object;
}

void TestTranslationGizmoSnap::testSnapToAbsoluteProperty()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
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

void TestTranslationGizmoSnap::testDefaultValues()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify default values
    QCOMPARE(object->property("snapEnabled").toBool(), false);
    QCOMPARE(object->property("snapIncrement").toReal(), 1.0);
    QCOMPARE(object->property("snapToAbsolute").toBool(), true);

    delete object;
}

void TestTranslationGizmoSnap::testSnapEnabledToggle()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
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

void TestTranslationGizmoSnap::testSnapIncrementValues()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test various snap increment values
    object->setProperty("snapIncrement", 0.5);
    QCOMPARE(object->property("snapIncrement").toReal(), 0.5);

    object->setProperty("snapIncrement", 1.0);
    QCOMPARE(object->property("snapIncrement").toReal(), 1.0);

    object->setProperty("snapIncrement", 5.0);
    QCOMPARE(object->property("snapIncrement").toReal(), 5.0);

    object->setProperty("snapIncrement", 10.0);
    QCOMPARE(object->property("snapIncrement").toReal(), 10.0);

    object->setProperty("snapIncrement", 100.0);
    QCOMPARE(object->property("snapIncrement").toReal(), 100.0);

    delete object;
}

void TestTranslationGizmoSnap::testInvalidSnapIncrement()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Test edge cases - these values should be accepted by the property system
    // The snapValue function handles zero/negative values internally
    object->setProperty("snapIncrement", 0.0);
    QCOMPARE(object->property("snapIncrement").toReal(), 0.0);

    object->setProperty("snapIncrement", -1.0);
    QCOMPARE(object->property("snapIncrement").toReal(), -1.0);

    delete object;
}

QTEST_MAIN(TestTranslationGizmoSnap)
#include "tst_translationgizmo_snap.moc"

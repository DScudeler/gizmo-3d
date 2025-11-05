#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>
#include <QtPlugin>

// Import the static Gizmo3D plugin
Q_IMPORT_PLUGIN(Gizmo3DPlugin)

class TestTranslationGizmo : public QObject
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

private:
    QQmlEngine *engine = nullptr;
};

void TestTranslationGizmo::initTestCase()
{
    engine = new QQmlEngine(this);

    // Add import path for the Gizmo3D module
    engine->addImportPath(QCoreApplication::applicationDirPath() + "/../src");
}

void TestTranslationGizmo::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestTranslationGizmo::init()
{
    // Setup before each test
}

void TestTranslationGizmo::cleanup()
{
    // Cleanup after each test
}

void TestTranslationGizmo::testComponentCreation()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
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

void TestTranslationGizmo::testProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
            gizmoSize: 150.0
            activeAxis: 1
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

    delete object;
}

void TestTranslationGizmo::testGizmoSize()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        TranslationGizmo {
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

void TestTranslationGizmo::testTargetNodeBinding()
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
            }

            TranslationGizmo {
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

QTEST_MAIN(TestTranslationGizmo)
#include "tst_translationgizmo.moc"

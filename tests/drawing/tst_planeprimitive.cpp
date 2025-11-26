#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

class TestPlanePrimitive : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    // Test cases
    void testComponentCreation();
    void testDefaultProperties();
    void testCustomProperties();
    void testDrawFunction();
    void testDrawActiveState();
    void testDrawInactiveState();

private:
    QQmlEngine *engine = nullptr;
};

void TestPlanePrimitive::initTestCase()
{
    engine = new QQmlEngine(this);
}

void TestPlanePrimitive::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestPlanePrimitive::testComponentCreation()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        PlanePrimitive {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    delete object;
}

void TestPlanePrimitive::testDefaultProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        PlanePrimitive {
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify default property values
    QCOMPARE(object->property("inactiveAlpha").toReal(), 0.3);
    QCOMPARE(object->property("activeAlpha").toReal(), 0.5);
    QCOMPARE(object->property("inactiveLineWidth").toInt(), 2);
    QCOMPARE(object->property("activeLineWidth").toInt(), 3);

    delete object;
}

void TestPlanePrimitive::testCustomProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        PlanePrimitive {
            inactiveAlpha: 0.2
            activeAlpha: 0.6
            inactiveLineWidth: 1
            activeLineWidth: 4
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify custom property values
    QCOMPARE(object->property("inactiveAlpha").toReal(), 0.2);
    QCOMPARE(object->property("activeAlpha").toReal(), 0.6);
    QCOMPARE(object->property("inactiveLineWidth").toInt(), 1);
    QCOMPARE(object->property("activeLineWidth").toInt(), 4);

    delete object;
}

void TestPlanePrimitive::testDrawFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim
            width: 800
            height: 600

            PlanePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    // Create a quad (4 corners)
    QVariantList corners;
    corners << QVariant::fromValue(QPointF(0, 0));
    corners << QVariant::fromValue(QPointF(100, 0));
    corners << QVariant::fromValue(QPointF(100, 100));
    corners << QVariant::fromValue(QPointF(0, 100));

    // Verify draw function exists and is callable
    QMetaObject::invokeMethod(primitive, "draw",
        Q_ARG(QVariant, QVariant()),  // ctx (null for this test)
        Q_ARG(QVariant, corners),  // corners
        Q_ARG(QVariant, QColor("red")),  // color
        Q_ARG(QVariant, false));  // active

    delete object;
}

void TestPlanePrimitive::testDrawActiveState()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim

            PlanePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    QVariantList corners;
    corners << QVariant::fromValue(QPointF(0, 0));
    corners << QVariant::fromValue(QPointF(100, 0));
    corners << QVariant::fromValue(QPointF(100, 100));
    corners << QVariant::fromValue(QPointF(0, 100));

    // Test active state (should use activeAlpha and activeLineWidth)
    QMetaObject::invokeMethod(primitive, "draw",
        Q_ARG(QVariant, QVariant()),
        Q_ARG(QVariant, corners),
        Q_ARG(QVariant, QColor("blue")),
        Q_ARG(QVariant, true));  // active = true

    delete object;
}

void TestPlanePrimitive::testDrawInactiveState()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim

            PlanePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    QVariantList corners;
    corners << QVariant::fromValue(QPointF(0, 0));
    corners << QVariant::fromValue(QPointF(100, 0));
    corners << QVariant::fromValue(QPointF(100, 100));
    corners << QVariant::fromValue(QPointF(0, 100));

    // Test inactive state (should use inactiveAlpha and inactiveLineWidth)
    QMetaObject::invokeMethod(primitive, "draw",
        Q_ARG(QVariant, QVariant()),
        Q_ARG(QVariant, corners),
        Q_ARG(QVariant, QColor("green")),
        Q_ARG(QVariant, false));  // active = false

    delete object;
}

QTEST_MAIN(TestPlanePrimitive)
#include "tst_planeprimitive.moc"

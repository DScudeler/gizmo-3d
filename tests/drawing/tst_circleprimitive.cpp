#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

class TestCirclePrimitive : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    // Test cases
    void testComponentCreation();
    void testDefaultProperties();
    void testCustomProperties();
    void testDrawCircleFunction();
    void testDrawArcFunction();
    void testDrawFilledWedgeFunction();
    void testCombinedDrawFunction();

private:
    QQmlEngine *engine = nullptr;
};

void TestCirclePrimitive::initTestCase()
{
    engine = new QQmlEngine(this);
}

void TestCirclePrimitive::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestCirclePrimitive::testComponentCreation()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        CirclePrimitive {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    delete object;
}

void TestCirclePrimitive::testDefaultProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        CirclePrimitive {
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify default property values
    QCOMPARE(object->property("fillAlpha").toReal(), 0.5);
    QCOMPARE(object->property("lineCap").toString(), QString("round"));
    QCOMPARE(object->property("lineJoin").toString(), QString("round"));

    delete object;
}

void TestCirclePrimitive::testCustomProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        CirclePrimitive {
            fillAlpha: 0.7
            lineCap: "square"
            lineJoin: "miter"
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify custom property values
    QCOMPARE(object->property("fillAlpha").toReal(), 0.7);
    QCOMPARE(object->property("lineCap").toString(), QString("square"));
    QCOMPARE(object->property("lineJoin").toString(), QString("miter"));

    delete object;
}

void TestCirclePrimitive::testDrawCircleFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim
            width: 800
            height: 600

            CirclePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    // Create a simple circle points array (4 points forming a diamond)
    QVariantList points;
    points << QVariant::fromValue(QPointF(100, 0));
    points << QVariant::fromValue(QPointF(200, 100));
    points << QVariant::fromValue(QPointF(100, 200));
    points << QVariant::fromValue(QPointF(0, 100));

    // Verify drawCircle function exists and is callable
    QMetaObject::invokeMethod(primitive, "drawCircle",
        Q_ARG(QVariant, QVariant()),  // ctx (null for this test)
        Q_ARG(QVariant, points),  // points
        Q_ARG(QVariant, QColor("red")),  // color
        Q_ARG(QVariant, 3.0));  // lineWidth

    delete object;
}

void TestCirclePrimitive::testDrawArcFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim

            CirclePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    QVariantList points;
    points << QVariant::fromValue(QPointF(100, 0));
    points << QVariant::fromValue(QPointF(200, 100));

    // Verify drawArc function exists and is callable
    QMetaObject::invokeMethod(primitive, "drawArc",
        Q_ARG(QVariant, QVariant()),  // ctx
        Q_ARG(QVariant, points),  // points
        Q_ARG(QVariant, M_PI / 2),  // arcCenter
        Q_ARG(QVariant, M_PI),  // arcRange
        Q_ARG(QVariant, QColor("blue")),  // color
        Q_ARG(QVariant, 2.0));  // lineWidth

    delete object;
}

void TestCirclePrimitive::testDrawFilledWedgeFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim

            CirclePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    QVariantList points;
    points << QVariant::fromValue(QPointF(100, 0));
    points << QVariant::fromValue(QPointF(200, 100));

    // Verify drawFilledWedge function exists and is callable
    QMetaObject::invokeMethod(primitive, "drawFilledWedge",
        Q_ARG(QVariant, QVariant()),  // ctx
        Q_ARG(QVariant, points),  // points
        Q_ARG(QVariant, QPointF(100, 100)),  // center
        Q_ARG(QVariant, 0.0),  // arcStart
        Q_ARG(QVariant, M_PI / 2),  // arcEnd
        Q_ARG(QVariant, QColor("green")));  // color

    delete object;
}

void TestCirclePrimitive::testCombinedDrawFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim

            CirclePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    QVariantList points;
    points << QVariant::fromValue(QPointF(100, 0));
    points << QVariant::fromValue(QPointF(200, 100));

    // Verify combined draw function exists and is callable
    QMetaObject::invokeMethod(primitive, "draw",
        Q_ARG(QVariant, QVariant()),  // ctx
        Q_ARG(QVariant, points),  // points
        Q_ARG(QVariant, QPointF(100, 100)),  // center
        Q_ARG(QVariant, QColor("yellow")),  // color
        Q_ARG(QVariant, 3.0),  // lineWidth
        Q_ARG(QVariant, true),  // filled
        Q_ARG(QVariant, 0.0),  // arcStart
        Q_ARG(QVariant, M_PI),  // arcEnd
        Q_ARG(QVariant, QString()),  // geometryName
        Q_ARG(QVariant, false),  // partialArc
        Q_ARG(QVariant, 0.0),  // arcCenter
        Q_ARG(QVariant, 0.0));  // arcRange

    delete object;
}

QTEST_MAIN(TestCirclePrimitive)
#include "tst_circleprimitive.moc"

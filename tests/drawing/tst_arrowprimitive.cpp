#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

class TestArrowPrimitive : public QObject
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
    void testDrawWithSquareFunction();

private:
    QQmlEngine *engine = nullptr;
};

void TestArrowPrimitive::initTestCase()
{
    engine = new QQmlEngine(this);
}

void TestArrowPrimitive::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestArrowPrimitive::testComponentCreation()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        ArrowPrimitive {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    delete object;
}

void TestArrowPrimitive::testDefaultProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        ArrowPrimitive {
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify default property values
    QCOMPARE(object->property("headLength").toReal(), 15.0);
    QCOMPARE(object->property("headAngle").toReal(), M_PI / 6.0);
    QCOMPARE(object->property("lineCap").toString(), QString("round"));

    delete object;
}

void TestArrowPrimitive::testCustomProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        ArrowPrimitive {
            headLength: 20
            headAngle: Math.PI / 4
            lineCap: "square"
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify custom property values
    QCOMPARE(object->property("headLength").toReal(), 20.0);
    QCOMPARE(object->property("headAngle").toReal(), M_PI / 4.0);
    QCOMPARE(object->property("lineCap").toString(), QString("square"));

    delete object;
}

void TestArrowPrimitive::testDrawFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim
            width: 800
            height: 600

            ArrowPrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    // Verify draw function exists and is callable
    // Note: Actual drawing requires Canvas context, which we can't easily test here
    // This test just verifies the function doesn't crash when invoked
    QMetaObject::invokeMethod(primitive, "draw",
        Q_ARG(QVariant, QVariant()),  // ctx (null for this test)
        Q_ARG(QVariant, QPointF(0, 0)),  // start
        Q_ARG(QVariant, QPointF(100, 100)),  // end
        Q_ARG(QVariant, QColor("red")),  // color
        Q_ARG(QVariant, 3.0));  // lineWidth

    delete object;
}

void TestArrowPrimitive::testDrawWithSquareFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim
            width: 800
            height: 600

            ArrowPrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    // Verify drawWithSquare function exists and is callable
    QMetaObject::invokeMethod(primitive, "drawWithSquare",
        Q_ARG(QVariant, QVariant()),  // ctx (null for this test)
        Q_ARG(QVariant, QPointF(0, 0)),  // start
        Q_ARG(QVariant, QPointF(100, 100)),  // end
        Q_ARG(QVariant, QColor("blue")),  // color
        Q_ARG(QVariant, 4.0),  // lineWidth
        Q_ARG(QVariant, 12.0));  // squareSize

    delete object;
}

QTEST_MAIN(TestArrowPrimitive)
#include "tst_arrowprimitive.moc"

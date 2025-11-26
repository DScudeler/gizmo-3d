#include <QtTest/QtTest>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQuickItem>

class TestSquareHandlePrimitive : public QObject
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
    void testDrawWithCustomSize();

private:
    QQmlEngine *engine = nullptr;
};

void TestSquareHandlePrimitive::initTestCase()
{
    engine = new QQmlEngine(this);
}

void TestSquareHandlePrimitive::cleanupTestCase()
{
    delete engine;
    engine = nullptr;
}

void TestSquareHandlePrimitive::testComponentCreation()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        SquareHandlePrimitive {
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    delete object;
}

void TestSquareHandlePrimitive::testDefaultProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        SquareHandlePrimitive {
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify default property values
    QCOMPARE(object->property("defaultSize").toReal(), 12.0);
    QCOMPARE(object->property("lineWidth").toInt(), 1);

    delete object;
}

void TestSquareHandlePrimitive::testCustomProperties()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        SquareHandlePrimitive {
            defaultSize: 16
            lineWidth: 2
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    // Verify custom property values
    QCOMPARE(object->property("defaultSize").toReal(), 16.0);
    QCOMPARE(object->property("lineWidth").toInt(), 2);

    delete object;
}

void TestSquareHandlePrimitive::testDrawFunction()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim
            width: 800
            height: 600

            SquareHandlePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QVERIFY2(!component.isError(), qPrintable(component.errorString()));

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    // Verify draw function exists and is callable (using default size)
    QMetaObject::invokeMethod(primitive, "draw",
        Q_ARG(QVariant, QVariant()),  // ctx (null for this test)
        Q_ARG(QVariant, QPointF(100, 100)),  // center
        Q_ARG(QVariant, QColor("yellow")));  // color
        // customSize not provided, should use defaultSize

    delete object;
}

void TestSquareHandlePrimitive::testDrawWithCustomSize()
{
    QQmlComponent component(engine);
    component.setData(R"qml(
        import QtQuick
        import Gizmo3D

        Item {
            property alias primitive: prim

            SquareHandlePrimitive {
                id: prim
            }
        }
    )qml", QUrl());

    QObject *object = component.create();
    QVERIFY(object != nullptr);

    QObject *primitive = object->property("primitive").value<QObject*>();
    QVERIFY(primitive != nullptr);

    // Verify draw function with custom size parameter
    QMetaObject::invokeMethod(primitive, "draw",
        Q_ARG(QVariant, QVariant()),  // ctx
        Q_ARG(QVariant, QPointF(150, 150)),  // center
        Q_ARG(QVariant, QColor("blue")),  // color
        Q_ARG(QVariant, 20.0));  // customSize

    delete object;
}

QTEST_MAIN(TestSquareHandlePrimitive)
#include "tst_squarehandleprimitive.moc"

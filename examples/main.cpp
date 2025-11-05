#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Add QML import path for the Gizmo3D module
    engine.addImportPath(QStringLiteral("qrc:/qt/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + "/../src");

    const QUrl url(QStringLiteral("qrc:/qt/qml/Example/main.qml"));

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}

#include <QtQuickTest/quicktest.h>
#include <QQmlEngine>
#include <QCoreApplication>
#include <QtPlugin>

class GizmoTestSetup : public QObject
{
    Q_OBJECT

public slots:
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        // Add import path for the Gizmo3D module
        QString importPath = QCoreApplication::applicationDirPath() + "/../src";
        engine->addImportPath(importPath);

        qDebug() << "QML Test Setup: Added import path:" << importPath;
        qDebug() << "QML Test Setup: Import paths:" << engine->importPathList();
    }
};

QUICK_TEST_MAIN_WITH_SETUP(gizmo3d, GizmoTestSetup)
#include "tst_qml_main.moc"

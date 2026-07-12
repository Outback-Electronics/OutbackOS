#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include "SystemLauncher.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QGuiApplication::setDesktopFileName("outback-shell");
    QGuiApplication::setApplicationName("Outback");
    QGuiApplication::setOrganizationName("Outback Electronics");
    QGuiApplication::setOrganizationDomain("outbackelectronics.com.au");

    SystemLauncher launcher;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(
        "systemLauncher",
        &launcher
    );

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {
            QCoreApplication::exit(EXIT_FAILURE);
        },
        Qt::QueuedConnection
    );

    engine.load(
        QUrl(QStringLiteral(
            "qrc:/Outback/Shell/Main.qml"
        ))
    );

    return app.exec();
}

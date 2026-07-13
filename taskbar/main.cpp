#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include "LockBackend.h"
#include "SignalBridge.h"
#include "SystemLauncher.h"

int main(int argc, char *argv[])
{
    // Only the taskbar's own surface should become a wlr-layer-shell panel;
    // regular apps must stay ordinary xdg-shell toplevels, so this is set
    // here rather than session-wide.
    qputenv("QT_WAYLAND_SHELL_INTEGRATION", "layer-shell");

    QGuiApplication app(argc, argv);

    QGuiApplication::setApplicationName("Outback");
    QGuiApplication::setOrganizationName("Outback Electronics");
    QGuiApplication::setOrganizationDomain(
        "outbackelectronics.com.au"
    );

    SystemLauncher launcher;
    SignalBridge signalBridge;
    SignalBridge::writePidFile();
    LockBackend lockBackend;

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(
        "systemLauncher",
        &launcher
    );

    engine.rootContext()->setContextProperty(
        "signalBridge",
        &signalBridge
    );

    engine.rootContext()->setContextProperty(
        "lockBackend",
        &lockBackend
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
            "qrc:/Outback/Taskbar/Main.qml"
        ))
    );

    return app.exec();
}

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include "NotificationServer.h"
#include "SignalBridge.h"
#include "SystemBackend.h"
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
    SystemBackend systemBackend;
    SignalBridge signalBridge;
    SignalBridge::writePidFile();

    NotificationServer notificationServer;

    // Not fatal: if another notification daemon already owns the name,
    // Outback's panel simply stays empty rather than fighting over it.
    notificationServer.connectToBus();

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(
        "systemLauncher",
        &launcher
    );

    engine.rootContext()->setContextProperty(
        "systemBackend",
        &systemBackend
    );

    engine.rootContext()->setContextProperty(
        "notificationServer",
        &notificationServer
    );

    engine.rootContext()->setContextProperty(
        "signalBridge",
        &signalBridge
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

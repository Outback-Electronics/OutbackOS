#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QGuiApplication::setApplicationName("Outback");
    QGuiApplication::setOrganizationName("Outback Electronics");
    QGuiApplication::setOrganizationDomain(
        "outbackelectronics.com.au"
    );

    // Set by the labwc autostart script for the real boot sequence: play
    // once, fullscreen, borderless, then quit so the session can proceed to
    // the shell. Unset for local preview: windowed, loops, click/Space to
    // replay (see splash/Main.qml).
    const bool autoExit = qEnvironmentVariableIsSet("OUTBACK_SPLASH_AUTOEXIT");

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(
        QStringLiteral("autoExit"),
        autoExit
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
            "qrc:/Outback/Splash/Main.qml"
        ))
    );

    return app.exec();
}

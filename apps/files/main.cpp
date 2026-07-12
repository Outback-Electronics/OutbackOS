#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include "FilesBackend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QGuiApplication::setApplicationName("Outback");
    QGuiApplication::setOrganizationName("Outback Electronics");
    QGuiApplication::setOrganizationDomain(
        "outbackelectronics.com.au"
    );

    FilesBackend filesBackend;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(
        QStringLiteral("filesBackend"),
        &filesBackend
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
            "qrc:/Outback/Files/Main.qml"
        ))
    );

    return app.exec();
}

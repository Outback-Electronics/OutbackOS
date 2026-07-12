#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include <QtWebEngineQuick>

#include "BrowserBackend.h"

int main(int argc, char *argv[])
{
    // Hardened for zero background network activity: no safe-browsing pings,
    // no component/extension auto-update, no sync, no crash/metrics upload,
    // no search-suggestion or domain-reliability telemetry. Must be set
    // before QtWebEngineQuick::initialize()/QGuiApplication construction,
    // since Chromium reads its command line at process start.
    qputenv(
        "QTWEBENGINE_CHROMIUM_FLAGS",
        "--disable-background-networking "
        "--disable-component-update "
        "--disable-domain-reliability "
        "--disable-client-side-phishing-detection "
        "--disable-breakpad "
        "--disable-sync "
        "--no-pings "
        "--safebrowsing-disable-auto-update "
        "--disable-features=OptimizationHints,"
        "OptimizationGuideModelDownloading,MediaRouter,"
        "AutofillServerCommunication,Translate"
    );

    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);

    QGuiApplication::setApplicationName("Outback");
    QGuiApplication::setOrganizationName("Outback Electronics");
    QGuiApplication::setOrganizationDomain(
        "outbackelectronics.com.au"
    );

    BrowserBackend browserBackend;
    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty(
        QStringLiteral("browserBackend"),
        &browserBackend
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
            "qrc:/Outback/Browser/Main.qml"
        ))
    );

    return app.exec();
}

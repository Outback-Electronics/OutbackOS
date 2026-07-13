#include "NotificationsAdaptor.h"

#include "NotificationServer.h"

NotificationsAdaptor::NotificationsAdaptor(NotificationServer *server)
    : QDBusAbstractAdaptor(server)
    , m_server(server)
{
    connect(
        server,
        &NotificationServer::notificationClosed,
        this,
        [this](uint id, int reason) {
            emit NotificationClosed(id, static_cast<uint>(reason));
        }
    );

    connect(
        server,
        &NotificationServer::actionInvoked,
        this,
        [this](uint id, const QString &actionKey) {
            emit ActionInvoked(id, actionKey);
        }
    );
}

QStringList NotificationsAdaptor::GetCapabilities()
{
    return m_server->capabilities();
}

uint NotificationsAdaptor::Notify(
    const QString &app_name,
    uint replaces_id,
    const QString &app_icon,
    const QString &summary,
    const QString &body,
    const QStringList &actions,
    const QVariantMap &hints,
    int expire_timeout
)
{
    return m_server->notify(
        app_name,
        replaces_id,
        app_icon,
        summary,
        body,
        actions,
        hints,
        expire_timeout
    );
}

void NotificationsAdaptor::CloseNotification(uint id)
{
    m_server->closeNotification(
        id,
        NotificationServer::ClosedByCallReason
    );
}

void NotificationsAdaptor::GetServerInformation(
    QString &name,
    QString &vendor,
    QString &version,
    QString &spec_version
)
{
    name = QStringLiteral("Outback Notifications");
    vendor = QStringLiteral("Outback Electronics");
    version = QStringLiteral("0.1");
    spec_version = QStringLiteral("1.2");
}

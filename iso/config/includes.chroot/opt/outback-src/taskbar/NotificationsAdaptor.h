#pragma once

#include <QDBusAbstractAdaptor>
#include <QString>
#include <QStringList>
#include <QVariantMap>

class NotificationServer;

// Hand-written equivalent of what qdbusxml2cpp would generate for
// org.freedesktop.Notifications: translates the wire calls into
// NotificationServer calls, and re-exposes NotificationServer's Qt signals
// as the D-Bus signals the spec requires.
class NotificationsAdaptor final : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")

public:
    explicit NotificationsAdaptor(NotificationServer *server);

public slots:
    QStringList GetCapabilities();

    uint Notify(
        const QString &app_name,
        uint replaces_id,
        const QString &app_icon,
        const QString &summary,
        const QString &body,
        const QStringList &actions,
        const QVariantMap &hints,
        int expire_timeout
    );

    void CloseNotification(uint id);

    void GetServerInformation(
        QString &name,
        QString &vendor,
        QString &version,
        QString &spec_version
    );

signals:
    void NotificationClosed(uint id, uint reason);
    void ActionInvoked(uint id, const QString &action_key);

private:
    NotificationServer *m_server;
};

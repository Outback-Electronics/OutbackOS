#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QList>
#include <QString>
#include <QStringList>
#include <QVariantMap>

// Implements the org.freedesktop.Notifications D-Bus service (the
// "desktop notifications" spec that notify-send, browsers, NetworkManager,
// etc. all target) and doubles as the QAbstractListModel backing the
// taskbar's notification panel. There is no other notification daemon in
// Outback OS, so this is the only thing on the session bus answering that
// name.
//
// A toast (the transient popup) is a client-side concern: this class just
// emits toastRequested() for every arrival and lets NotificationToast.qml
// own the show/auto-hide timer. The persisted list underneath the panel is
// only ever trimmed by an explicit dismiss, CloseNotification over D-Bus, or
// the history cap - not by toast expiry - so the panel keeps working as a
// history you can catch up on later, the same way GNOME/Windows action
// centers do.
class NotificationServer final : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(
        int unreadCount
        READ unreadCount
        NOTIFY unreadCountChanged
    )

public:
    enum Role {
        IdRole = Qt::UserRole + 1,
        AppNameRole,
        SummaryRole,
        BodyRole,
        UrgencyRole,
        ActionsRole,
        TimestampRole
    };
    Q_ENUM(Role)

    enum CloseReason {
        ExpiredReason = 1,
        DismissedReason = 2,
        ClosedByCallReason = 3,
        UndefinedReason = 4
    };

    explicit NotificationServer(QObject *parent = nullptr);

    // Registers org.freedesktop.Notifications on the session bus. Returns
    // false (and leaves the model usable, just inert) if the name is
    // already taken by another daemon.
    bool connectToBus();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int unreadCount() const { return m_unreadCount; }

    Q_INVOKABLE void markAllRead();
    Q_INVOKABLE void dismissAt(int row);
    Q_INVOKABLE void dismissById(uint id);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void invokeAction(int row, const QString &actionKey);

    // Called by NotificationsAdaptor.
    uint notify(
        const QString &appName,
        uint replacesId,
        const QString &appIcon,
        const QString &summary,
        const QString &body,
        const QStringList &actions,
        const QVariantMap &hints,
        int expireTimeout
    );
    void closeNotification(uint id, CloseReason reason);
    QStringList capabilities() const;

signals:
    void countChanged();
    void unreadCountChanged();

    // For the transient popup. expireTimeoutMs is -1 when the sender left
    // it up to us (Toast.qml applies its own default in that case).
    void toastRequested(
        uint id,
        const QString &appName,
        const QString &summary,
        const QString &body,
        int urgency,
        int expireTimeoutMs
    );

    void notificationClosed(uint id, int reason);
    void actionInvoked(uint id, const QString &actionKey);

private:
    struct Entry {
        uint id = 0;
        QString appName;
        QString summary;
        QString body;
        QStringList actions;
        int urgency = 1;
        qint64 timestamp = 0;
    };

    int indexOfId(uint id) const;
    void removeAt(int row, CloseReason reason);

    QList<Entry> m_entries;
    uint m_nextId = 1;
    int m_unreadCount = 0;

    static constexpr int kHistoryCap = 50;
};

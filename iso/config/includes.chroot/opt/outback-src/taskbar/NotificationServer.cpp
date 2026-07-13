#include "NotificationServer.h"

#include <QDBusConnection>

#include "NotificationsAdaptor.h"

NotificationServer::NotificationServer(QObject *parent)
    : QAbstractListModel(parent)
{
    new NotificationsAdaptor(this);
}

bool NotificationServer::connectToBus()
{
    QDBusConnection bus = QDBusConnection::sessionBus();

    if (!bus.registerObject(
        QStringLiteral("/org/freedesktop/Notifications"),
        this,
        QDBusConnection::ExportAdaptors
    )) {
        return false;
    }

    return bus.registerService(
        QStringLiteral("org.freedesktop.Notifications")
    );
}

int NotificationServer::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return m_entries.size();
}

QVariant NotificationServer::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()
        || index.row() < 0
        || index.row() >= m_entries.size()) {
        return {};
    }

    const Entry &entry = m_entries.at(index.row());

    switch (role) {
    case IdRole:
        return entry.id;
    case AppNameRole:
        return entry.appName;
    case SummaryRole:
        return entry.summary;
    case BodyRole:
        return entry.body;
    case UrgencyRole:
        return entry.urgency;
    case ActionsRole:
        return entry.actions;
    case TimestampRole:
        return entry.timestamp;
    default:
        return {};
    }
}

QHash<int, QByteArray> NotificationServer::roleNames() const
{
    return {
        { IdRole, "notificationId" },
        { AppNameRole, "appName" },
        { SummaryRole, "summary" },
        { BodyRole, "body" },
        { UrgencyRole, "urgency" },
        { ActionsRole, "actions" },
        { TimestampRole, "timestamp" }
    };
}

void NotificationServer::markAllRead()
{
    if (m_unreadCount == 0) {
        return;
    }

    m_unreadCount = 0;
    emit unreadCountChanged();
}

void NotificationServer::dismissAt(int row)
{
    removeAt(row, DismissedReason);
}

void NotificationServer::dismissById(uint id)
{
    removeAt(indexOfId(id), DismissedReason);
}

void NotificationServer::clearAll()
{
    if (m_entries.isEmpty()) {
        return;
    }

    beginResetModel();

    const QList<Entry> closed = m_entries;
    m_entries.clear();

    endResetModel();
    emit countChanged();

    for (const Entry &entry : closed) {
        emit notificationClosed(entry.id, DismissedReason);
    }
}

void NotificationServer::invokeAction(int row, const QString &actionKey)
{
    if (row < 0 || row >= m_entries.size()) {
        return;
    }

    const uint id = m_entries.at(row).id;

    emit actionInvoked(id, actionKey);

    removeAt(row, DismissedReason);
}

uint NotificationServer::notify(
    const QString &appName,
    uint replacesId,
    const QString &appIcon,
    const QString &summary,
    const QString &body,
    const QStringList &actions,
    const QVariantMap &hints,
    int expireTimeout
)
{
    Q_UNUSED(appIcon)

    int urgency = 1;
    const QVariant urgencyHint = hints.value(QStringLiteral("urgency"));

    if (urgencyHint.isValid()) {
        urgency = qBound(0, urgencyHint.toInt(), 2);
    }

    Entry entry;
    entry.appName = appName.isEmpty()
        ? QStringLiteral("Application")
        : appName;
    entry.summary = summary;
    entry.body = body;
    entry.actions = actions;
    entry.urgency = urgency;
    entry.timestamp = QDateTime::currentSecsSinceEpoch();

    const int existingRow = replacesId != 0
        ? indexOfId(replacesId)
        : -1;

    if (existingRow >= 0) {
        entry.id = replacesId;

        m_entries[existingRow] = entry;

        const QModelIndex changed = index(existingRow);
        emit dataChanged(changed, changed);
    } else {
        entry.id = m_nextId++;

        beginInsertRows(QModelIndex(), 0, 0);
        m_entries.prepend(entry);
        endInsertRows();

        emit countChanged();

        while (m_entries.size() > kHistoryCap) {
            const int lastRow = m_entries.size() - 1;

            beginRemoveRows(QModelIndex(), lastRow, lastRow);
            m_entries.removeAt(lastRow);
            endRemoveRows();

            emit countChanged();
        }
    }

    ++m_unreadCount;
    emit unreadCountChanged();

    emit toastRequested(
        entry.id,
        entry.appName,
        entry.summary,
        entry.body,
        entry.urgency,
        expireTimeout
    );

    return entry.id;
}

void NotificationServer::closeNotification(uint id, CloseReason reason)
{
    const int row = indexOfId(id);

    if (row < 0) {
        return;
    }

    removeAt(row, reason);
}

QStringList NotificationServer::capabilities() const
{
    return {
        QStringLiteral("body"),
        QStringLiteral("actions"),
        QStringLiteral("persistence")
    };
}

int NotificationServer::indexOfId(uint id) const
{
    for (int i = 0; i < m_entries.size(); ++i) {
        if (m_entries.at(i).id == id) {
            return i;
        }
    }

    return -1;
}

void NotificationServer::removeAt(int row, CloseReason reason)
{
    if (row < 0 || row >= m_entries.size()) {
        return;
    }

    const uint id = m_entries.at(row).id;

    beginRemoveRows(QModelIndex(), row, row);
    m_entries.removeAt(row);
    endRemoveRows();

    emit countChanged();
    emit notificationClosed(id, reason);
}

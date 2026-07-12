#include "BrowserBackend.h"

#include <QSettings>
#include <QVariantMap>

BrowserBackend::BrowserBackend(QObject *parent)
    : QObject(parent)
{
}

QVariantList BrowserBackend::bookmarks() const
{
    QSettings settings;
    QVariantList result;

    const int count = settings.beginReadArray(QStringLiteral("bookmarks"));

    for (int i = 0; i < count; ++i) {
        settings.setArrayIndex(i);

        QVariantMap bookmark;
        bookmark.insert(
            QStringLiteral("title"),
            settings.value(QStringLiteral("title"))
        );
        bookmark.insert(
            QStringLiteral("url"),
            settings.value(QStringLiteral("url"))
        );

        result.append(bookmark);
    }

    settings.endArray();

    return result;
}

void BrowserBackend::addBookmark(
    const QString &title,
    const QString &url
)
{
    if (url.trimmed().isEmpty()) {
        return;
    }

    const QVariantList existing = bookmarks();

    for (const QVariant &entry : existing) {
        if (entry.toMap().value(QStringLiteral("url")).toString() == url) {
            return;
        }
    }

    QSettings settings;

    settings.beginWriteArray(QStringLiteral("bookmarks"));
    settings.setArrayIndex(existing.size());
    settings.setValue(QStringLiteral("title"), title);
    settings.setValue(QStringLiteral("url"), url);
    settings.endArray();
}

void BrowserBackend::removeBookmark(const QString &url)
{
    const QVariantList existing = bookmarks();

    QSettings settings;
    settings.remove(QStringLiteral("bookmarks"));

    settings.beginWriteArray(QStringLiteral("bookmarks"));

    int index = 0;

    for (const QVariant &entry : existing) {
        const QVariantMap map = entry.toMap();

        if (map.value(QStringLiteral("url")).toString() == url) {
            continue;
        }

        settings.setArrayIndex(index);
        settings.setValue(
            QStringLiteral("title"),
            map.value(QStringLiteral("title"))
        );
        settings.setValue(
            QStringLiteral("url"),
            map.value(QStringLiteral("url"))
        );

        ++index;
    }

    settings.endArray();
}

#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class BrowserBackend final : public QObject
{
    Q_OBJECT

public:
    explicit BrowserBackend(QObject *parent = nullptr);

    Q_INVOKABLE QVariantList bookmarks() const;
    Q_INVOKABLE void addBookmark(
        const QString &title,
        const QString &url
    );
    Q_INVOKABLE void removeBookmark(const QString &url);
};

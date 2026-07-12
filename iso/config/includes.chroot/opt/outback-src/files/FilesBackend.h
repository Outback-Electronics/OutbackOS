#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class FilesBackend final : public QObject
{
    Q_OBJECT

public:
    explicit FilesBackend(QObject *parent = nullptr);

    Q_INVOKABLE QString homePath() const;
    Q_INVOKABLE QString parentPath(const QString &path) const;
    Q_INVOKABLE QVariantList listDirectory(const QString &path) const;
    Q_INVOKABLE QVariantList listVolumes() const;

    Q_INVOKABLE bool createFolder(
        const QString &parentDir,
        const QString &name
    );
    Q_INVOKABLE bool renamePath(
        const QString &path,
        const QString &newName
    );
    Q_INVOKABLE bool moveToTrash(const QString &path);
    Q_INVOKABLE bool copyPath(
        const QString &source,
        const QString &destinationDir
    );
    Q_INVOKABLE bool movePath(
        const QString &source,
        const QString &destinationDir
    );

    Q_INVOKABLE bool ejectVolume(const QString &mountPoint);
};

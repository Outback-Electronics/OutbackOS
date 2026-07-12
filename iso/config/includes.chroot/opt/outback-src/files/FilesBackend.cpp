#include "FilesBackend.h"

#include "CommandRunner.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSet>
#include <QStorageInfo>
#include <QVariantMap>

FilesBackend::FilesBackend(QObject *parent)
    : QObject(parent)
{
}

QString FilesBackend::homePath() const
{
    return QDir::homePath();
}

QString FilesBackend::parentPath(const QString &path) const
{
    QDir dir(path);

    if (!dir.cdUp()) {
        return path;
    }

    return dir.absolutePath();
}

QVariantList FilesBackend::listDirectory(const QString &path) const
{
    QVariantList entries;

    QDir dir(path);
    dir.setFilter(
        QDir::AllEntries
        | QDir::NoDotAndDotDot
        | QDir::Hidden
    );
    dir.setSorting(QDir::DirsFirst | QDir::Name);

    for (const QFileInfo &info : dir.entryInfoList()) {
        QVariantMap entry;
        entry.insert(QStringLiteral("name"), info.fileName());
        entry.insert(QStringLiteral("path"), info.absoluteFilePath());
        entry.insert(QStringLiteral("isDir"), info.isDir());
        entry.insert(QStringLiteral("size"), info.size());
        entry.insert(
            QStringLiteral("modified"),
            info.lastModified()
        );
        entry.insert(
            QStringLiteral("isHidden"),
            info.fileName().startsWith(QLatin1Char('.'))
        );

        entries.append(entry);
    }

    return entries;
}

QVariantList FilesBackend::listVolumes() const
{
    QVariantList volumes;

    static const QSet<QString> pseudoFilesystems = {
        QStringLiteral("proc"),
        QStringLiteral("sysfs"),
        QStringLiteral("devtmpfs"),
        QStringLiteral("tmpfs"),
        QStringLiteral("devpts"),
        QStringLiteral("squashfs"),
        QStringLiteral("overlay"),
        QStringLiteral("cgroup2")
    };

    for (const QStorageInfo &storage : QStorageInfo::mountedVolumes()) {
        if (!storage.isValid() || !storage.isReady()) {
            continue;
        }

        if (pseudoFilesystems.contains(
            QString::fromUtf8(storage.fileSystemType())
        )) {
            continue;
        }

        QVariantMap volume;
        volume.insert(
            QStringLiteral("name"),
            storage.displayName()
        );
        volume.insert(
            QStringLiteral("path"),
            storage.rootPath()
        );
        volume.insert(
            QStringLiteral("device"),
            QString::fromUtf8(storage.device())
        );
        volume.insert(
            QStringLiteral("bytesTotal"),
            storage.bytesTotal()
        );
        volume.insert(
            QStringLiteral("bytesAvailable"),
            storage.bytesAvailable()
        );
        volume.insert(
            QStringLiteral("isRoot"),
            storage.rootPath() == QStringLiteral("/")
        );

        volumes.append(volume);
    }

    return volumes;
}

bool FilesBackend::createFolder(
    const QString &parentDir,
    const QString &name
)
{
    if (name.trimmed().isEmpty()) {
        return false;
    }

    return QDir(parentDir).mkdir(name);
}

bool FilesBackend::renamePath(
    const QString &path,
    const QString &newName
)
{
    if (newName.trimmed().isEmpty()) {
        return false;
    }

    QFileInfo info(path);
    const QString destination =
        info.absoluteDir().filePath(newName);

    return QFile::rename(path, destination);
}

bool FilesBackend::moveToTrash(const QString &path)
{
    return QFile::moveToTrash(path);
}

bool FilesBackend::copyPath(
    const QString &source,
    const QString &destinationDir
)
{
    const QFileInfo info(source);
    const QString destination =
        QDir(destinationDir).filePath(info.fileName());

    if (info.isDir()) {
        QDir sourceDir(source);
        QDir().mkpath(destination);

        for (const QFileInfo &child : sourceDir.entryInfoList(
            QDir::AllEntries | QDir::NoDotAndDotDot | QDir::Hidden
        )) {
            if (!copyPath(child.absoluteFilePath(), destination)) {
                return false;
            }
        }

        return true;
    }

    return QFile::copy(source, destination);
}

bool FilesBackend::movePath(
    const QString &source,
    const QString &destinationDir
)
{
    const QFileInfo info(source);
    const QString destination =
        QDir(destinationDir).filePath(info.fileName());

    return QFile::rename(source, destination);
}

bool FilesBackend::ejectVolume(const QString &mountPoint)
{
    const QString device = QStorageInfo(mountPoint).device();

    if (device.isEmpty()) {
        return false;
    }

    const auto unmount = CommandRunner::run(
        QStringLiteral("udisksctl"),
        {
            QStringLiteral("unmount"),
            QStringLiteral("-b"),
            device
        }
    );

    if (!unmount.succeeded()) {
        return false;
    }

    CommandRunner::run(
        QStringLiteral("udisksctl"),
        {
            QStringLiteral("power-off"),
            QStringLiteral("-b"),
            device
        }
    );

    return true;
}

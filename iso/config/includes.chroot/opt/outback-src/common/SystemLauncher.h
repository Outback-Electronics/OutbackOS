#pragma once

#include <QObject>
#include <QString>

class SystemLauncher final : public QObject
{
    Q_OBJECT

public:
    explicit SystemLauncher(QObject *parent = nullptr);

    Q_INVOKABLE bool launch(const QString &program);
    Q_INVOKABLE bool launchInstaller();
    Q_INVOKABLE bool isInstallerAvailable() const;
    Q_INVOKABLE bool reboot();
    Q_INVOKABLE bool shutdown();
    Q_INVOKABLE bool signOut();
};

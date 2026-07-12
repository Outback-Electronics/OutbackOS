#pragma once

#include <QObject>
#include <QString>

class SystemLauncher final : public QObject
{
    Q_OBJECT

public:
    explicit SystemLauncher(QObject *parent = nullptr);

    Q_INVOKABLE bool launch(const QString &program);
};

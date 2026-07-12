#include "SystemLauncher.h"

#include <QProcess>

SystemLauncher::SystemLauncher(QObject *parent)
    : QObject(parent)
{
}

bool SystemLauncher::launch(const QString &program)
{
    if (program.trimmed().isEmpty()) {
        return false;
    }

    return QProcess::startDetached(program);
}

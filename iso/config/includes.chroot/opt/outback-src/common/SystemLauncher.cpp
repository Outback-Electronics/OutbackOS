#include "SystemLauncher.h"

#include <QFileInfo>
#include <QProcess>
#include <QProcessEnvironment>

SystemLauncher::SystemLauncher(QObject *parent)
    : QObject(parent)
{
}

bool SystemLauncher::launch(const QString &program)
{
    if (program.trimmed().isEmpty()) {
        return false;
    }

    // outback-taskbar sets QT_WAYLAND_SHELL_INTEGRATION=layer-shell on
    // itself so its own window renders as a Wayland layer-shell panel, but
    // that's a process-wide env var, and QProcess inherits it by default.
    // Without stripping it, apps launched from the taskbar (pinned icons,
    // the start menu) would also try to open as layer-shell surfaces
    // instead of ordinary xdg-shell toplevels, which have no decoration,
    // no resize, and no close/minimize/maximize.
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.remove(QStringLiteral("QT_WAYLAND_SHELL_INTEGRATION"));

    QProcess process;
    process.setProgram(program);
    process.setProcessEnvironment(env);

    return process.startDetached();
}

bool SystemLauncher::isInstallerAvailable() const
{
    return QFileInfo::exists(QStringLiteral("/usr/bin/calamares"));
}

bool SystemLauncher::launchInstaller()
{
    const auto env = QProcessEnvironment::systemEnvironment();

    return QProcess::startDetached(
        QStringLiteral("pkexec"),
        {
            QStringLiteral("/usr/bin/outback-launch-calamares"),
            env.value(QStringLiteral("XDG_RUNTIME_DIR")),
            env.value(QStringLiteral("WAYLAND_DISPLAY"))
        }
    );
}

bool SystemLauncher::reboot()
{
    return QProcess::startDetached(
        QStringLiteral("systemctl"),
        {
            QStringLiteral("reboot")
        }
    );
}

bool SystemLauncher::shutdown()
{
    return QProcess::startDetached(
        QStringLiteral("systemctl"),
        {
            QStringLiteral("poweroff")
        }
    );
}

bool SystemLauncher::signOut()
{
    const auto env = QProcessEnvironment::systemEnvironment();
    const QString sessionId = env.value(QStringLiteral("XDG_SESSION_ID"));

    if (sessionId.isEmpty()) {
        return false;
    }

    return QProcess::startDetached(
        QStringLiteral("loginctl"),
        {
            QStringLiteral("terminate-session"),
            sessionId
        }
    );
}

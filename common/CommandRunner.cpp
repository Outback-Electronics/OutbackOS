#include "CommandRunner.h"

#include <QProcess>

namespace CommandRunner {

CommandResult run(
    const QString &program,
    const QStringList &arguments
)
{
    QProcess process;

    process.start(program, arguments);

    if (!process.waitForStarted(5000)) {
        return {
            -1,
            {},
            QStringLiteral("Could not start %1").arg(program)
        };
    }

    if (!process.waitForFinished(30000)) {
        process.kill();
        process.waitForFinished();

        return {
            -1,
            QString::fromUtf8(process.readAllStandardOutput()).trimmed(),
            QStringLiteral("Command timed out")
        };
    }

    return {
        process.exitCode(),
        QString::fromUtf8(process.readAllStandardOutput()).trimmed(),
        QString::fromUtf8(process.readAllStandardError()).trimmed()
    };
}

} // namespace CommandRunner

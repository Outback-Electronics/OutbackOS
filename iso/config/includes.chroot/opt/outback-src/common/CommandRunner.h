#pragma once

#include <QString>
#include <QStringList>

struct CommandResult {
    int exitCode = -1;
    QString standardOutput;
    QString standardError;

    bool succeeded() const
    {
        return exitCode == 0;
    }
};

namespace CommandRunner {

CommandResult run(
    const QString &program,
    const QStringList &arguments = {}
);

} // namespace CommandRunner

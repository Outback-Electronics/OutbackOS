#include "PtySession.h"

#include <QSocketNotifier>

#include <csignal>
#include <cstdlib>
#include <pty.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

PtySession::PtySession(QObject *parent)
    : QObject(parent)
{
}

PtySession::~PtySession()
{
    if (m_childPid > 0) {
        ::kill(m_childPid, SIGHUP);
    }

    if (m_masterFd >= 0) {
        ::close(m_masterFd);
    }
}

bool PtySession::start(int columns, int rows)
{
    struct winsize windowSize {};
    windowSize.ws_col = static_cast<unsigned short>(columns);
    windowSize.ws_row = static_cast<unsigned short>(rows);

    const pid_t pid = forkpty(&m_masterFd, nullptr, nullptr, &windowSize);

    if (pid < 0) {
        return false;
    }

    if (pid == 0) {
        const char *shell = std::getenv("SHELL");

        if (!shell || shell[0] == '\0') {
            shell = "/bin/bash";
        }

        ::execl(shell, shell, static_cast<char *>(nullptr));
        ::_exit(127);
    }

    m_childPid = pid;

    m_notifier = new QSocketNotifier(
        m_masterFd,
        QSocketNotifier::Read,
        this
    );

    connect(
        m_notifier,
        &QSocketNotifier::activated,
        this,
        &PtySession::readMaster
    );

    return true;
}

void PtySession::readMaster()
{
    char buffer[4096];
    const ssize_t bytesRead = ::read(m_masterFd, buffer, sizeof(buffer));

    if (bytesRead <= 0) {
        m_notifier->setEnabled(false);
        emit finished();
        return;
    }

    emit dataReceived(QByteArray(buffer, static_cast<int>(bytesRead)));
}

void PtySession::write(const QByteArray &data)
{
    if (m_masterFd < 0) {
        return;
    }

    ::write(m_masterFd, data.constData(), static_cast<size_t>(data.size()));
}

void PtySession::resize(int columns, int rows)
{
    if (m_masterFd < 0) {
        return;
    }

    struct winsize windowSize {};
    windowSize.ws_col = static_cast<unsigned short>(columns);
    windowSize.ws_row = static_cast<unsigned short>(rows);

    ::ioctl(m_masterFd, TIOCSWINSZ, &windowSize);
}

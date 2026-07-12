#include "SignalBridge.h"

#include <QFile>
#include <QSocketNotifier>
#include <QString>
#include <QTextStream>

#include <cstring>
#include <signal.h>
#include <sys/socket.h>
#include <unistd.h>

int SignalBridge::s_socketPair[2] = {-1, -1};

SignalBridge::SignalBridge(QObject *parent)
    : QObject(parent)
{
    if (::socketpair(AF_UNIX, SOCK_STREAM, 0, s_socketPair) != 0) {
        return;
    }

    m_notifier = new QSocketNotifier(
        s_socketPair[1],
        QSocketNotifier::Read,
        this
    );

    connect(
        m_notifier,
        &QSocketNotifier::activated,
        this,
        &SignalBridge::handleSignal
    );

    struct sigaction action;
    std::memset(&action, 0, sizeof(action));
    action.sa_handler = &SignalBridge::unixSignalHandler;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;
    sigaction(SIGUSR1, &action, nullptr);
}

SignalBridge::~SignalBridge()
{
    if (s_socketPair[0] >= 0) {
        ::close(s_socketPair[0]);
    }

    if (s_socketPair[1] >= 0) {
        ::close(s_socketPair[1]);
    }
}

bool SignalBridge::writePidFile()
{
    QString runtimeDir = QString::fromLocal8Bit(qgetenv("XDG_RUNTIME_DIR"));

    if (runtimeDir.isEmpty()) {
        runtimeDir = QStringLiteral("/tmp");
    }

    QFile pidFile(runtimeDir + QStringLiteral("/outback-taskbar.pid"));

    if (!pidFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return false;
    }

    QTextStream stream(&pidFile);
    stream << QString::number(getpid());

    return true;
}

void SignalBridge::unixSignalHandler(int signum)
{
    Q_UNUSED(signum);

    const char byte = 1;
    ::write(s_socketPair[0], &byte, sizeof(byte));
}

void SignalBridge::handleSignal()
{
    char byte;
    ::read(s_socketPair[1], &byte, sizeof(byte));

    emit toggleStartMenuRequested();
}

#pragma once

#include <QObject>

class QSocketNotifier;

// Lets the compositor's Super-key keybind (which can only run a shell
// command, not call into a running process) ask the already-running
// taskbar to toggle its start menu, by sending SIGUSR1 to its pid. Unix
// signal handlers can only safely write to an async-signal-safe function
// (write(2) here), so the handler writes a byte to a socketpair and a
// QSocketNotifier picks it up back on the Qt event loop, where emitting
// a signal is safe.
class SignalBridge final : public QObject
{
    Q_OBJECT

public:
    explicit SignalBridge(QObject *parent = nullptr);
    ~SignalBridge() override;

    static bool writePidFile();

signals:
    void toggleStartMenuRequested();

private slots:
    void handleSignal();

private:
    static void unixSignalHandler(int signum);

    static int s_socketPair[2];

    QSocketNotifier *m_notifier = nullptr;
};

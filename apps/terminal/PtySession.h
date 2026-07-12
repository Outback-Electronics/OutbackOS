#pragma once

#include <QByteArray>
#include <QObject>

#include <sys/types.h>

class QSocketNotifier;

class PtySession final : public QObject
{
    Q_OBJECT

public:
    explicit PtySession(QObject *parent = nullptr);
    ~PtySession() override;

    bool start(int columns, int rows);
    void write(const QByteArray &data);
    void resize(int columns, int rows);

signals:
    void dataReceived(const QByteArray &data);
    void finished();

private:
    void readMaster();

    int m_masterFd = -1;
    pid_t m_childPid = -1;
    QSocketNotifier *m_notifier = nullptr;
};

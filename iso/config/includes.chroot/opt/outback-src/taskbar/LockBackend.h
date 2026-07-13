#pragma once

#include <QObject>
#include <QString>

// Authenticates the lock screen's password field against the same local
// account used to auto-login the session, via the system's normal PAM
// stack (see /etc/pam.d/outback-lockscreen). This runs unprivileged: PAM's
// unix module shells out to the suid unix_chkpwd helper internally to read
// the shadow file, the same way "login" or "su" do.
class LockBackend final : public QObject
{
    Q_OBJECT

public:
    explicit LockBackend(QObject *parent = nullptr);

    Q_INVOKABLE bool authenticate(const QString &password);
};

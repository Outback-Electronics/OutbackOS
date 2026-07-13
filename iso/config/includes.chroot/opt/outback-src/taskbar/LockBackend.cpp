#include "LockBackend.h"

#include <QByteArray>

#include <cstdlib>
#include <cstring>
#include <pwd.h>
#include <security/pam_appl.h>
#include <unistd.h>

namespace {

struct PamConversationData {
    const char *password = nullptr;
};

int pamConversation(
    int numMessages,
    const struct pam_message **messages,
    struct pam_response **responses,
    void *appDataPtr
)
{
    if (numMessages <= 0) {
        return PAM_CONV_ERR;
    }

    auto *reply = static_cast<struct pam_response *>(
        std::calloc(
            static_cast<std::size_t>(numMessages),
            sizeof(struct pam_response)
        )
    );

    if (!reply) {
        return PAM_BUF_ERR;
    }

    const auto *data = static_cast<PamConversationData *>(appDataPtr);

    for (int i = 0; i < numMessages; ++i) {
        switch (messages[i]->msg_style) {
        case PAM_PROMPT_ECHO_OFF:
        case PAM_PROMPT_ECHO_ON:
            reply[i].resp = strdup(data->password ? data->password : "");
            reply[i].resp_retcode = 0;
            break;
        default:
            reply[i].resp = nullptr;
            reply[i].resp_retcode = 0;
            break;
        }
    }

    *responses = reply;
    return PAM_SUCCESS;
}

QString currentUserName()
{
    const struct passwd *entry = ::getpwuid(::geteuid());
    return entry ? QString::fromLocal8Bit(entry->pw_name) : QString();
}

} // namespace

LockBackend::LockBackend(QObject *parent)
    : QObject(parent)
{
}

bool LockBackend::authenticate(const QString &password)
{
    const QString userName = currentUserName();

    if (userName.isEmpty()) {
        return false;
    }

    const QByteArray passwordBytes = password.toUtf8();
    PamConversationData data{passwordBytes.constData()};

    struct pam_conv conv;
    conv.conv = &pamConversation;
    conv.appdata_ptr = &data;

    pam_handle_t *handle = nullptr;
    const QByteArray userNameBytes = userName.toLocal8Bit();

    int result = pam_start(
        "outback-lockscreen",
        userNameBytes.constData(),
        &conv,
        &handle
    );

    if (result != PAM_SUCCESS || !handle) {
        return false;
    }

    result = pam_authenticate(handle, 0);

    const bool success = (result == PAM_SUCCESS);

    pam_end(handle, result);

    return success;
}

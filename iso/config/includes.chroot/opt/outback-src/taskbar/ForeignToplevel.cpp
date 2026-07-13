#include "ForeignToplevel.h"

#include <QGuiApplication>

#include <cstring>

ForeignToplevel::ForeignToplevel(struct ::zwlr_foreign_toplevel_handle_v1 *object, QObject *parent)
    : QObject(parent)
    , QtWayland::zwlr_foreign_toplevel_handle_v1(object)
{
}

ForeignToplevel::~ForeignToplevel()
{
    if (isInitialized())
        destroy();
}

void ForeignToplevel::requestActivate()
{
    auto *waylandApp = qGuiApp->nativeInterface<QNativeInterface::QWaylandApplication>();
    struct ::wl_seat *seat = waylandApp ? waylandApp->lastInputSeat() : nullptr;
    if (!seat)
        return;

    if (m_minimized)
        unset_minimized();

    activate(seat);
}

void ForeignToplevel::requestClose()
{
    close();
}

void ForeignToplevel::requestToggleMinimize()
{
    if (m_minimized) {
        requestActivate();
    } else if (m_activated) {
        set_minimized();
    } else {
        requestActivate();
    }
}

void ForeignToplevel::requestToggleMaximize()
{
    if (m_maximized) {
        unset_maximized();
    } else {
        set_maximized();
    }
}

void ForeignToplevel::zwlr_foreign_toplevel_handle_v1_title(const QString &title)
{
    if (m_title == title)
        return;
    m_title = title;
    emit titleChanged();
}

void ForeignToplevel::zwlr_foreign_toplevel_handle_v1_app_id(const QString &app_id)
{
    if (m_appId == app_id)
        return;
    m_appId = app_id;
    emit appIdChanged();
}

void ForeignToplevel::zwlr_foreign_toplevel_handle_v1_state(const QByteArray &state)
{
    // The wire format is a densely packed array of uint32_t entries, each
    // one a zwlr_foreign_toplevel_handle_v1::state enum value. Wayland never
    // crosses machine boundaries, so no byte-swapping is needed.
    m_pendingActivated = false;
    m_pendingMinimized = false;
    m_pendingMaximized = false;

    uint32_t value = 0;
    for (qsizetype offset = 0; offset + qsizetype(sizeof(value)) <= state.size(); offset += sizeof(value)) {
        std::memcpy(&value, state.constData() + offset, sizeof(value));

        switch (value) {
        case state_maximized:
            m_pendingMaximized = true;
            break;
        case state_minimized:
            m_pendingMinimized = true;
            break;
        case state_activated:
            m_pendingActivated = true;
            break;
        default:
            break;
        }
    }
}

void ForeignToplevel::zwlr_foreign_toplevel_handle_v1_done()
{
    const bool changed = m_activated != m_pendingActivated
        || m_minimized != m_pendingMinimized
        || m_maximized != m_pendingMaximized;

    m_activated = m_pendingActivated;
    m_minimized = m_pendingMinimized;
    m_maximized = m_pendingMaximized;

    if (changed)
        emit stateChanged();
}

void ForeignToplevel::zwlr_foreign_toplevel_handle_v1_closed()
{
    emit closed();
}

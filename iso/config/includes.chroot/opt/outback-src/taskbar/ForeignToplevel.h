#pragma once

#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>

#include "qwayland-wlr-foreign-toplevel-management-unstable-v1.h"

// Wraps a single zwlr_foreign_toplevel_handle_v1: one open window on the
// system, regardless of which process created it. Instances are created by
// ToplevelManager in response to the manager's "toplevel" event and are not
// meant to be constructed directly from QML.
class ForeignToplevel : public QObject, public QtWayland::zwlr_foreign_toplevel_handle_v1
{
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(QString title READ title NOTIFY titleChanged)
    Q_PROPERTY(QString appId READ appId NOTIFY appIdChanged)
    Q_PROPERTY(bool activated READ isActivated NOTIFY stateChanged)
    Q_PROPERTY(bool minimized READ isMinimized NOTIFY stateChanged)
    Q_PROPERTY(bool maximized READ isMaximized NOTIFY stateChanged)

public:
    explicit ForeignToplevel(struct ::zwlr_foreign_toplevel_handle_v1 *object, QObject *parent = nullptr);
    ~ForeignToplevel() override;

    QString title() const { return m_title; }
    QString appId() const { return m_appId; }
    bool isActivated() const { return m_activated; }
    bool isMinimized() const { return m_minimized; }
    bool isMaximized() const { return m_maximized; }

    // Bring this window to the front. If it is currently minimized, it is
    // restored first, since a bare "activate" request does not imply that.
    Q_INVOKABLE void requestActivate();
    Q_INVOKABLE void requestClose();
    Q_INVOKABLE void requestToggleMinimize();

signals:
    void titleChanged();
    void appIdChanged();
    void stateChanged();
    // Emitted right before this object is deleted, once the compositor has
    // confirmed the window is gone.
    void closed();

protected:
    void zwlr_foreign_toplevel_handle_v1_title(const QString &title) override;
    void zwlr_foreign_toplevel_handle_v1_app_id(const QString &app_id) override;
    void zwlr_foreign_toplevel_handle_v1_state(struct wl_array *state) override;
    void zwlr_foreign_toplevel_handle_v1_done() override;
    void zwlr_foreign_toplevel_handle_v1_closed() override;

private:
    QString m_title;
    QString m_appId;
    bool m_activated = false;
    bool m_minimized = false;
    bool m_maximized = false;

    // Staged by the state event, applied atomically on "done" per protocol.
    bool m_pendingActivated = false;
    bool m_pendingMinimized = false;
    bool m_pendingMaximized = false;
};

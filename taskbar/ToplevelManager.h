#pragma once

#include <QList>
#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>
#include <QtWaylandClient/QWaylandClientExtension>

#include "qwayland-wlr-foreign-toplevel-management-unstable-v1.h"

class ForeignToplevel;

// Binds to the zwlr_foreign_toplevel_manager_v1 global (if the compositor
// advertises it) and keeps a live list of every open window on the system,
// across all processes. This is what makes a real taskbar possible: it does
// not depend on Outback's own launcher knowing what it started.
class ToplevelManager : public QWaylandClientExtensionTemplate<ToplevelManager>
        , public QtWayland::zwlr_foreign_toplevel_manager_v1
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QList<QObject *> toplevels READ toplevels NOTIFY toplevelsChanged)

public:
    explicit ToplevelManager(QObject *parent = nullptr);
    ~ToplevelManager() override;

    QList<QObject *> toplevels() const;

signals:
    void toplevelsChanged();

protected:
    void zwlr_foreign_toplevel_manager_v1_toplevel(struct ::zwlr_foreign_toplevel_handle_v1 *toplevel) override;
    void zwlr_foreign_toplevel_manager_v1_finished() override;

private slots:
    void handleToplevelClosed();

private:
    QList<ForeignToplevel *> m_toplevels;
};

#include "ToplevelManager.h"
#include "ForeignToplevel.h"

ToplevelManager::ToplevelManager(QObject *parent)
    : QWaylandClientExtensionTemplate(3)
{
    Q_UNUSED(parent);
}

ToplevelManager::~ToplevelManager()
{
    qDeleteAll(m_toplevels);
}

QList<QObject *> ToplevelManager::toplevels() const
{
    QList<QObject *> result;
    result.reserve(m_toplevels.size());
    for (ForeignToplevel *toplevel : m_toplevels)
        result.append(toplevel);
    return result;
}

void ToplevelManager::zwlr_foreign_toplevel_manager_v1_toplevel(struct ::zwlr_foreign_toplevel_handle_v1 *toplevel)
{
    auto *wrapped = new ForeignToplevel(toplevel, this);
    connect(wrapped, &ForeignToplevel::closed, this, &ToplevelManager::handleToplevelClosed);

    m_toplevels.append(wrapped);
    emit toplevelsChanged();
}

void ToplevelManager::zwlr_foreign_toplevel_manager_v1_finished()
{
    // The compositor does not support this global (or has withdrawn it);
    // nothing more will ever be reported. The taskbar simply shows an empty
    // window list in that case.
}

void ToplevelManager::handleToplevelClosed()
{
    auto *closedToplevel = qobject_cast<ForeignToplevel *>(sender());
    if (!closedToplevel)
        return;

    if (m_toplevels.removeOne(closedToplevel)) {
        emit toplevelsChanged();
        closedToplevel->deleteLater();
    }
}

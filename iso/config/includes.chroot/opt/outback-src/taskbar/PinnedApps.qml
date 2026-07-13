pragma Singleton
import QtQuick
import Qt.labs.settings

// Persists which Apps.qml entries are pinned to the taskbar. Stored as a
// JSON array of app ids rather than separate indexed Settings properties
// since the pinned set is variable-length. The default (for anyone who has
// never pinned/unpinned anything) mirrors Apps.qml's own "pinned" flags,
// so it stays in sync with whatever Outback OS ships pinned by default.
QtObject {
    id: root

    readonly property var pinnedIds: parseIds(prefs.pinnedJson)

    property Settings prefs: Settings {
        category: "taskbar"
        property string pinnedJson: JSON.stringify(
            Apps.entries
                .filter(function (app) { return app.pinned })
                .map(function (app) { return app.id })
        )
    }

    function parseIds(json) {
        try {
            const parsed = JSON.parse(json)
            return Array.isArray(parsed) ? parsed : []
        } catch (error) {
            return []
        }
    }

    function isPinned(appId) {
        return root.pinnedIds.indexOf(appId) !== -1
    }

    function pin(appId) {
        if (isPinned(appId)) {
            return
        }

        prefs.pinnedJson = JSON.stringify(
            root.pinnedIds.concat([appId])
        )
    }

    function unpin(appId) {
        if (!isPinned(appId)) {
            return
        }

        prefs.pinnedJson = JSON.stringify(
            root.pinnedIds.filter(function (id) {
                return id !== appId
            })
        )
    }

    function toggle(appId) {
        if (isPinned(appId)) {
            unpin(appId)
        } else {
            pin(appId)
        }
    }
}

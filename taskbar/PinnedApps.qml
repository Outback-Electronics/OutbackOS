pragma Singleton
import QtQuick
import Qt.labs.settings

// Persists which AppCatalog entries are pinned to the taskbar. Stored as a
// JSON array of app ids rather than separate indexed Settings properties
// since the pinned set is variable-length.
QtObject {
    id: root

    readonly property var pinnedIds: parseIds(prefs.pinnedJson)

    property Settings prefs: Settings {
        category: "taskbar"
        property string pinnedJson: '["terminal","files"]'
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

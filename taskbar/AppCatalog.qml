pragma Singleton
import QtQuick

// The full set of apps Outback OS ships. There is no desktop-entry/.desktop
// scanning yet, so this stands in for one - it is what both the start
// menu's app list and the taskbar's pin/unpin feature enumerate against.
QtObject {
    readonly property var apps: [
        {
            id: "terminal",
            symbol: "T",
            label: "Terminal",
            command: "/usr/bin/outback-terminal"
        },
        {
            id: "files",
            symbol: "F",
            label: "Files",
            command: "/usr/bin/outback-files"
        },
        {
            id: "browser",
            symbol: "B",
            label: "Browser",
            command: "/usr/bin/outback-browser"
        },
        {
            id: "settings",
            symbol: "S",
            label: "Settings",
            command: "/usr/bin/outback-settings"
        }
    ]

    function byId(appId) {
        for (let i = 0; i < apps.length; i++) {
            if (apps[i].id === appId) {
                return apps[i]
            }
        }

        return null
    }

    // Matches a running window's Wayland app_id (e.g. "outback-terminal")
    // against a catalog entry's launch command (".../outback-terminal") so
    // the window-list context menu can offer "Pin to taskbar" for windows
    // belonging to apps Outback OS actually ships.
    function byAppId(waylandAppId) {
        if (!waylandAppId) {
            return null
        }

        for (let i = 0; i < apps.length; i++) {
            if (apps[i].command.endsWith("/" + waylandAppId)) {
                return apps[i]
            }
        }

        return null
    }
}

pragma Singleton
import QtQuick

// Single source of truth for installed apps: the taskbar's pinned buttons
// and the start menu's all-apps list both read from here, so wiring up a
// new app means adding one entry instead of editing two files.
QtObject {
    readonly property var entries: [
        {
            id: "settings",
            label: "Settings",
            icon: "icons/gear.svg",
            command: "/usr/bin/outback-settings",
            accent: "#3FA7D6",
            pinned: false
        },
        {
            id: "browser",
            label: "Browser",
            icon: "icons/globe.svg",
            command: "/usr/bin/outback-browser",
            accent: "#4C9F70",
            pinned: false
        },
        {
            id: "terminal",
            label: "Terminal",
            icon: "icons/terminal.svg",
            command: "/usr/bin/outback-terminal",
            accent: "#D9732F",
            pinned: true
        },
        {
            id: "files",
            label: "Files",
            icon: "icons/folder.svg",
            command: "/usr/bin/outback-files",
            accent: "#9B6FD1",
            pinned: true
        }
    ]

    function byId(appId) {
        for (let i = 0; i < entries.length; i++) {
            if (entries[i].id === appId) {
                return entries[i]
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

        for (let i = 0; i < entries.length; i++) {
            if (entries[i].command.endsWith("/" + waylandAppId)) {
                return entries[i]
            }
        }

        return null
    }
}

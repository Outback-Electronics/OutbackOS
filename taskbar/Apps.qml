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
            symbol: "S",
            command: "/usr/bin/outback-settings",
            accent: "#3FA7D6",
            pinned: false
        },
        {
            id: "browser",
            label: "Browser",
            symbol: "B",
            command: "/usr/bin/outback-browser",
            accent: "#4C9F70",
            pinned: false
        },
        {
            id: "terminal",
            label: "Terminal",
            symbol: "T",
            command: "/usr/bin/outback-terminal",
            accent: "#D9732F",
            pinned: true
        },
        {
            id: "files",
            label: "Files",
            symbol: "F",
            command: "/usr/bin/outback-files",
            accent: "#9B6FD1",
            pinned: true
        }
    ]
}

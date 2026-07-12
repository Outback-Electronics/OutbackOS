pragma Singleton
import QtQuick
import Qt.labs.settings

// Central colour palette so every taskbar flyout (start menu, quick
// settings, notifications, calendar) agrees on the same look without each
// one needing the five colour properties threaded in as required
// properties.
QtObject {
    id: theme

    readonly property color surface: "#1B2229"
    readonly property color surfaceRaised: "#252E36"
    readonly property color textPrimary: "#F4F6F7"
    readonly property color textSecondary: "#AEB8C0"
    readonly property var accentColours: ["#D9732F", "#3FA7D6", "#4C9F70"]
    readonly property color primary: accentColours[prefs.accentIndex]

    property Settings prefs: Settings {
        category: "appearance"
        property int accentIndex: 0
    }
}

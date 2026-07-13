import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.settings

ApplicationWindow {
    id: root

    visible: true
    // Maximized rather than FullScreen: on wlroots compositors (labwc) a
    // true fullscreen surface is stacked above the layer-shell "top" layer,
    // which would hide the always-on-top taskbar behind the desktop
    // whenever it regains focus (e.g. after closing/minimising every app).
    // Maximized respects the taskbar's reserved exclusion zone instead.
    visibility: Window.Maximized

    // The desktop shell is not an application: it must never present the
    // usual title bar / iconify / maximize / close chrome, and it must
    // never actually close short of a shutdown or restart (see onClosing
    // below). FramelessWindowHint stops Qt requesting server-side
    // decoration from labwc at all, the same way taskbar/Main.qml and
    // splash/Main.qml opt out of it.
    flags: Qt.FramelessWindowHint

    title: "Outback OS"

    minimumWidth: 1024
    minimumHeight: 600

    color: "#101418"

    // Belt and braces: even without decoration there are other ways a
    // close request can reach this window (Alt+F4, the window switcher,
    // a stray wlr-foreign-toplevel close request). Refuse all of them —
    // the only way out is Shut Down / Restart below, which end the
    // session directly rather than closing this window.
    onClosing: (close) => {
        close.accepted = false
    }

    property color surface: "#1B2229"
    property color surfaceRaised: "#252E36"
    property color primary: accentColours[prefs.accentIndex]
    property color textPrimary: "#F4F6F7"
    property color textSecondary: "#AEB8C0"

    property var accentColours: ["#D9732F", "#3FA7D6", "#4C9F70"]

    property var wallpaperPresets: [
        { name: "Outback Dusk", top: "#182027", bottom: "#0D1115" },
        { name: "Desert Glow", top: "#3A2418", bottom: "#120C08" },
        { name: "Ocean Deep", top: "#152833", bottom: "#050B0F" },
        { name: "Spinifex", top: "#1A2A1E", bottom: "#0A120C" },
        { name: "Midnight", top: "#1A1A24", bottom: "#08080C" }
    ]

    property string statusMessage: ""

    function showError(message) {
        statusMessage = message
        statusMessageTimer.restart()
    }

    Timer {
        id: statusMessageTimer
        interval: 4000
        onTriggered: root.statusMessage = ""
    }

    Settings {
        id: prefs

        category: "appearance"

        property int accentIndex: 0
        property int scalingIndex: 0
        property bool animationsEnabled: true
        property int wallpaperIndex: 0
    }

    Settings {
        id: desktopPrefs

        category: "desktop"

        property string shortcutsJson: "[]"
    }

    property var shortcuts: []

    function loadShortcuts() {
        try {
            const parsed = JSON.parse(desktopPrefs.shortcutsJson)
            shortcuts = Array.isArray(parsed) ? parsed : []
        } catch (e) {
            shortcuts = []
        }
    }

    function saveShortcuts() {
        desktopPrefs.shortcutsJson = JSON.stringify(shortcuts)
    }

    function gridPositionForIndex(index) {
        const cellWidth = 104
        const cellHeight = 116
        const marginX = 40
        const marginY = 140
        const rows = Math.max(
            1,
            Math.floor((root.height - marginY - 40) / cellHeight)
        )

        const col = Math.floor(index / rows)
        const row = index % rows

        return {
            x: marginX + col * cellWidth,
            y: marginY + row * cellHeight
        }
    }

    function addShortcut(title, icon, command) {
        if (shortcuts.some(s => s.command === command)) {
            root.showError(title + " is already on the desktop.")
            return
        }

        const pos = root.gridPositionForIndex(shortcuts.length)

        shortcuts = shortcuts.concat([{
            id: Date.now().toString(36) + Math.random().toString(36).slice(2, 7),
            title: title,
            icon: icon,
            command: command,
            x: pos.x,
            y: pos.y
        }])

        root.saveShortcuts()
    }

    function removeShortcut(shortcutId) {
        shortcuts = shortcuts.filter(s => s.id !== shortcutId)
        root.saveShortcuts()
    }

    function moveShortcut(shortcutId, x, y) {
        shortcuts = shortcuts.map(s =>
            s.id === shortcutId ? Object.assign({}, s, { x: x, y: y }) : s
        )
        root.saveShortcuts()
    }

    function launchShortcut(shortcutId) {
        const shortcut = shortcuts.find(s => s.id === shortcutId)
        if (!shortcut) {
            return
        }

        if (!systemLauncher.launch(shortcut.command)) {
            root.showError("Couldn't open " + shortcut.title + ".")
        }
    }

    function autoArrangeShortcuts() {
        shortcuts = shortcuts.map((s, index) =>
            Object.assign({}, s, root.gridPositionForIndex(index))
        )
        root.saveShortcuts()
    }

    function cycleWallpaper() {
        prefs.wallpaperIndex =
            (prefs.wallpaperIndex + 1) % wallpaperPresets.length
    }

    Component.onCompleted: root.loadShortcuts()

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.wallpaperPresets[prefs.wallpaperIndex].top
            }

            GradientStop {
                position: 1.0
                color: root.wallpaperPresets[prefs.wallpaperIndex].bottom
            }
        }
    }

    MouseArea {
        id: desktopContextArea

        anchors.fill: parent
        acceptedButtons: Qt.RightButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                desktopMenu.popup()
            }
        }
    }

    Item {
        id: desktopIconLayer
        anchors.fill: parent

        Repeater {
            model: root.shortcuts

            delegate: DesktopIcon {
                required property var modelData

                shortcutId: modelData.id
                title: modelData.title
                iconSource: modelData.icon
                command: modelData.command
                posX: modelData.x
                posY: modelData.y
            }
        }
    }

    Menu {
        id: desktopMenu

        Menu {
            title: "Add shortcut"

            MenuItem {
                text: "Terminal"
                onTriggered: root.addShortcut(
                    "Terminal", "icons/terminal.svg", "/usr/bin/outback-terminal"
                )
            }

            MenuItem {
                text: "Files"
                onTriggered: root.addShortcut(
                    "Files", "icons/folder.svg", "/usr/bin/outback-files"
                )
            }

            MenuItem {
                text: "Browser"
                onTriggered: root.addShortcut(
                    "Browser", "icons/globe.svg", "/usr/bin/outback-browser"
                )
            }

            MenuItem {
                text: "Settings"
                onTriggered: root.addShortcut(
                    "Settings", "icons/gear.svg", "/usr/bin/outback-settings"
                )
            }
        }

        MenuItem {
            text: "Refresh"
            onTriggered: root.autoArrangeShortcuts()
        }

        MenuSeparator {}

        MenuItem {
            text: "Change wallpaper"
            onTriggered: root.cycleWallpaper()
        }

        MenuItem {
            text: "Personalize..."
            onTriggered: {
                if (!systemLauncher.launch("/usr/bin/outback-settings")) {
                    root.showError("Couldn't open Settings.")
                }
            }
        }
    }

    Menu {
        id: iconMenu

        property string targetId: ""

        MenuItem {
            text: "Open"
            onTriggered: root.launchShortcut(iconMenu.targetId)
        }

        MenuItem {
            text: "Remove from desktop"
            onTriggered: root.removeShortcut(iconMenu.targetId)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 28

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                width: 52
                height: 52
                radius: 14
                color: root.primary

                Image {
                    anchors.centerIn: parent
                    source: "icons/outback-mark.svg"
                    sourceSize.width: 26
                    sourceSize.height: 26
                }
            }

            Column {
                spacing: 2

                Text {
                    text: "Outback OS"
                    color: root.textPrimary
                    font.pixelSize: 27
                    font.bold: true
                }

                Text {
                    text: "Built for where the signal ends."
                    color: root.textSecondary
                    font.pixelSize: 14
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                id: clock

                color: root.textPrimary
                font.pixelSize: 21
                font.weight: Font.Medium

                function updateClock() {
                    text = Qt.formatDateTime(
                        new Date(),
                        "ddd d MMM  h:mm AP"
                    )
                }

                Component.onCompleted: updateClock()

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clock.updateClock()
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Column {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Welcome"
                color: root.textPrimary
                font.pixelSize: 42
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press the Start button or the Windows key to open your apps."
                color: root.textSecondary
                font.pixelSize: 18
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 1
            columnSpacing: 20
            rowSpacing: 20

            AppTile {
                title: "Install Outback OS"
                icon: "icons/download.svg"
                command: ""
                isInstaller: true
                visible: systemLauncher.isInstallerAvailable()
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            visible: root.statusMessage.length > 0
            radius: 10
            color: "#4A1F1F"
            border.color: "#C0392B"
            border.width: 1
            implicitWidth: statusText.implicitWidth + 32
            implicitHeight: statusText.implicitHeight + 20

            Text {
                id: statusText
                anchors.centerIn: parent
                text: root.statusMessage
                color: "#F4F6F7"
                font.pixelSize: 14
            }
        }
    }

    component AppTile: Rectangle {
        id: tile

        required property string title
        required property string icon
        required property string command
        property bool isInstaller: false

        Layout.preferredWidth: 160
        Layout.preferredHeight: 145

        radius: 24
        color: tileMouse.containsMouse
               ? root.surfaceRaised
               : root.surface

        scale: tileMouse.pressed ? 0.96 : 1.0

        Behavior on scale {
            enabled: prefs.animationsEnabled

            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
            enabled: prefs.animationsEnabled

            ColorAnimation {
                duration: 150
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 14

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter

                width: 62
                height: 62
                radius: 18
                color: root.primary

                Image {
                    anchors.centerIn: parent
                    source: tile.icon
                    sourceSize.width: 30
                    sourceSize.height: 30
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.title
                color: root.textPrimary
                font.pixelSize: 16
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: tileMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                if (tile.isInstaller) {
                    if (!systemLauncher.launchInstaller()) {
                        root.showError("Couldn't start the installer.")
                    }
                    return
                }

                if (tile.command.length === 0) {
                    root.showError(tile.title + " isn't available yet.")
                    return
                }

                if (!systemLauncher.launch(tile.command)) {
                    root.showError("Couldn't open " + tile.title + ".")
                }
            }
        }
    }

    component DesktopIcon: Item {
        id: icon

        // Named iconSource rather than icon: this Item's own id is "icon"
        // (used throughout below), and a property can't share that name.
        required property string shortcutId
        required property string title
        required property string iconSource
        required property string command
        required property real posX
        required property real posY

        x: posX
        y: posY
        width: 92
        height: 104

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: iconMouse.containsMouse || iconMouse.drag.active
                   ? "#2A343D"
                   : "transparent"

            Behavior on color {
                enabled: prefs.animationsEnabled

                ColorAnimation {
                    duration: 120
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter

                width: 48
                height: 48
                radius: 14
                color: root.primary

                Image {
                    anchors.centerIn: parent
                    source: icon.iconSource
                    sourceSize.width: 22
                    sourceSize.height: 22
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 88
                horizontalAlignment: Text.AlignHCenter
                text: icon.title
                color: root.textPrimary
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: iconMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            drag.target: icon
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: root.width - icon.width
            drag.maximumY: root.height - icon.height

            onReleased: {
                root.moveShortcut(icon.shortcutId, icon.x, icon.y)
            }

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    iconMenu.targetId = icon.shortcutId
                    iconMenu.popup()
                    return
                }

                root.launchShortcut(icon.shortcutId)
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.settings
import org.kde.layershell 1.0 as LayerShellQt
import Outback.Taskbar

Window {
    id: menu

    required property color surface
    required property color surfaceRaised
    required property color primary
    required property color textPrimary
    required property color textSecondary
    required property real taskbarHeight

    readonly property var filteredApps: {
        const q = searchField.text.trim().toLowerCase()
        if (q.length === 0) {
            return Apps.entries
        }
        return Apps.entries.filter(function (app) {
            return app.label.toLowerCase().indexOf(q) !== -1
        })
    }

    readonly property var recentApps: recentsSettings.recentIds
        .map(function (id) {
            return Apps.entries.find(function (app) { return app.id === id })
        })
        .filter(function (app) { return app !== undefined })

    // Covers the whole output so a click anywhere outside the panel can be
    // caught and closes the menu; the panel itself is positioned within
    // this via ordinary QML anchors rather than layer-shell anchors.
    width: Screen.width
    height: Screen.height
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

    Settings {
        id: recentsSettings

        category: "startMenu"

        property var recentIds: []
    }

    function toggle() {
        menu.visible = !menu.visible
    }

    function close() {
        menu.visible = false
    }

    function launch(app) {
        systemLauncher.launch(app.command)

        const ids = recentsSettings.recentIds.filter(function (id) {
            return id !== app.id
        })
        ids.unshift(app.id)
        recentsSettings.recentIds = ids.slice(0, 3)

        menu.close()
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            searchField.forceActiveFocus()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: menu.close()
    }

    Rectangle {
        id: panel

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.bottomMargin: menu.taskbarHeight + 12
        width: 300
        height: content.implicitHeight + 24
        radius: 16
        color: menu.surface
        border.color: menu.surfaceRaised
        border.width: 1

        Keys.onEscapePressed: menu.close()

        MouseArea {
            // Swallows clicks inside the panel so they don't fall through
            // to the full-screen backdrop and close the menu.
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
                    color: menu.primary

                    Text {
                        anchors.centerIn: parent
                        text: "O"
                        color: "white"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Outback"
                    color: menu.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }

            TextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: "Type to search apps"
                selectByMouse: true

                Keys.onEscapePressed: menu.close()
                Keys.onReturnPressed: {
                    if (menu.filteredApps.length > 0) {
                        menu.launch(menu.filteredApps[0])
                    }
                }
            }

            Text {
                text: "Recent"
                color: menu.textSecondary
                font.pixelSize: 11
                Layout.topMargin: 4
                visible: searchField.text.length === 0 && menu.recentApps.length > 0
            }

            Repeater {
                model: searchField.text.length === 0 ? menu.recentApps : []

                delegate: AppEntry {
                    required property var modelData
                    Layout.fillWidth: true
                    app: modelData
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                visible: searchField.text.length === 0 && menu.recentApps.length > 0
                color: menu.surfaceRaised
            }

            Text {
                text: "All Apps"
                color: menu.textSecondary
                font.pixelSize: 11
                Layout.topMargin: 4
                visible: searchField.text.length === 0
            }

            Repeater {
                model: menu.filteredApps

                delegate: AppEntry {
                    required property var modelData
                    Layout.fillWidth: true
                    app: modelData
                }
            }

            Text {
                text: "No apps found"
                color: menu.textSecondary
                font.pixelSize: 13
                Layout.topMargin: 4
                visible: menu.filteredApps.length === 0
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: menu.surfaceRaised
            }

            MenuEntry {
                Layout.fillWidth: true
                label: "Sign Out"
                onActivated: {
                    systemLauncher.signOut()
                    menu.close()
                }
            }

            MenuEntry {
                Layout.fillWidth: true
                label: "Restart"
                onActivated: {
                    systemLauncher.reboot()
                    menu.close()
                }
            }

            MenuEntry {
                Layout.fillWidth: true
                label: "Shut Down"
                onActivated: {
                    systemLauncher.shutdown()
                    menu.close()
                }
            }
        }
    }

    component AppEntry: Rectangle {
        id: entry

        required property var app

        Layout.preferredHeight: 44
        radius: 10
        color: entryMouse.containsMouse ? menu.surfaceRaised : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 8
                color: entry.app.accent

                Text {
                    anchors.centerIn: parent
                    text: entry.app.symbol
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: entry.app.label
                color: menu.textPrimary
                font.pixelSize: 14
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: entryMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: menu.launch(entry.app)
        }
    }

    component MenuEntry: Rectangle {
        id: entry

        required property string label
        signal activated()

        Layout.preferredHeight: 40
        radius: 10
        color: entryMouse.containsMouse ? menu.surfaceRaised : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: entry.label
            color: menu.textPrimary
            font.pixelSize: 14
        }

        MouseArea {
            id: entryMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: entry.activated()
        }
    }
}

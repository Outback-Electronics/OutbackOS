pragma Singleton
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

Window {
    id: menu

    width: 260
    height: content.implicitHeight + 24
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    // Anchoring bottom+left (not the full-width anchor the taskbar uses)
    // lets the compositor's usual exclusive-zone avoidance place this just
    // above the taskbar's reserved strip rather than behind it, without
    // this surface needing to know the taskbar's exact height.
    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

    // Shows (or hides, if already open on that output) the menu on a
    // specific output. Each output gets its own taskbar panel, but there is
    // only ever one start menu, so whichever panel triggers it just moves
    // it to its own screen.
    function toggleOn(targetScreen) {
        if (menu.visible && menu.screen === targetScreen) {
            menu.close()
            return
        }

        menu.screen = targetScreen
        menu.visible = true
    }

    function close() {
        menu.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.surface
        border.color: Theme.surfaceRaised
        border.width: 1

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                text: "Applications"
                color: Theme.textSecondary
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Repeater {
                model: AppCatalog.apps

                delegate: AppEntry {
                    Layout.fillWidth: true
                    required property var modelData
                    appData: modelData
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: Theme.surfaceRaised
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
        id: appEntry

        required property var appData

        Layout.preferredHeight: 40
        radius: 10
        color: appMouse.containsMouse ? Theme.surfaceRaised : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 8
                color: Theme.surface

                Text {
                    anchors.centerIn: parent
                    text: appEntry.appData.symbol
                    color: Theme.primary
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: appEntry.appData.label
                color: Theme.textPrimary
                font.pixelSize: 14
            }

            Rectangle {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 8
                color: pinMouse.containsMouse ? Theme.surface : "transparent"

                readonly property bool pinned: PinnedApps.isPinned(appEntry.appData.id)

                Text {
                    anchors.centerIn: parent
                    text: parent.pinned ? "★" : "☆"
                    color: parent.pinned ? Theme.primary : Theme.textSecondary
                    font.pixelSize: 13
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    ToolTip.visible: containsMouse
                    ToolTip.text: parent.pinned ? "Unpin from taskbar" : "Pin to taskbar"
                    ToolTip.delay: 500

                    onClicked: PinnedApps.toggle(appEntry.appData.id)
                }
            }
        }

        MouseArea {
            id: appMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: -1

            onClicked: {
                systemLauncher.launch(appEntry.appData.command)
                menu.close()
            }
        }
    }

    component MenuEntry: Rectangle {
        id: entry

        required property string label
        signal activated()

        Layout.preferredHeight: 40
        radius: 10
        color: entryMouse.containsMouse ? Theme.surfaceRaised : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: entry.label
            color: Theme.textPrimary
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

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

Window {
    id: menu

    required property color surface
    required property color surfaceRaised
    required property color primary
    required property color textPrimary
    required property color textSecondary

    width: 240
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

    function toggle() {
        menu.visible = !menu.visible
    }

    function close() {
        menu.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: menu.surface
        border.color: menu.surfaceRaised
        border.width: 1

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            MenuEntry {
                Layout.fillWidth: true
                label: "Settings"
                onActivated: {
                    systemLauncher.launch("/usr/bin/outback-settings")
                    menu.close()
                }
            }

            MenuEntry {
                Layout.fillWidth: true
                label: "Browser"
                onActivated: {
                    systemLauncher.launch("/usr/bin/outback-browser")
                    menu.close()
                }
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

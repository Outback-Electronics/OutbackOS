pragma Singleton
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

// Right-click menu for a taskbar window-list entry. wlr-layer-shell has no
// concept of "open at the cursor" (surfaces only anchor to screen edges),
// so this only anchors to the bottom edge, which the compositor centers
// horizontally by default - close enough to the window list (it sits in
// the middle of the taskbar) without needing cursor-relative positioning
// layer-shell can't express.
Window {
    id: menu

    width: 200
    height: content.implicitHeight + 16
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    property var toplevel: null
    property var pinEntry: null

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

    function openFor(targetToplevel, targetScreen) {
        menu.toplevel = targetToplevel
        menu.pinEntry = Apps.byAppId(targetToplevel.appId)
        menu.screen = targetScreen
        menu.visible = true
    }

    function close() {
        menu.visible = false
        menu.toplevel = null
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.surface
        border.color: Theme.surfaceRaised
        border.width: 1

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Entry {
                Layout.fillWidth: true
                label: menu.toplevel && menu.toplevel.minimized ? "Restore" : "Minimize"
                enabled: menu.toplevel !== null
                onActivated: {
                    menu.toplevel.requestToggleMinimize()
                    menu.close()
                }
            }

            Entry {
                Layout.fillWidth: true
                label: menu.toplevel && menu.toplevel.maximized ? "Unmaximize" : "Maximize"
                enabled: menu.toplevel !== null
                onActivated: {
                    menu.toplevel.requestToggleMaximize()
                    menu.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: Theme.surfaceRaised
                visible: menu.pinEntry !== null
            }

            Entry {
                Layout.fillWidth: true
                visible: menu.pinEntry !== null
                label: menu.pinEntry && PinnedApps.isPinned(menu.pinEntry.id)
                       ? "Unpin from taskbar"
                       : "Pin to taskbar"
                onActivated: {
                    PinnedApps.toggle(menu.pinEntry.id)
                    menu.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: Theme.surfaceRaised
            }

            Entry {
                Layout.fillWidth: true
                label: "Close window"
                enabled: menu.toplevel !== null
                onActivated: {
                    menu.toplevel.requestClose()
                    menu.close()
                }
            }
        }
    }

    component Entry: Rectangle {
        id: entry

        required property string label
        signal activated()

        Layout.preferredHeight: 34
        radius: 8
        opacity: entry.enabled ? 1.0 : 0.4
        color: entryMouse.containsMouse && entry.enabled ? Theme.surfaceRaised : "transparent"

        Behavior on color {
            ColorAnimation { duration: 100 }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: entry.label
            color: Theme.textPrimary
            font.pixelSize: 13
        }

        MouseArea {
            id: entryMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: entry.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: entry.activated()
        }
    }
}

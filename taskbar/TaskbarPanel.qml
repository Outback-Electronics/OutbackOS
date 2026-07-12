import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt
import Outback.Taskbar

// One instance of this is created per connected output (see Main.qml), so
// every monitor gets its own full-width bottom bar rather than assuming a
// single primary display.
Window {
    id: root

    width: Screen.width
    height: 56
    visible: true
    color: Theme.surface

    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.exclusionZone: root.height
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand
    LayerShellQt.Window.scope: "taskbar"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: startMouse.containsMouse ? Theme.surfaceRaised : "transparent"

            Text {
                anchors.centerIn: parent
                text: "O"
                color: Theme.primary
                font.pixelSize: 19
                font.bold: true
            }

            MouseArea {
                id: startMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: StartMenu.toggleOn(root.screen)
            }
        }

        Repeater {
            model: PinnedApps.pinnedIds

            delegate: PinnedButton {
                required property string modelData
                readonly property var appData: AppCatalog.byId(modelData)
                visible: appData !== null
                symbol: appData ? appData.symbol : ""
                label: appData ? appData.label : ""
                command: appData ? appData.command : ""
                appId: modelData
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            color: Theme.surfaceRaised
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    // The desktop background ("outback-shell") is not a
                    // real app window, so it is excluded from this list.
                    model: ToplevelManager.toplevels.filter(function (toplevel) {
                        return toplevel.appId !== "outback-shell"
                    })

                    delegate: Rectangle {
                        id: entry

                        required property var modelData

                        height: 40
                        width: Math.min(220, Math.max(120, label.implicitWidth + 52))
                        radius: 12
                        color: modelData.activated
                               ? Theme.primary
                               : (entryMouse.containsMouse ? Theme.surfaceRaised : Theme.surface)
                        opacity: modelData.minimized ? 0.55 : 1.0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    WindowContextMenu.openFor(entry.modelData, root.screen)
                                } else {
                                    entry.modelData.requestToggleMinimize()
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 6
                            spacing: 6

                            Text {
                                id: label
                                Layout.fillWidth: true
                                text: entry.modelData.title.length > 0
                                      ? entry.modelData.title
                                      : entry.modelData.appId
                                color: entry.modelData.activated ? "white" : Theme.textPrimary
                                elide: Text.ElideRight
                                font.pixelSize: 13
                            }

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                radius: 11
                                color: closeMouse.containsMouse ? "#40000000" : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: entry.modelData.activated ? "white" : Theme.textSecondary
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: entry.modelData.requestClose()
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            color: Theme.surfaceRaised
        }

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: bellMouse.containsMouse ? Theme.surfaceRaised : "transparent"

            Text {
                anchors.centerIn: parent
                text: "🔔"
                font.pixelSize: 16
            }

            Rectangle {
                visible: notificationServer.unreadCount > 0
                width: 8
                height: 8
                radius: 4
                color: Theme.primary
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.rightMargin: 8
            }

            MouseArea {
                id: bellMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationPanel.toggleOn(root.screen)
            }
        }

        Rectangle {
            id: trayCluster

            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: trayMouse.containsMouse ? Theme.surfaceRaised : "transparent"

            // SystemBackend is poll-based (it shells out on demand rather
            // than watching nmcli/wpctl for changes), so this icon cluster
            // has to poll it too rather than binding straight to it.
            property bool wifiOn: false
            property bool muted: false

            function refresh() {
                wifiOn = systemBackend.wifiEnabled()
                muted = systemBackend.audioMuted()
            }

            Component.onCompleted: refresh()

            Timer {
                interval: 5000
                running: true
                repeat: true
                onTriggered: trayCluster.refresh()
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: "📶"
                    font.pixelSize: 13
                    opacity: trayCluster.wifiOn ? 1.0 : 0.4
                }

                Text {
                    text: trayCluster.muted ? "🔇" : "🔊"
                    font.pixelSize: 13
                }
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: QuickSettingsPanel.toggleOn(root.screen)
            }
        }

        Text {
            id: clock

            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.Medium

            function updateClock() {
                text = Qt.formatDateTime(new Date(), "ddd d MMM  h:mm AP")
            }

            Component.onCompleted: updateClock()

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.updateClock()
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: CalendarFlyout.toggleOn(root.screen)
            }
        }
    }

    component PinnedButton: Rectangle {
        id: pinned

        required property string symbol
        required property string label
        required property string command
        required property string appId

        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: 12
        color: pinnedMouse.containsMouse ? Theme.surfaceRaised : "transparent"

        Text {
            anchors.centerIn: parent
            text: pinned.symbol
            color: Theme.textPrimary
            font.pixelSize: 15
            font.bold: true
        }

        MouseArea {
            id: pinnedMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    PinnedApps.unpin(pinned.appId)
                } else {
                    systemLauncher.launch(pinned.command)
                }
            }

            ToolTip.visible: containsMouse
            ToolTip.text: pinned.label
            ToolTip.delay: 500
        }
    }
}

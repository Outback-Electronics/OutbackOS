import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.settings
import org.kde.layershell 1.0 as LayerShellQt
import Outback.Taskbar

Window {
    id: root

    width: Screen.width
    height: 56
    visible: true
    color: surface

    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.exclusionZone: root.height
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand
    LayerShellQt.Window.scope: "taskbar"

    property color surface: "#1B2229"
    property color surfaceRaised: "#252E36"
    property color primary: accentColours[prefs.accentIndex]
    property color textPrimary: "#F4F6F7"
    property color textSecondary: "#AEB8C0"

    property var accentColours: ["#D9732F", "#3FA7D6", "#4C9F70"]

    Settings {
        id: prefs

        category: "appearance"

        property int accentIndex: 0
    }

    StartMenu {
        id: startMenu

        surface: root.surface
        surfaceRaised: root.surfaceRaised
        primary: root.primary
        textPrimary: root.textPrimary
        textSecondary: root.textSecondary
        taskbarHeight: root.height

        onLockRequested: root.lock()
    }

    LockScreen {
        id: lockScreen

        surface: root.surface
        surfaceRaised: root.surfaceRaised
        primary: root.primary
        textPrimary: root.textPrimary
        textSecondary: root.textSecondary
    }

    function lock() {
        startMenu.close()
        lockScreen.show()
    }

    Connections {
        target: signalBridge
        function onToggleStartMenuRequested() {
            startMenu.toggle()
        }
        function onLockRequested() {
            root.lock()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            radius: 12
            color: root.primary
            opacity: startMouse.containsMouse ? 0.85 : 1.0

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            Image {
                anchors.centerIn: parent
                source: "icons/outback-mark.svg"
                sourceSize.width: 20
                sourceSize.height: 20
            }

            MouseArea {
                id: startMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: startMenu.toggle()
            }
        }

        Repeater {
            // Pinned taskbar apps come from the same registry the start
            // menu's all-apps list uses, so adding an app there is enough
            // to also pin it here.
            model: Apps.entries.filter(function (app) { return app.pinned })

            delegate: PinnedButton {
                required property var modelData
                icon: modelData.icon
                label: modelData.label
                command: modelData.command
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            color: root.surfaceRaised
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
                               ? root.primary
                               : (entryMouse.containsMouse ? root.surfaceRaised : root.surface)
                        opacity: modelData.minimized ? 0.55 : 1.0

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        MouseArea {
                            id: entryMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: entry.modelData.requestToggleMinimize()
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
                                color: entry.modelData.activated ? "white" : root.textPrimary
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
                                    color: entry.modelData.activated ? "white" : root.textSecondary
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

        Text {
            id: clock

            color: root.textPrimary
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
        }
    }

    component PinnedButton: Rectangle {
        id: pinned

        required property string icon
        required property string label
        required property string command

        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: 12
        color: pinnedMouse.containsMouse ? root.surfaceRaised : "transparent"

        Image {
            anchors.centerIn: parent
            source: pinned.icon
            sourceSize.width: 18
            sourceSize.height: 18
        }

        MouseArea {
            id: pinnedMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: systemLauncher.launch(pinned.command)

            ToolTip.visible: containsMouse
            ToolTip.text: pinned.label
            ToolTip.delay: 500
        }
    }
}

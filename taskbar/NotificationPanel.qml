pragma Singleton
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

Window {
    id: panel

    width: 340
    height: Math.min(480, list.contentHeight + header.height + 40)
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

    function toggleOn(targetScreen) {
        if (panel.visible && panel.screen === targetScreen) {
            panel.visible = false
            return
        }

        panel.screen = targetScreen
        panel.visible = true
        notificationServer.markAllRead()
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.surface
        border.color: Theme.surfaceRaised
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                id: header
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.textPrimary
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Clear all"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    visible: notificationServer.count > 0

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notificationServer.clearAll()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 20
                Layout.bottomMargin: 20
                horizontalAlignment: Text.AlignHCenter
                text: "No notifications"
                color: Theme.textSecondary
                font.pixelSize: 13
                visible: notificationServer.count === 0
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                clip: true
                visible: notificationServer.count > 0
                model: notificationServer

                delegate: Rectangle {
                    id: card

                    required property int index
                    required property string appName
                    required property string summary
                    required property string body
                    required property int urgency
                    required property var actions
                    required property double timestamp

                    width: list.width
                    height: cardContent.implicitHeight + 20
                    radius: 12
                    color: Theme.surfaceRaised

                    ColumnLayout {
                        id: cardContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: card.appName
                                color: card.urgency === 2 ? Theme.primary : Theme.textSecondary
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: {
                                    const elapsedSeconds =
                                        Date.now() / 1000 - card.timestamp
                                    if (elapsedSeconds < 60) {
                                        return "now"
                                    }
                                    if (elapsedSeconds < 3600) {
                                        return Math.floor(elapsedSeconds / 60) + "m"
                                    }
                                    return Math.floor(elapsedSeconds / 3600) + "h"
                                }
                                color: Theme.textSecondary
                                font.pixelSize: 11
                            }

                            Text {
                                text: "✕"
                                color: Theme.textSecondary
                                font.pixelSize: 11

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notificationServer.dismissAt(card.index)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.summary
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.body
                            visible: card.body.length > 0
                            color: Theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Flow {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 6
                            visible: card.actions.length >= 2

                            Repeater {
                                // actions is a flat [key, label, key, label, ...] list
                                // per the org.freedesktop.Notifications spec.
                                model: Math.floor(card.actions.length / 2)

                                delegate: Rectangle {
                                    id: actionChip

                                    required property int index

                                    readonly property string actionKey: card.actions[index * 2]
                                    readonly property string actionLabel: card.actions[index * 2 + 1]

                                    width: actionLabelText.implicitWidth + 20
                                    height: 26
                                    radius: 8
                                    color: actionMouse.containsMouse ? Theme.primary : Theme.surface

                                    Text {
                                        id: actionLabelText
                                        anchors.centerIn: parent
                                        text: actionChip.actionLabel
                                        color: Theme.textPrimary
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notificationServer.invokeAction(
                                            card.index,
                                            actionChip.actionKey
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

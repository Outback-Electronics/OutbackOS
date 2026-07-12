import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root

    visible: true
    visibility: Window.FullScreen

    title: "Outback OS"

    minimumWidth: 1024
    minimumHeight: 600

    color: "#101418"

    property color surface: "#1B2229"
    property color surfaceRaised: "#252E36"
    property color primary: "#D9732F"
    property color textPrimary: "#F4F6F7"
    property color textSecondary: "#AEB8C0"

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#182027"
            }

            GradientStop {
                position: 1.0
                color: "#0D1115"
            }
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

                Text {
                    anchors.centerIn: parent
                    text: "O"
                    color: "white"
                    font.pixelSize: 30
                    font.bold: true
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
                text: "Choose an application"
                color: root.textSecondary
                font.pixelSize: 18
            }
        }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 4
            columnSpacing: 20
            rowSpacing: 20

            AppTile {
                title: "Files"
                symbol: "F"
                command: ""
            }

            AppTile {
                title: "Browser"
                symbol: "B"
                command: ""
            }

            AppTile {
                title: "Settings"
                symbol: "S"
                command: "/usr/bin/outback-settings"
            }

            AppTile {
                title: "Terminal"
                symbol: "T"
                command: ""
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 540
            Layout.preferredHeight: 72

            radius: 24
            color: root.surface

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Repeater {
                    model: [
                        "Home",
                        "Files",
                        "Browser",
                        "Settings"
                    ]

                    delegate: Rectangle {
                        required property string modelData

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius: 16
                        color: mouse.containsMouse
                               ? root.surfaceRaised
                               : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.textPrimary
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: mouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    component AppTile: Rectangle {
        id: tile

        required property string title
        required property string symbol
        required property string command

        Layout.preferredWidth: 160
        Layout.preferredHeight: 145

        radius: 24
        color: tileMouse.containsMouse
               ? root.surfaceRaised
               : root.surface

        scale: tileMouse.pressed ? 0.96 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutCubic
            }
        }

        Behavior on color {
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

                Text {
                    anchors.centerIn: parent
                    text: tile.symbol
                    color: "white"
                    font.pixelSize: 29
                    font.bold: true
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
                if (tile.command.length === 0) {
                    console.log(tile.title, "is not built yet")
                    return
                }

                if (!systemLauncher.launch(tile.command)) {
                    console.log("Failed to launch:", tile.command)
                }
            }
        }
    }
}

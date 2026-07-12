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
    }

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
                symbol: "I"
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
        required property string symbol
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
}

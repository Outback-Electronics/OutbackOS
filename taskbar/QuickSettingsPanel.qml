pragma Singleton
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

// A quick-access panel for the same backends Settings already exposes
// (SystemBackend), so common toggles don't require opening the full
// Settings app. Values are polled rather than pushed since SystemBackend
// itself is poll-based (it shells out to nmcli/wpctl/bluetoothctl on
// demand, it does not watch them for changes).
Window {
    id: panel

    width: 300
    height: content.implicitHeight + 24
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

    property bool batteryPresent: false
    property int batteryPercentage: 0
    property bool batteryCharging: false
    property bool wifiOn: false
    property string network: ""
    property bool bluetoothOn: false
    property real volumeValue: 0
    property bool muted: false

    function toggleOn(targetScreen) {
        if (panel.visible && panel.screen === targetScreen) {
            panel.visible = false
            return
        }

        panel.screen = targetScreen
        refresh()
        panel.visible = true
    }

    function refresh() {
        batteryPresent = systemBackend.batteryPresent()
        if (batteryPresent) {
            batteryPercentage = systemBackend.batteryPercentage()
            batteryCharging = systemBackend.batteryCharging()
        }

        wifiOn = systemBackend.wifiEnabled()
        network = systemBackend.activeNetwork()
        bluetoothOn = systemBackend.bluetoothEnabled()

        const currentVolume = systemBackend.volume()
        if (currentVolume >= 0) {
            volumeValue = currentVolume
        }
        muted = systemBackend.audioMuted()
    }

    Timer {
        interval: 4000
        running: panel.visible
        repeat: true
        onTriggered: panel.refresh()
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
            anchors.margins: 16
            spacing: 14

            Row {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "📶"
                    font.pixelSize: 18
                    opacity: panel.wifiOn ? 1.0 : 0.4
                }

                Column {
                    width: 170

                    Text {
                        text: "Wi-Fi"
                        color: Theme.textPrimary
                        font.pixelSize: 14
                    }

                    Text {
                        text: panel.wifiOn
                              ? (panel.network.length > 0 ? panel.network : "On")
                              : "Off"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                // Not a live "checked: panel.wifiOn" binding: interactive
                // controls sever a declarative binding the moment the user
                // (or Qt Quick Controls itself, on click) assigns their
                // property directly, so this panel - a singleton that stays
                // alive across opens rather than being recreated each time -
                // needs an explicit resync whenever refresh() runs.
                Switch {
                    id: wifiSwitch
                    Component.onCompleted: checked = panel.wifiOn
                    onToggled: {
                        systemBackend.setWifiEnabled(checked)
                        panel.refresh()
                    }

                    Connections {
                        target: panel
                        function onWifiOnChanged() {
                            wifiSwitch.checked = panel.wifiOn
                        }
                    }
                }
            }

            Row {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "BT"
                    font.pixelSize: 13
                    font.bold: true
                    color: panel.bluetoothOn ? Theme.primary : Theme.textSecondary
                }

                Column {
                    width: 170

                    Text {
                        text: "Bluetooth"
                        color: Theme.textPrimary
                        font.pixelSize: 14
                    }

                    Text {
                        text: panel.bluetoothOn ? "On" : "Off"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                    }
                }

                Switch {
                    id: bluetoothSwitch
                    Component.onCompleted: checked = panel.bluetoothOn
                    onToggled: {
                        systemBackend.setBluetoothEnabled(checked)
                        panel.refresh()
                    }

                    Connections {
                        target: panel
                        function onBluetoothOnChanged() {
                            bluetoothSwitch.checked = panel.bluetoothOn
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: panel.muted ? "🔇" : "🔊"
                    font.pixelSize: 18
                }

                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 150
                    Component.onCompleted: value = panel.volumeValue
                    onMoved: {
                        systemBackend.setVolume(Math.round(value))
                        panel.muted = false
                    }

                    Connections {
                        target: panel
                        function onVolumeValueChanged() {
                            volumeSlider.value = panel.volumeValue
                        }
                    }
                }

                Text {
                    text: Math.round(panel.volumeValue) + "%"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    Layout.preferredWidth: 34
                }
            }

            Row {
                Layout.fillWidth: true
                spacing: 10
                visible: panel.batteryPresent

                Text {
                    text: panel.batteryCharging ? "⚡" : "🔋"
                    font.pixelSize: 18
                }

                Text {
                    text: "Battery "
                          + panel.batteryPercentage
                          + "%"
                          + (panel.batteryCharging ? " · Charging" : "")
                    color: Theme.textPrimary
                    font.pixelSize: 14
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.surfaceRaised
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 10
                color: settingsMouse.containsMouse ? Theme.surfaceRaised : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Open Settings"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                }

                MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        systemLauncher.launch("/usr/bin/outback-settings")
                        panel.visible = false
                    }
                }
            }
        }
    }
}

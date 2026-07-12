import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root

    width: 1100
    height: 720
    visible: true

    title: "Outback Settings"
    color: "#0D1115"

    property color sidebarColor: "#151B21"
    property color surfaceColor: "#1B2229"
    property color raisedColor: "#252E36"
    property color primaryColor: "#D9732F"
    property color textPrimaryColor: "#F4F6F7"
    property color textSecondaryColor: "#AEB8C0"

    property var categories: [
        "System",
        "Display",
        "Sound",
        "Network",
        "Bluetooth",
        "Appearance",
        "Accounts",
        "Privacy",
        "Updates",
        "About"
    ]

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 275
            Layout.fillHeight: true
            color: root.sidebarColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 13
                        color: root.primaryColor

                        Text {
                            anchors.centerIn: parent
                            text: "O"
                            color: "white"
                            font.pixelSize: 25
                            font.bold: true
                        }
                    }

                    Column {
                        Text {
                            text: "Outback OS"
                            color: root.textPrimaryColor
                            font.pixelSize: 19
                            font.bold: true
                        }

                        Text {
                            text: "Settings"
                            color: root.textSecondaryColor
                            font.pixelSize: 13
                        }
                    }
                }

                Item {
                    Layout.preferredHeight: 12
                }

                Repeater {
                    model: root.categories

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 14

                        color: pageStack.currentIndex === index
                               ? root.raisedColor
                               : mouseArea.containsMouse
                                   ? "#202830"
                                   : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16

                            text: modelData
                            color: root.textPrimaryColor
                            font.pixelSize: 15
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: mouseArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                pageStack.currentIndex = index
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Text {
                    text: "Outback OS Developer Preview"
                    color: root.textSecondaryColor
                    font.pixelSize: 11
                }
            }
        }

        StackLayout {
            id: pageStack

            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex: 0

            SettingsPage {
                pageTitle: "System"
                pageDescription: "Configure the core behaviour of this device."

                SettingCard {
                    title: "Device name"
                    description: "outback-homelab"

                    Button {
                        text: "Rename"
                        onClicked: console.log("Rename device")
                    }
                }

                SettingCard {
                    title: "Automatic updates"
                    description: "Install security and system updates automatically"

                    Switch {
                        checked: true
                        onToggled: console.log("Automatic updates:", checked)
                    }
                }

                SettingCard {
                    title: "Offline mode"
                    description: "Reduce network activity when connectivity is limited"

                    Switch {
                        onToggled: console.log("Offline mode:", checked)
                    }
                }
            }

            SettingsPage {
                pageTitle: "Display"
                pageDescription: "Adjust brightness, resolution and scaling."

                SettingCard {
                    title: "Brightness"
                    description: Math.round(brightnessSlider.value) + "%"

                    Slider {
                        id: brightnessSlider
                        from: 1
                        to: 100
                        value: 50
                        Layout.preferredWidth: 220

                        Component.onCompleted: {
                            const current = systemBackend.brightness()
                            if (current >= 0) {
                                value = current
                            }
                        }

                        onMoved: {
                            systemBackend.setBrightness(
                                Math.round(value)
                            )
                        }
                    }
                }

                SettingCard {
                    title: "Interface scaling"
                    description: scalingBox.currentText

                    ComboBox {
                        id: scalingBox
                        model: ["100%", "125%", "150%", "175%", "200%"]
                    }
                }

                SettingCard {
                    title: "Night colour"
                    description: nightSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: nightSwitch
                    }
                }
            }

            SettingsPage {
                pageTitle: "Sound"
                pageDescription: "Configure output, input and alert volume."

                SettingCard {
                    title: "Output volume"
                    description: Math.round(volumeSlider.value) + "%"

                    Slider {
                        id: volumeSlider
                        from: 0
                        to: 150
                        value: 70
                        Layout.preferredWidth: 220

                        Component.onCompleted: {
                            const current = systemBackend.volume()
                            if (current >= 0) {
                                value = current
                            }
                        }

                        onMoved: {
                            systemBackend.setVolume(
                                Math.round(value)
                            )
                        }
                    }
                }

                SettingCard {
                    title: "Mute system audio"
                    description: muteSwitch.checked ? "Muted" : "Active"

                    Switch {
                        id: muteSwitch

                        Component.onCompleted: {
                            checked = systemBackend.audioMuted()
                        }

                        onToggled: {
                            systemBackend.setAudioMuted(checked)
                        }
                    }
                }
            }

            SettingsPage {
                pageTitle: "Network"
                pageDescription: "Manage wired and wireless connections."

                SettingCard {
                    title: "Wi-Fi"
                    description: wifiSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: wifiSwitch

                        Component.onCompleted: {
                            checked = systemBackend.wifiEnabled()
                        }

                        onToggled: {
                            systemBackend.setWifiEnabled(checked)
                            activeNetworkText.text =
                                systemBackend.activeNetwork()
                        }
                    }
                }

                SettingCard {
                    title: "Current network"
                    description: activeNetworkText.text

                    Text {
                        id: activeNetworkText
                        text: systemBackend.activeNetwork()
                        visible: false
                    }

                    Button {
                        text: systemBackend.wifiScanning
                              ? "Scanning..."
                              : "Scan"

                        enabled: !systemBackend.wifiScanning

                        onClicked: {
                            networkStatus.text =
                                "Scanning for Wi-Fi networks..."

                            systemBackend.startWifiScan()
                        }
                    }
                }

                Text {
                    id: networkStatus
                    text: ""
                    color: root.textSecondaryColor
                    font.pixelSize: 14
                }
            }

            SettingsPage {
                pageTitle: "Bluetooth"
                pageDescription: "Pair and manage nearby devices."

                SettingCard {
                    title: "Bluetooth"
                    description: bluetoothSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: bluetoothSwitch

                        Component.onCompleted: {
                            checked =
                                systemBackend.bluetoothEnabled()
                        }

                        onToggled: {
                            systemBackend.setBluetoothEnabled(
                                checked
                            )
                        }
                    }
                }

                SettingCard {
                    title: "Nearby devices"
                    description: bluetoothStatus.text

                    Text {
                        id: bluetoothStatus
                        text: "Ready"
                        visible: false
                    }

                    Button {
                        text: systemBackend.bluetoothScanning
                              ? "Scanning..."
                              : "Scan"

                        enabled: !systemBackend.bluetoothScanning

                        onClicked: {
                            bluetoothStatus.text =
                                "Scanning for Bluetooth devices..."

                            systemBackend.startBluetoothScan()
                        }
                    }
                }
            }

            SettingsPage {
                pageTitle: "Appearance"
                pageDescription: "Change colours, layout and visual effects."

                SettingCard {
                    title: "Theme"
                    description: themeBox.currentText

                    ComboBox {
                        id: themeBox
                        model: ["Outback Dark", "Outback Light", "High Contrast"]
                    }
                }

                SettingCard {
                    title: "Animations"
                    description: animationSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: animationSwitch
                        checked: true
                    }
                }

                SettingCard {
                    title: "Accent colour"
                    description: "Outback Orange"

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 14
                        color: root.primaryColor
                    }
                }
            }

            SettingsPage {
                pageTitle: "Accounts"
                pageDescription: "Manage Outback accounts and device identity."

                SettingCard {
                    title: "Outback Account"
                    description: "No account connected"

                    Button {
                        text: "Sign in"
                        onClicked: console.log("Open sign-in flow")
                    }
                }
            }

            SettingsPage {
                pageTitle: "Privacy"
                pageDescription: "Control permissions, location and diagnostics."

                SettingCard {
                    title: "Location services"
                    description: locationSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: locationSwitch
                    }
                }

                SettingCard {
                    title: "Diagnostic data"
                    description: diagnosticsSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: diagnosticsSwitch
                    }
                }
            }

            SettingsPage {
                pageTitle: "Updates"
                pageDescription: "Check for and install Outback OS updates."

                SettingCard {
                    title: "System version"
                    description: "Outback OS 0.1 Developer Preview"

                    Button {
                        text: "Check now"

                        onClicked: {
                            updateStatus.text =
                                "Checking for updates..."

                            updateStatus.text =
                                systemBackend.checkForUpdates()
                        }
                    }
                }

                Text {
                    id: updateStatus
                    text: ""
                    color: root.textSecondaryColor
                    font.pixelSize: 14
                }
            }

            SettingsPage {
                pageTitle: "About"
                pageDescription: "System and device information."

                SettingCard {
                    title: "Operating system"
                    description: systemBackend.operatingSystem()
                }

                SettingCard {
                    title: "Kernel"
                    description: systemBackend.kernelVersion()
                }

                SettingCard {
                    title: "Build"
                    description: "Development build"
                }
            }
        }
    }

    component SettingsPage: Item {
        id: settingsPage

        property string pageTitle
        property string pageDescription
        default property alias pageContent: contentColumn.data

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 38
            spacing: 22

            Text {
                text: settingsPage.pageTitle
                color: root.textPrimaryColor
                font.pixelSize: 34
                font.bold: true
            }

            Text {
                text: settingsPage.pageDescription
                color: root.textSecondaryColor
                font.pixelSize: 16
            }

            ColumnLayout {
                id: contentColumn

                Layout.fillWidth: true
                spacing: 16
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    component SettingCard: Rectangle {
        id: card

        property string title
        property string description
        default property alias controls: controlArea.data

        Layout.fillWidth: true
        Layout.preferredHeight: 92

        radius: 20
        color: root.surfaceColor

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: card.title
                    color: root.textPrimaryColor
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                Text {
                    text: card.description
                    color: root.textSecondaryColor
                    font.pixelSize: 14
                }
            }

            RowLayout {
                id: controlArea
                spacing: 12
            }
        }
    }

    Connections {
        target: systemBackend

        function onWifiScanFinished(networks, error) {
            if (error.length > 0) {
                networkStatus.text = error
                return
            }

            if (networks.length === 0) {
                networkStatus.text =
                    "No Wi-Fi networks found"
                return
            }

            networkStatus.text =
                networks.length
                + " Wi-Fi networks found. Strongest: "
                + networks[0].ssid
                + " ("
                + networks[0].signal
                + "%)"
        }

        function onBluetoothScanFinished(devices, error) {
            if (error.length > 0) {
                bluetoothStatus.text = error
                return
            }

            if (devices.length === 0) {
                bluetoothStatus.text =
                    "No Bluetooth devices found"
                return
            }

            bluetoothStatus.text =
                devices.length
                + " Bluetooth devices found"
        }
    }

}

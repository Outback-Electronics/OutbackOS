import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.settings

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
    property color primaryColor: accentColours[prefs.accentIndex]
    property color textPrimaryColor: "#F4F6F7"
    property color textSecondaryColor: "#AEB8C0"

    property var accentColours: ["#D9732F", "#3FA7D6", "#4C9F70"]
    property var accentNames: ["Outback Orange", "Ocean Blue", "Spinifex Green"]
    property var scalingOptions: ["100%", "125%", "150%", "175%", "200%"]

    Settings {
        id: prefs

        category: "appearance"

        property int accentIndex: 0
        property int scalingIndex: 0
        property bool animationsEnabled: true
    }

    property var categories: [
        "System",
        "Display",
        "Sound",
        "Network",
        "Bluetooth",
        "Appearance",
        "Device",
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
                    description: deviceNameField.text

                    TextField {
                        id: deviceNameField
                        Layout.preferredWidth: 200

                        Component.onCompleted: {
                            text = systemBackend.deviceName()
                        }
                    }

                    Button {
                        text: "Rename"

                        onClicked: {
                            renameStatus.text = systemBackend.renameDevice(
                                deviceNameField.text
                            )
                                ? "Renamed. Applies fully after next sign-in."
                                : "Could not rename device"
                        }
                    }
                }

                Text {
                    id: renameStatus
                    text: ""
                    color: root.textSecondaryColor
                    font.pixelSize: 14
                }

                SettingCard {
                    title: "Automatic updates"
                    description: "Install security and system updates automatically"

                    Switch {
                        id: autoUpdatesSwitch

                        Component.onCompleted: {
                            checked = systemBackend.autoUpdatesEnabled()
                        }

                        onToggled: {
                            if (!systemBackend.setAutoUpdatesEnabled(checked)) {
                                checked = !checked
                            }
                        }
                    }
                }

                SettingCard {
                    title: "Offline mode"
                    description: "Reduce network activity when connectivity is limited"

                    Switch {
                        id: offlineModeSwitch

                        Component.onCompleted: {
                            checked = systemBackend.offlineMode()
                        }

                        onToggled: {
                            if (!systemBackend.setOfflineMode(checked)) {
                                checked = !checked
                            }
                        }
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
                    description: root.scalingOptions[scalingBox.currentIndex]
                                 + " · applies after next sign-in"

                    ComboBox {
                        id: scalingBox
                        model: root.scalingOptions
                        currentIndex: prefs.scalingIndex

                        onActivated: {
                            prefs.scalingIndex = currentIndex
                        }
                    }
                }

                SettingCard {
                    title: "Night colour"
                    description: nightSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: nightSwitch

                        Component.onCompleted: {
                            checked = systemBackend.nightColourEnabled()
                        }

                        onToggled: {
                            systemBackend.setNightColour(checked)
                        }
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
                id: wifiPage

                pageTitle: "Network"
                pageDescription: "Manage wired and wireless connections."

                property var wifiNetworks: []
                property string activeSsid: systemBackend.activeNetwork()
                property var savedNetworks: systemBackend.savedWifiNetworks()

                function refreshSavedNetworks() {
                    wifiPage.savedNetworks = systemBackend.savedWifiNetworks()
                }

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
                            wifiPage.activeSsid =
                                systemBackend.activeNetwork()
                        }
                    }
                }

                SettingCard {
                    title: "Current network"
                    description: wifiPage.activeSsid.length > 0
                                  ? wifiPage.activeSsid
                                  : "Not connected"

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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 280

                    radius: 20
                    color: root.surfaceColor
                    clip: true

                    ListView {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4
                        model: wifiPage.wifiNetworks

                        delegate: Rectangle {
                            required property var modelData

                            width: ListView.view.width
                            height: 56
                            radius: 12

                            readonly property bool isOpen:
                                modelData.security === ""
                                || modelData.security === "--"
                            readonly property bool isActive:
                                modelData.ssid === wifiPage.activeSsid
                            readonly property bool isKnown:
                                wifiPage.savedNetworks.indexOf(modelData.ssid) !== -1

                            color: isActive
                                   ? root.raisedColor
                                   : rowMouse.containsMouse
                                       ? "#202830"
                                       : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                Text {
                                    text: modelData.signal > 66
                                          ? "▓▓▓"
                                          : modelData.signal > 33
                                              ? "▓▓░"
                                              : "▓░░"
                                    color: root.primaryColor
                                    font.pixelSize: 13
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.ssid
                                          + (isOpen ? "" : "  🔒")
                                    color: root.textPrimaryColor
                                    font.pixelSize: 15
                                    font.weight: isActive
                                                 ? Font.Bold
                                                 : Font.Normal
                                }

                                Button {
                                    visible: isActive
                                    text: "Forget"

                                    onClicked: {
                                        systemBackend.forgetNetwork(modelData.ssid)
                                        networkStatus.text =
                                            "Forgot " + modelData.ssid
                                        wifiPage.activeSsid = ""
                                        wifiPage.refreshSavedNetworks()
                                    }
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    if (isOpen || isKnown) {
                                        networkStatus.text =
                                            "Connecting to " + modelData.ssid + "..."
                                        systemBackend.connectToNetwork(modelData.ssid, "")
                                    } else {
                                        passwordDialog.targetSsid = modelData.ssid
                                        passwordField.text = ""
                                        passwordDialog.open()
                                    }
                                }
                            }
                        }
                    }
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
                    description: "Outback Dark · additional themes coming in a future release"

                    ComboBox {
                        model: ["Outback Dark"]
                        currentIndex: 0
                        enabled: false
                    }
                }

                SettingCard {
                    title: "Animations"
                    description: animationSwitch.checked ? "Enabled" : "Disabled"

                    Switch {
                        id: animationSwitch
                        checked: prefs.animationsEnabled

                        onToggled: {
                            prefs.animationsEnabled = checked
                        }
                    }
                }

                SettingCard {
                    title: "Accent colour"
                    description: root.accentNames[accentRow.currentIndex]

                    Row {
                        id: accentRow

                        property int currentIndex: prefs.accentIndex

                        spacing: 12

                        Repeater {
                            model: root.accentColours

                            delegate: Rectangle {
                                required property string modelData
                                required property int index

                                width: 36
                                height: 36
                                radius: 12
                                color: modelData
                                border.width: accentRow.currentIndex === index ? 3 : 0
                                border.color: root.textPrimaryColor

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: prefs.accentIndex = index
                                }
                            }
                        }
                    }
                }
            }

            SettingsPage {
                pageTitle: "Device identity"
                pageDescription: "Outback OS is a local-only system — there is no cloud account."

                SettingCard {
                    title: "Device name"
                    description: systemBackend.deviceName()
                }

                SettingCard {
                    title: "Local user"
                    description: "outback"
                }
            }

            SettingsPage {
                pageTitle: "Privacy"
                pageDescription: "Control permissions and data collection."

                SettingCard {
                    title: "Location services"
                    description: "Disabled · no location hardware on this device"

                    Switch {
                        checked: false
                        enabled: false
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

    Dialog {
        id: passwordDialog

        property string targetSsid: ""

        title: "Connect to " + targetSsid
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok | Dialog.Cancel

        contentItem: ColumnLayout {
            spacing: 12

            Text {
                text: "Enter the password for " + passwordDialog.targetSsid
                color: root.textPrimaryColor
            }

            TextField {
                id: passwordField
                Layout.preferredWidth: 260
                echoMode: TextInput.Password
            }
        }

        onAccepted: {
            networkStatus.text =
                "Connecting to " + targetSsid + "..."
            systemBackend.connectToNetwork(targetSsid, passwordField.text)
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

            wifiPage.wifiNetworks = networks
            wifiPage.activeSsid = systemBackend.activeNetwork()

            networkStatus.text = networks.length === 0
                ? "No Wi-Fi networks found"
                : networks.length + " Wi-Fi networks found"
        }

        function onWifiConnectFinished(success, ssid, error) {
            if (success) {
                networkStatus.text = "Connected to " + ssid
                wifiPage.activeSsid = ssid
                wifiPage.refreshSavedNetworks()
                passwordDialog.close()
            } else {
                networkStatus.text = error.length > 0
                    ? error
                    : "Could not connect to " + ssid
            }
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

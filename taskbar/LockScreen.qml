import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

// A full-screen, keyboard-exclusive overlay above every other surface
// (including the taskbar itself). Authentication is delegated to the
// system's normal PAM stack via LockBackend, so unlocking requires the
// same password as the "outback" account itself.
Window {
    id: lock

    required property color surface
    required property color surfaceRaised
    required property color primary
    required property color textPrimary
    required property color textSecondary

    property string errorText: ""

    width: Screen.width
    height: Screen.height
    visible: false
    color: "#0D1115"
    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
                                  | LayerShellQt.Window.AnchorBottom
                                  | LayerShellQt.Window.AnchorLeft
                                  | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityExclusive
    LayerShellQt.Window.scope: "lockscreen"

    // Same defence-in-depth as the desktop shell window: nothing but a
    // successful unlock should ever make this surface go away.
    onClosing: (close) => {
        close.accepted = false
    }

    function show() {
        passwordField.text = ""
        lock.errorText = ""
        lock.visible = true
        lock.requestActivate()
        passwordField.forceActiveFocus()
    }

    function attemptUnlock() {
        if (passwordField.text.length === 0) {
            return
        }

        if (lockBackend.authenticate(passwordField.text)) {
            lock.visible = false
        } else {
            lock.errorText = "Incorrect password"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#182027" }
            GradientStop { position: 1.0; color: "#0D1115" }
        }

        Column {
            anchors.centerIn: parent
            spacing: 22

            Text {
                id: clockText

                anchors.horizontalCenter: parent.horizontalCenter
                color: lock.textPrimary
                font.pixelSize: 64
                font.weight: Font.Light

                function updateClock() {
                    text = Qt.formatDateTime(new Date(), "h:mm AP")
                }

                Component.onCompleted: updateClock()

                Timer {
                    interval: 1000
                    running: lock.visible
                    repeat: true
                    onTriggered: clockText.updateClock()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(new Date(), "dddd d MMMM")
                color: lock.textSecondary
                font.pixelSize: 18
            }

            Item {
                width: 1
                height: 12
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 300
                height: 52
                radius: 14
                color: lock.surface
                border.width: 1
                border.color: passwordField.activeFocus ? lock.primary : lock.surfaceRaised

                TextField {
                    id: passwordField

                    anchors.fill: parent
                    anchors.margins: 2
                    leftPadding: 16
                    rightPadding: 16
                    verticalAlignment: TextInput.AlignVCenter

                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    color: lock.textPrimary
                    background: Item {}

                    onAccepted: lock.attemptUnlock()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: lock.errorText
                color: "#E06C5C"
                font.pixelSize: 13
                visible: lock.errorText.length > 0
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Unlock"
                onClicked: lock.attemptUnlock()
            }
        }
    }
}

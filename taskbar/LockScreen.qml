pragma Singleton
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

// One lock surface per connected output (see the Instantiator below):
// locking the session has to cover every monitor, not just whichever one
// the taskbar that triggered it happens to live on, or the "locked"
// desktop would just be visible and usable on the others. Every instance
// shares this singleton's locked/errorText state, so unlocking from any
// one of them (they all authenticate against the same LockBackend/PAM
// account) closes all of them together.
QtObject {
    id: root

    property bool locked: false
    property string errorText: ""

    function show() {
        root.errorText = ""
        root.locked = true
    }

    // Returns whether the password was correct, so a LockScreenWindow can
    // decide whether to clear/refocus its own password field.
    function attemptUnlock(password) {
        if (password.length === 0) {
            return true
        }

        if (lockBackend.authenticate(password)) {
            root.locked = false
            root.errorText = ""
            return true
        }

        root.errorText = "Incorrect password"
        return false
    }

    Instantiator {
        model: Qt.application.screens

        delegate: LockScreenWindow {
            required property var modelData
            screen: modelData
        }
    }

    // A full-screen, keyboard-exclusive overlay above every other surface
    // (including the taskbar itself). Authentication is delegated to the
    // system's normal PAM stack via LockBackend, so unlocking requires the
    // same password as the "outback" account itself.
    component LockScreenWindow: Window {
        id: lock

        width: Screen.width
        height: Screen.height
        visible: root.locked
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

        onVisibleChanged: {
            if (visible) {
                passwordField.text = ""
                lock.requestActivate()
                passwordField.forceActiveFocus()
            }
        }

        function tryUnlock() {
            if (passwordField.text.length === 0) {
                return
            }

            if (!root.attemptUnlock(passwordField.text)) {
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
                    color: Theme.textPrimary
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
                    color: Theme.textSecondary
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
                    color: Theme.surface
                    border.width: 1
                    border.color: passwordField.activeFocus ? Theme.primary : Theme.surfaceRaised

                    TextField {
                        id: passwordField

                        anchors.fill: parent
                        anchors.margins: 2
                        leftPadding: 16
                        rightPadding: 16
                        verticalAlignment: TextInput.AlignVCenter

                        echoMode: TextInput.Password
                        placeholderText: "Password"
                        color: Theme.textPrimary
                        background: Item {}

                        onAccepted: lock.tryUnlock()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.errorText
                    color: "#E06C5C"
                    font.pixelSize: 13
                    visible: root.errorText.length > 0
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Unlock"
                    onClicked: lock.tryUnlock()
                }
            }
        }
    }
}

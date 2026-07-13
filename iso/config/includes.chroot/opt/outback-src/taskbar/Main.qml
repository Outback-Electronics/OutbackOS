import QtQml
import QtQuick

// The taskbar's actual bar UI lives in TaskbarPanel.qml, one instance per
// connected output, so this file is just the controller that creates them
// and wires up the process-wide bits (the Super-key/lock signal toggles,
// and the shared flyouts that only ever need one instance - or one
// per-screen instance in the lock screen's case - regardless of monitor
// count).
QtObject {
    id: root

    Instantiator {
        model: Qt.application.screens

        delegate: TaskbarPanel {
            required property var modelData
            screen: modelData
        }
    }

    Connections {
        target: signalBridge
        function onToggleStartMenuRequested() {
            StartMenu.toggleOn(Qt.application.screens[0])
        }
        function onLockRequested() {
            LockScreen.show()
        }
    }

    // Instantiating these here (rather than lazily on first use) means the
    // notification toast host and the lock screen are listening from
    // process start, so nothing sent/requested before the first flyout is
    // opened gets lost or misses a monitor.
    property QtObject notificationToastHost: NotificationToastHost
    property QtObject lockScreen: LockScreen
}

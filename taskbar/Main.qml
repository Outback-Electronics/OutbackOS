import QtQml
import QtQuick

// The taskbar's actual bar UI lives in TaskbarPanel.qml, one instance per
// connected output, so this file is just the controller that creates them
// and wires up the process-wide bits (the Super-key toggle, the shared
// flyouts that only ever need one instance regardless of monitor count).
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
    }

    // Instantiating these here (rather than lazily on first use) means the
    // notification toast host is listening from process start, so nothing
    // sent before the first flyout is opened gets lost.
    property QtObject notificationToastHost: NotificationToastHost
}

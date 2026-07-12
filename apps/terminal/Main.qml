import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Outback.Terminal

ApplicationWindow {
    id: root

    width: 960
    height: 600
    visible: true

    title: "Outback Terminal"
    color: "#0D1115"

    property color surfaceColor: "#1B2229"
    property color textSecondaryColor: "#AEB8C0"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: root.surfaceColor

            Text {
                anchors.centerIn: parent
                text: "Outback Terminal"
                color: root.textSecondaryColor
                font.pixelSize: 13
            }
        }

        TerminalView {
            id: terminalView

            Layout.fillWidth: true
            Layout.fillHeight: true

            focus: true

            Component.onCompleted: {
                terminalView.start()
                terminalView.forceActiveFocus()
            }
        }
    }
}

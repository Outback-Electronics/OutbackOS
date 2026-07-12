import QtQuick
import QtQuick.Controls
import QtQuick.Window
import Outback.Terminal

ApplicationWindow {
    id: root

    width: 960
    height: 600
    visible: true

    title: "Outback Terminal"
    color: "#0D1115"

    // The window's own title bar (with minimize/maximize/close) is now
    // drawn by labwc's server-side decorations, so this content is just
    // the terminal itself.
    TerminalView {
        id: terminalView

        anchors.fill: parent

        focus: true

        Component.onCompleted: {
            terminalView.start()
            terminalView.forceActiveFocus()
        }
    }
}

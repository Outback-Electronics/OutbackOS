pragma Singleton
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

Window {
    id: flyout

    width: 260
    height: content.implicitHeight + 24
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    property date viewedMonth: new Date()
    property date today: new Date()

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

    function toggleOn(targetScreen) {
        if (flyout.visible && flyout.screen === targetScreen) {
            flyout.visible = false
            return
        }

        flyout.today = new Date()
        flyout.viewedMonth = flyout.today
        flyout.screen = targetScreen
        flyout.visible = true
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate()
    }

    function buildGrid() {
        const year = flyout.viewedMonth.getFullYear()
        const month = flyout.viewedMonth.getMonth()
        const firstWeekday = new Date(year, month, 1).getDay()
        const totalDays = daysInMonth(year, month)

        const cells = []
        for (let i = 0; i < firstWeekday; i++) {
            cells.push(0)
        }
        for (let day = 1; day <= totalDays; day++) {
            cells.push(day)
        }
        while (cells.length % 7 !== 0) {
            cells.push(0)
        }

        return cells
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
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹"
                    color: Theme.textSecondary
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const d = flyout.viewedMonth
                            flyout.viewedMonth = new Date(d.getFullYear(), d.getMonth() - 1, 1)
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(flyout.viewedMonth, "MMMM yyyy")
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "›"
                    color: Theme.textSecondary
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const d = flyout.viewedMonth
                            flyout.viewedMonth = new Date(d.getFullYear(), d.getMonth() + 1, 1)
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    delegate: Text {
                        required property string modelData
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: flyout.buildGrid()

                    delegate: Rectangle {
                        id: cell

                        required property int modelData

                        readonly property bool isToday:
                            modelData !== 0
                            && modelData === flyout.today.getDate()
                            && flyout.viewedMonth.getMonth() === flyout.today.getMonth()
                            && flyout.viewedMonth.getFullYear() === flyout.today.getFullYear()

                        Layout.preferredWidth: 30
                        Layout.preferredHeight: 26
                        radius: 8
                        color: isToday ? Theme.primary : "transparent"

                        Text {
                            anchors.centerIn: parent
                            visible: cell.modelData !== 0
                            text: cell.modelData
                            color: cell.isToday ? "white" : Theme.textPrimary
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}

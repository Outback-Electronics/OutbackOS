pragma Singleton
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.layershell 1.0 as LayerShellQt

// The transient popup side of notifications - shown on the primary output
// only (toasts are ephemeral enough that duplicating them per-monitor would
// mostly just be noise). The persisted history lives in NotificationPanel /
// NotificationServer regardless of what happens here.
Window {
    id: host

    readonly property int defaultDurationMs: 5000

    width: 320
    height: Math.max(1, column.implicitHeight + (toastModel.count > 0 ? 24 : 0))
    visible: toastModel.count > 0
    color: "transparent"
    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityNone

    ListModel {
        id: toastModel
    }

    Connections {
        target: notificationServer

        function onToastRequested(id, appName, summary, body, urgency, expireTimeoutMs) {
            let durationMs = host.defaultDurationMs
            if (expireTimeoutMs > 0) {
                durationMs = expireTimeoutMs
            }

            // Critical notifications (and ones the sender said should never
            // auto-expire) stay until dismissed or closed over D-Bus.
            const neverExpires = urgency === 2 || expireTimeoutMs === 0

            toastModel.append({
                notificationId: id,
                appName: appName,
                summary: summary,
                body: body,
                urgency: urgency,
                expiresAt: neverExpires ? -1 : (Date.now() + durationMs)
            })
        }

        function onNotificationClosed(id, reason) {
            for (let i = toastModel.count - 1; i >= 0; i--) {
                if (toastModel.get(i).notificationId === id) {
                    toastModel.remove(i)
                }
            }
        }
    }

    Timer {
        interval: 500
        running: toastModel.count > 0
        repeat: true
        onTriggered: {
            const now = Date.now()

            for (let i = toastModel.count - 1; i >= 0; i--) {
                const entry = toastModel.get(i)
                if (entry.expiresAt >= 0 && entry.expiresAt <= now) {
                    toastModel.remove(i)
                }
            }
        }
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 8

        Repeater {
            model: toastModel

            delegate: Rectangle {
                id: toast

                required property int index
                required property int notificationId
                required property string appName
                required property string summary
                required property string body
                required property int urgency

                Layout.fillWidth: true
                Layout.preferredHeight: toastContent.implicitHeight + 20
                radius: 12
                color: Theme.surface
                border.color: urgency === 2 ? Theme.primary : Theme.surfaceRaised
                border.width: urgency === 2 ? 2 : 1

                ColumnLayout {
                    id: toastContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 3

                    Text {
                        text: toast.appName
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: toast.summary
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: toast.body
                        visible: toast.body.length > 0
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        notificationServer.dismissById(toast.notificationId)
                        toastModel.remove(toast.index)
                    }
                }
            }
        }
    }
}

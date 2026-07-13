import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.settings
import org.kde.layershell 1.0 as LayerShellQt
import Outback.Taskbar

Window {
    id: menu

    required property color surface
    required property color surfaceRaised
    required property color primary
    required property color textPrimary
    required property color textSecondary
    required property real taskbarHeight

    signal lockRequested()

    readonly property var filteredApps: {
        const q = searchField.text.trim().toLowerCase()
        if (q.length === 0) {
            return Apps.entries
        }
        return Apps.entries.filter(function (app) {
            return app.label.toLowerCase().indexOf(q) !== -1
        })
    }

    readonly property var recentApps: recentsSettings.recentIds
        .map(function (id) {
            return Apps.entries.find(function (app) { return app.id === id })
        })
        .filter(function (app) { return app !== undefined })

    readonly property bool showingRecents: searchField.text.length === 0 && menu.recentApps.length > 0

    readonly property var actionEntries: [
        {
            label: "Lock Screen",
            icon: "icons/lock.svg",
            run: function () {
                menu.close()
                menu.lockRequested()
            }
        },
        {
            label: "Sign Out",
            icon: "icons/signout.svg",
            run: function () {
                systemLauncher.signOut()
                menu.close()
            }
        },
        {
            label: "Restart",
            icon: "icons/restart.svg",
            run: function () {
                systemLauncher.reboot()
                menu.close()
            }
        },
        {
            label: "Shut Down",
            icon: "icons/power.svg",
            run: function () {
                systemLauncher.shutdown()
                menu.close()
            }
        }
    ]

    // Every navigable row (recents, all-apps, and the fixed actions at the
    // bottom) shares this single index space, in on-screen order, so arrow
    // keys can move through the whole panel and mouse hover stays in sync
    // with keyboard focus no matter which section it lands in.
    readonly property int recentsCount: menu.showingRecents ? menu.recentApps.length : 0
    readonly property int allAppsCount: menu.filteredApps.length
    readonly property int totalCount: menu.recentsCount + menu.allAppsCount + menu.actionEntries.length

    property int currentIndex: 0

    // Covers the whole output so a click anywhere outside the panel can be
    // caught and closes the menu; the panel itself is positioned within
    // this via ordinary QML anchors rather than layer-shell anchors.
    width: Screen.width
    height: Screen.height
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop | LayerShellQt.Window.AnchorBottom | LayerShellQt.Window.AnchorLeft | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand

    Settings {
        id: recentsSettings

        category: "startMenu"

        property var recentIds: []
    }

    function toggle() {
        menu.visible = !menu.visible
    }

    function close() {
        menu.visible = false
    }

    function launch(app) {
        systemLauncher.launch(app.command)

        const ids = recentsSettings.recentIds.filter(function (id) {
            return id !== app.id
        })
        ids.unshift(app.id)
        recentsSettings.recentIds = ids.slice(0, 3)

        menu.close()
    }

    function moveCurrent(delta) {
        if (menu.totalCount === 0) {
            return
        }

        menu.currentIndex = (menu.currentIndex + delta + menu.totalCount) % menu.totalCount
    }

    function activateCurrent() {
        const index = menu.currentIndex

        if (index < 0 || index >= menu.totalCount) {
            return
        }

        if (index < menu.recentsCount) {
            menu.launch(menu.recentApps[index])
            return
        }

        const allIndex = index - menu.recentsCount

        if (allIndex < menu.allAppsCount) {
            menu.launch(menu.filteredApps[allIndex])
            return
        }

        menu.actionEntries[allIndex - menu.allAppsCount].run()
    }

    onVisibleChanged: {
        if (visible) {
            searchField.text = ""
            menu.currentIndex = 0
            searchField.forceActiveFocus()
        }
    }

    onTotalCountChanged: {
        if (menu.currentIndex >= menu.totalCount) {
            menu.currentIndex = Math.max(0, menu.totalCount - 1)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: menu.close()
    }

    Rectangle {
        id: panel

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.bottomMargin: menu.taskbarHeight + 12
        width: 300
        height: content.implicitHeight + 24
        radius: 16
        color: menu.surface
        border.color: menu.surfaceRaised
        border.width: 1

        MouseArea {
            // Swallows clicks inside the panel so they don't fall through
            // to the full-screen backdrop and close the menu.
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    radius: 15
                    color: menu.primary

                    Image {
                        anchors.centerIn: parent
                        source: "icons/outback-mark.svg"
                        sourceSize.width: 16
                        sourceSize.height: 16
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "Outback"
                    color: menu.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
            }

            TextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: "Type to search apps"
                selectByMouse: true

                onTextChanged: menu.currentIndex = 0

                Keys.onEscapePressed: menu.close()
                Keys.onUpPressed: menu.moveCurrent(-1)
                Keys.onDownPressed: menu.moveCurrent(1)
                Keys.onReturnPressed: menu.activateCurrent()
                Keys.onEnterPressed: menu.activateCurrent()
            }

            Text {
                text: "Recent"
                color: menu.textSecondary
                font.pixelSize: 11
                Layout.topMargin: 4
                visible: menu.showingRecents
            }

            Repeater {
                model: menu.showingRecents ? menu.recentApps : []

                delegate: AppEntry {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    app: modelData
                    highlighted: menu.currentIndex === index

                    onHovered: menu.currentIndex = index
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                visible: menu.showingRecents
                color: menu.surfaceRaised
            }

            Text {
                text: "All Apps"
                color: menu.textSecondary
                font.pixelSize: 11
                Layout.topMargin: 4
                visible: searchField.text.length === 0
            }

            Repeater {
                model: menu.filteredApps

                delegate: AppEntry {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    app: modelData
                    highlighted: menu.currentIndex === (menu.recentsCount + index)

                    onHovered: menu.currentIndex = menu.recentsCount + index
                }
            }

            Text {
                text: "No apps found"
                color: menu.textSecondary
                font.pixelSize: 13
                Layout.topMargin: 4
                visible: menu.filteredApps.length === 0
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                color: menu.surfaceRaised
            }

            Repeater {
                model: menu.actionEntries

                delegate: MenuEntry {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    label: modelData.label
                    icon: modelData.icon
                    highlighted: menu.currentIndex === (menu.recentsCount + menu.allAppsCount + index)

                    onHovered: menu.currentIndex = menu.recentsCount + menu.allAppsCount + index
                    onActivated: modelData.run()
                }
            }
        }
    }

    component AppEntry: Rectangle {
        id: entry

        required property var app
        property bool highlighted: false

        signal hovered()

        Layout.preferredHeight: 44
        radius: 10
        color: (entry.highlighted || entryMouse.containsMouse) ? menu.surfaceRaised : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 8
                color: entry.app.accent

                Image {
                    anchors.centerIn: parent
                    source: entry.app.icon
                    sourceSize.width: 15
                    sourceSize.height: 15
                }
            }

            Text {
                Layout.fillWidth: true
                text: entry.app.label
                color: menu.textPrimary
                font.pixelSize: 14
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: entryMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: entry.hovered()
            onClicked: menu.launch(entry.app)
        }
    }

    component MenuEntry: Rectangle {
        id: entry

        required property string label
        required property string icon
        property bool highlighted: false

        signal activated()
        signal hovered()

        Layout.preferredHeight: 40
        radius: 10
        color: (entry.highlighted || entryMouse.containsMouse) ? menu.surfaceRaised : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Image {
                source: entry.icon
                sourceSize.width: 18
                sourceSize.height: 18
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
            }

            Text {
                Layout.fillWidth: true
                text: entry.label
                color: menu.textPrimary
                font.pixelSize: 14
            }
        }

        MouseArea {
            id: entryMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: entry.hovered()
            onClicked: entry.activated()
        }
    }
}

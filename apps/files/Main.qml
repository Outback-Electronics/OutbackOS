import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root

    width: 1100
    height: 720
    visible: true

    title: "Outback Files"
    color: "#0D1115"

    property color sidebarColor: "#151B21"
    property color surfaceColor: "#1B2229"
    property color raisedColor: "#252E36"
    property color primaryColor: "#D9732F"
    property color textPrimaryColor: "#F4F6F7"
    property color textSecondaryColor: "#AEB8C0"

    property string currentPath: filesBackend.homePath()
    property string selectedPath: ""
    property string clipboardPath: ""
    property var entries: []

    function refresh() {
        entries = filesBackend.listDirectory(currentPath)
        selectedPath = ""
    }

    function navigateTo(path) {
        currentPath = path
        refresh()
    }

    Component.onCompleted: refresh()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
            color: root.sidebarColor

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 4

                Text {
                    text: "Places"
                    color: root.textSecondaryColor
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                PlaceRow {
                    label: "Home"
                    path: filesBackend.homePath()
                }

                Item {
                    Layout.preferredHeight: 8
                }

                Text {
                    text: "Volumes"
                    color: root.textSecondaryColor
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Repeater {
                    model: filesBackend.listVolumes()

                    delegate: PlaceRow {
                        required property var modelData

                        label: modelData.name.length > 0
                               ? modelData.name
                               : modelData.path
                        path: modelData.path
                        ejectable: !modelData.isRoot
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                color: root.surfaceColor

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Button {
                        text: "Up"
                        enabled: root.currentPath !== "/"
                        onClicked: root.navigateTo(
                            filesBackend.parentPath(root.currentPath)
                        )
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.currentPath
                        color: root.textPrimaryColor
                        font.pixelSize: 14
                        elide: Text.ElideMiddle
                    }

                    Button {
                        text: "New Folder"
                        onClicked: newFolderDialog.open()
                    }

                    Button {
                        text: "Rename"
                        enabled: root.selectedPath.length > 0
                        onClicked: renameDialog.open()
                    }

                    Button {
                        text: "Copy"
                        enabled: root.selectedPath.length > 0
                        onClicked: root.clipboardPath = root.selectedPath
                    }

                    Button {
                        text: "Paste"
                        enabled: root.clipboardPath.length > 0
                        onClicked: {
                            filesBackend.copyPath(root.clipboardPath, root.currentPath)
                            root.refresh()
                        }
                    }

                    Button {
                        text: "Delete"
                        enabled: root.selectedPath.length > 0
                        onClicked: {
                            filesBackend.moveToTrash(root.selectedPath)
                            root.refresh()
                        }
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                model: root.entries

                delegate: Rectangle {
                    required property var modelData

                    width: ListView.view.width
                    height: 44

                    color: root.selectedPath === modelData.path
                           ? root.raisedColor
                           : rowMouse.containsMouse
                               ? "#202830"
                               : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Text {
                            text: modelData.isDir ? "📁" : "📄"
                            font.pixelSize: 15
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            color: root.textPrimaryColor
                            font.pixelSize: 14
                        }

                        Text {
                            text: modelData.isDir ? "" : (modelData.size + " bytes")
                            color: root.textSecondaryColor
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.selectedPath = modelData.path

                        onDoubleClicked: {
                            if (modelData.isDir) {
                                root.navigateTo(modelData.path)
                            }
                        }
                    }
                }
            }
        }
    }

    component PlaceRow: Rectangle {
        id: place

        property string label
        property string path
        property bool ejectable: false

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 10

        color: root.currentPath === path
               ? root.raisedColor
               : placeMouse.containsMouse
                   ? "#202830"
                   : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10

            Text {
                Layout.fillWidth: true
                text: place.label
                color: root.textPrimaryColor
                font.pixelSize: 14
                elide: Text.ElideRight
            }

            Button {
                visible: place.ejectable
                text: "Eject"

                onClicked: {
                    filesBackend.ejectVolume(place.path)
                }
            }
        }

        MouseArea {
            id: placeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.navigateTo(place.path)
        }
    }

    Dialog {
        id: newFolderDialog

        title: "New Folder"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok | Dialog.Cancel

        contentItem: TextField {
            id: newFolderField
            width: 260
        }

        onOpened: newFolderField.text = ""

        onAccepted: {
            filesBackend.createFolder(root.currentPath, newFolderField.text)
            root.refresh()
        }
    }

    Dialog {
        id: renameDialog

        title: "Rename"
        modal: true
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok | Dialog.Cancel

        contentItem: TextField {
            id: renameField
            width: 260
        }

        onOpened: {
            const parts = root.selectedPath.split("/")
            renameField.text = parts[parts.length - 1]
        }

        onAccepted: {
            filesBackend.renamePath(root.selectedPath, renameField.text)
            root.refresh()
        }
    }
}

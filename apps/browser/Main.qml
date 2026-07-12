import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine

ApplicationWindow {
    id: root

    width: 1200
    height: 780
    visible: true

    title: "Outback Browser"
    color: "#0D1115"

    property color surfaceColor: "#1B2229"
    property color raisedColor: "#252E36"
    property color primaryColor: "#D9732F"
    property color textPrimaryColor: "#F4F6F7"
    property color textSecondaryColor: "#AEB8C0"

    property int currentTabIndex: 0

    WebEngineProfile {
        id: hardenedProfile

        offTheRecord: true
        httpCacheType: WebEngineProfile.MemoryHttpCache
        persistentCookiesPolicy: WebEngineProfile.NoPersistentCookies
        spellCheckEnabled: false
    }

    ListModel {
        id: tabsModel

        ListElement {
            url: "https://start.outbackos.local/"
            title: "New Tab"
        }
    }

    function currentView() {
        return tabRepeater.itemAt(root.currentTabIndex)
    }

    function openNewTab(url) {
        tabsModel.append({
            url: url && url.length > 0 ? url : "https://start.outbackos.local/",
            title: "New Tab"
        })
        root.currentTabIndex = tabsModel.count - 1
    }

    function closeTab(index) {
        if (tabsModel.count <= 1) {
            return
        }

        tabsModel.remove(index)

        if (root.currentTabIndex >= tabsModel.count) {
            root.currentTabIndex = tabsModel.count - 1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: root.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                Repeater {
                    model: tabsModel

                    delegate: Rectangle {
                        required property string title
                        required property int index

                        Layout.preferredWidth: 180
                        Layout.fillHeight: true
                        radius: 8

                        color: root.currentTabIndex === index
                               ? root.raisedColor
                               : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6

                            Text {
                                Layout.fillWidth: true
                                text: title
                                color: root.textPrimaryColor
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Button {
                                text: "×"
                                flat: true
                                onClicked: root.closeTab(index)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: root.currentTabIndex = index
                            z: -1
                        }
                    }
                }

                Button {
                    text: "+"
                    onClicked: root.openNewTab("")
                }

                Item {
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: root.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Button {
                    text: "◀"
                    enabled: root.currentView() && root.currentView().canGoBack
                    onClicked: root.currentView().goBack()
                }

                Button {
                    text: "▶"
                    enabled: root.currentView() && root.currentView().canGoForward
                    onClicked: root.currentView().goForward()
                }

                Button {
                    text: "⟳"
                    onClicked: root.currentView().reload()
                }

                TextField {
                    id: addressField
                    Layout.fillWidth: true
                    text: tabsModel.get(root.currentTabIndex).url

                    onAccepted: {
                        let target = text.trim()

                        if (!target.includes("://")) {
                            target = "https://" + target
                        }

                        root.currentView().url = target
                    }
                }

                Button {
                    text: "☆"
                    onClicked: browserBackend.addBookmark(
                        root.currentView().title,
                        root.currentView().url.toString()
                    )
                }

                Button {
                    text: "Bookmarks"
                    onClicked: bookmarksMenu.open()
                }

                Menu {
                    id: bookmarksMenu

                    Repeater {
                        model: browserBackend.bookmarks()

                        delegate: MenuItem {
                            required property var modelData

                            text: modelData.title
                            onTriggered: root.currentView().url = modelData.url
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                id: tabRepeater
                model: tabsModel

                delegate: WebEngineView {
                    id: webView

                    required property int index

                    anchors.fill: parent
                    visible: root.currentTabIndex === index

                    profile: hardenedProfile
                    settings.pluginsEnabled: false

                    Component.onCompleted: {
                        const initialUrl = model.url

                        if (
                            initialUrl
                            && initialUrl.indexOf("outbackos.local") === -1
                        ) {
                            webView.url = initialUrl
                        } else {
                            loadHtml(
                                "<html><body style='background:#0D1115;color:#F4F6F7;"
                                + "font-family:sans-serif;display:flex;align-items:center;"
                                + "justify-content:center;height:100vh;margin:0'>"
                                + "<h1>Outback Browser</h1></body></html>",
                                "https://start.outbackos.local/"
                            )
                        }
                    }

                    onTitleChanged: {
                        tabsModel.setProperty(index, "title", title)
                    }

                    onUrlChanged: {
                        tabsModel.setProperty(index, "url", url.toString())

                        if (index === root.currentTabIndex) {
                            addressField.text = url.toString()
                        }
                    }
                }
            }
        }
    }
}

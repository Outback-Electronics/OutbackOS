import QtQuick 2.9
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#101418"

            Text {
                anchors.centerIn: parent
                width: parent.width * 0.7
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#F4F6F7"
                font.pixelSize: 28
                text: "Outback OS is built for where the signal ends — local-first, no cloud account required."
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#101418"

            Text {
                anchors.centerIn: parent
                width: parent.width * 0.7
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#F4F6F7"
                font.pixelSize: 28
                text: "Your files, terminal and browser stay on this device. Nothing phones home."
            }
        }
    }

    function onActivate() {}
    function onLeave() {}
}

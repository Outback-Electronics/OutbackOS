import QtQuick
import QtQuick.Window

Window {
    id: window

    width: 960
    height: 600
    visible: true
    title: "Outback OS — Boot Splash Preview"
    color: "#0D1115"

    readonly property color accentColour: "#D9732F"
    readonly property color textPrimary: "#F4F6F7"
    readonly property color textSecondary: "#AEB8C0"

    Rectangle {
        id: backgroundRect

        anchors.fill: parent
        focus: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#182027" }
            GradientStop { position: 1.0; color: "#0D1115" }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: introSequence.start()
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Space) {
                introSequence.start()
            }
        }
    }

    Item {
        id: badge

        anchors.centerIn: parent
        width: 260
        height: 260

        // Soft breathing glow behind the ring, drawn as a radial gradient
        Canvas {
            id: glowCanvas

            anchors.fill: parent
            anchors.margins: -70

            property real intensity: 0.6

            onIntensityChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const cx = width / 2
                const cy = height / 2
                const radius = Math.min(width, height) / 2

                const gradient = ctx.createRadialGradient(
                    cx, cy, radius * 0.15,
                    cx, cy, radius
                )
                gradient.addColorStop(0, Qt.rgba(0.851, 0.451, 0.184, 0.35 * intensity))
                gradient.addColorStop(1, Qt.rgba(0.851, 0.451, 0.184, 0))

                ctx.fillStyle = gradient
                ctx.fillRect(0, 0, width, height)
            }

            SequentialAnimation on intensity {
                id: breatheAnimation

                loops: Animation.Infinite
                running: false

                NumberAnimation { to: 1.0; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.6; duration: 1400; easing.type: Easing.InOutSine }
            }
        }

        // The ring itself: a track colour plus an animated accent-coloured
        // sweep that "draws itself in" from 0 to a full circle.
        Canvas {
            id: ringCanvas

            anchors.fill: parent
            property real sweep: 0

            onSweepChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const cx = width / 2
                const cy = height / 2
                const radius = Math.min(width, height) / 2 - 12

                ctx.lineWidth = 10
                ctx.lineCap = "round"

                ctx.strokeStyle = "#252E36"
                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                ctx.stroke()

                if (sweep > 0) {
                    ctx.strokeStyle = window.accentColour
                    ctx.beginPath()
                    ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + sweep)
                    ctx.stroke()
                }
            }
        }

        Row {
            id: mark

            anchors.centerIn: parent
            spacing: 2
            opacity: 0
            scale: 0.8

            Text {
                text: "O"
                color: window.textPrimary
                font.pixelSize: 84
                font.bold: true
            }

            Text {
                text: "S"
                color: window.accentColour
                font.pixelSize: 84
                font.bold: true
            }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: badge.bottom
        anchors.topMargin: 36
        spacing: 8

        Text {
            id: wordmark

            anchors.horizontalCenter: parent.horizontalCenter
            text: "OUTBACK OS"
            color: window.textPrimary
            font.pixelSize: 26
            font.bold: true
            font.letterSpacing: 4
            opacity: 0
        }

        Text {
            id: tagline

            anchors.horizontalCenter: parent.horizontalCenter
            text: "Built for where the signal ends."
            color: window.textSecondary
            font.pixelSize: 15
            opacity: 0
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        text: "Click or press Space to replay"
        color: window.textSecondary
        font.pixelSize: 12
        opacity: 0.6
    }

    SequentialAnimation {
        id: introSequence

        PropertyAction { target: breatheAnimation; property: "running"; value: false }
        PropertyAction { target: ringCanvas; property: "sweep"; value: 0 }
        PropertyAction { target: mark; property: "opacity"; value: 0 }
        PropertyAction { target: mark; property: "scale"; value: 0.8 }
        PropertyAction { target: wordmark; property: "opacity"; value: 0 }
        PropertyAction { target: tagline; property: "opacity"; value: 0 }
        PropertyAction { target: glowCanvas; property: "intensity"; value: 0.6 }

        NumberAnimation {
            target: ringCanvas
            property: "sweep"
            to: Math.PI * 2
            duration: 1100
            easing.type: Easing.InOutCubic
        }

        ParallelAnimation {
            NumberAnimation { target: mark; property: "opacity"; to: 1; duration: 350 }
            NumberAnimation {
                target: mark
                property: "scale"
                to: 1
                duration: 350
                easing.type: Easing.OutBack
            }
        }

        PauseAnimation { duration: 100 }

        NumberAnimation { target: wordmark; property: "opacity"; to: 1; duration: 400 }
        NumberAnimation { target: tagline; property: "opacity"; to: 1; duration: 400 }

        PropertyAction { target: breatheAnimation; property: "running"; value: true }
    }

    Component.onCompleted: introSequence.start()
}

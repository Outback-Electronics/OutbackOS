import QtQuick
import QtQuick.Window

Window {
    id: window

    width: 960
    height: 600
    visible: true
    title: "Outback OS — Boot Splash Preview"
    color: "#030811"

    // Genuine pixel-exact vector reconstruction of the approved logo, split
    // into independently-loadable object files (splash/layers/*.svg) - every
    // shape (ring, sky, stars, kangaroo, windmill, mark-space, and every
    // individual letter) is its own file, verified to recombine into the
    // source image with zero differing pixels. No bitmap asset anywhere.
    readonly property real badgeSize: 380
    readonly property real aspect: 461 / 492

    readonly property var outbackLetters: [
        "outback-letter-1", "outback-letter-2", "outback-letter-3",
        "outback-letter-4", "outback-letter-5", "outback-letter-6",
        "outback-letter-7"
    ]
    readonly property var osLetters: ["os-letter-1", "os-letter-2"]
    readonly property var tagline1Letters: [
        "tagline1-letter-1", "tagline1-letter-2", "tagline1-letter-3",
        "tagline1-letter-4", "tagline1-letter-5", "tagline1-letter-6",
        "tagline1-letter-7", "tagline1-letter-8", "tagline1-letter-9",
        "tagline1-letter-10", "tagline1-letter-11", "tagline1-letter-12",
        "tagline1-letter-13"
    ]
    readonly property var tagline2Letters: [
        "tagline2-letter-1", "tagline2-letter-2", "tagline2-letter-3",
        "tagline2-letter-4", "tagline2-letter-5", "tagline2-letter-6",
        "tagline2-letter-7", "tagline2-letter-8", "tagline2-letter-9",
        "tagline2-letter-10", "tagline2-letter-11", "tagline2-letter-12",
        "tagline2-letter-13"
    ]

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#081524" }
            GradientStop { position: 1.0; color: "#030811" }
        }

        focus: true

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

    Canvas {
        id: glowCanvas

        anchors.centerIn: parent
        width: window.badgeSize * 1.7
        height: window.badgeSize * 1.7 * window.aspect

        property real intensity: 0.5

        onIntensityChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const cx = width / 2
            const cy = height / 2
            const radius = Math.min(width, height) / 2

            const gradient = ctx.createRadialGradient(
                cx, cy, radius * 0.2,
                cx, cy, radius
            )
            gradient.addColorStop(0, Qt.rgba(0.03, 0.596, 0.992, 0.32 * intensity))
            gradient.addColorStop(1, Qt.rgba(0.03, 0.596, 0.992, 0))

            ctx.fillStyle = gradient
            ctx.fillRect(0, 0, width, height)
        }

        SequentialAnimation on intensity {
            id: breatheAnimation

            loops: Animation.Infinite
            running: false

            NumberAnimation { to: 1.0; duration: 1700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.5; duration: 1700; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: badge

        anchors.centerIn: parent
        width: window.badgeSize
        height: window.badgeSize * window.aspect

        Image { anchors.fill: parent; source: "layers/background.svg"; smooth: true }

        Item {
            id: sceneLayer
            anchors.fill: parent
            opacity: 0

            Image { anchors.fill: parent; source: "layers/sky.svg"; smooth: true }
            Image { anchors.fill: parent; source: "layers/stars.svg"; smooth: true }
            Image { anchors.fill: parent; source: "layers/kangaroo.svg"; smooth: true }
            Image { anchors.fill: parent; source: "layers/windmill.svg"; smooth: true }
        }

        Image {
            id: ringLayer
            anchors.fill: parent
            source: "layers/ring.svg"
            smooth: true
            opacity: 0
            scale: 0.9

            SequentialAnimation on rotation {
                id: idleSpin

                loops: Animation.Infinite
                running: false

                NumberAnimation { from: 0; to: 360; duration: 9000; easing.type: Easing.Linear }
            }
        }

        Item {
            id: markLayer
            anchors.fill: parent
            opacity: 0
            scale: 0.92

            Image { anchors.fill: parent; source: "layers/mark-space.svg"; smooth: true }
            Image { anchors.fill: parent; source: "layers/letter-o-big.svg"; smooth: true }
            Image { anchors.fill: parent; source: "layers/letter-s-big.svg"; smooth: true }

            Repeater {
                model: window.outbackLetters
                delegate: Image {
                    required property string modelData
                    anchors.fill: parent
                    source: "layers/" + modelData + ".svg"
                    smooth: true
                }
            }

            Repeater {
                model: window.osLetters
                delegate: Image {
                    required property string modelData
                    anchors.fill: parent
                    source: "layers/" + modelData + ".svg"
                    smooth: true
                }
            }

            Repeater {
                model: window.tagline1Letters
                delegate: Image {
                    required property string modelData
                    anchors.fill: parent
                    source: "layers/" + modelData + ".svg"
                    smooth: true
                }
            }

            Repeater {
                model: window.tagline2Letters
                delegate: Image {
                    required property string modelData
                    anchors.fill: parent
                    source: "layers/" + modelData + ".svg"
                    smooth: true
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        text: "Click or press Space to replay"
        color: "#8FA5BD"
        font.pixelSize: 12
        opacity: 0.6
    }

    SequentialAnimation {
        id: introSequence

        PropertyAction { target: breatheAnimation; property: "running"; value: false }
        PropertyAction { target: idleSpin; property: "running"; value: false }
        PropertyAction { target: glowCanvas; property: "intensity"; value: 0.5 }
        PropertyAction { target: sceneLayer; property: "opacity"; value: 0 }
        PropertyAction { target: ringLayer; property: "opacity"; value: 0 }
        PropertyAction { target: ringLayer; property: "scale"; value: 0.9 }
        PropertyAction { target: ringLayer; property: "rotation"; value: 0 }
        PropertyAction { target: markLayer; property: "opacity"; value: 0 }
        PropertyAction { target: markLayer; property: "scale"; value: 0.92 }

        NumberAnimation {
            target: sceneLayer
            property: "opacity"
            to: 1
            duration: 500
            easing.type: Easing.OutCubic
        }

        ParallelAnimation {
            NumberAnimation {
                target: ringLayer
                property: "opacity"
                to: 1
                duration: 650
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: ringLayer
                property: "scale"
                to: 1.0
                duration: 650
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: ringLayer
                property: "rotation"
                from: -50
                to: 0
                duration: 650
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation { target: markLayer; property: "opacity"; to: 1; duration: 400 }
            NumberAnimation {
                target: markLayer
                property: "scale"
                to: 1.0
                duration: 400
                easing.type: Easing.OutBack
            }
        }

        PropertyAction { target: breatheAnimation; property: "running"; value: true }
        PropertyAction { target: idleSpin; property: "running"; value: true }
    }

    Component.onCompleted: introSequence.start()
}

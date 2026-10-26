/*
    44OS NOVA Plasma startup splash.
    ksplashqml advances `stage` from 1 to 6 while the session starts.
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick

Rectangle {
    id: root
    color: "#080D18"

    property int stage

    onStageChanged: {
        if (stage === 2) {
            introAnimation.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: glow
            anchors.centerIn: mark
            width: mark.width * 1.8
            height: width
            source: "images/44os-mark.png"
            sourceSize.width: 256
            opacity: 0.25
            scale: 1.0
            SequentialAnimation on opacity {
                running: true
                loops: Animation.Infinite
                NumberAnimation { from: 0.12; to: 0.35; duration: 1100; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.35; to: 0.12; duration: 1100; easing.type: Easing.InOutSine }
            }
        }

        Image {
            id: mark
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -root.height * 0.06
            width: Math.round(root.height * 0.11)
            height: width
            source: "images/44os-mark.png"
            sourceSize.width: 256
            smooth: true
        }

        Rectangle {
            id: track
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: mark.bottom
            anchors.topMargin: root.height * 0.06
            width: Math.round(root.width * 0.12)
            height: 4
            radius: 2
            color: "#18243A"

            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, (root.stage - 1) / 5))
                height: parent.height
                radius: 2
                color: "#65A8FF"
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.height * 0.05
            width: Math.round(root.height * 0.12)
            fillMode: Image.PreserveAspectFit
            source: "images/44os-nova-wordmark.png"
            sourceSize.width: 620
            opacity: 0.85
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: 500
        easing.type: Easing.InOutQuad
    }
}

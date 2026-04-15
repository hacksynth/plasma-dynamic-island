pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami

// Horizontally scrolling text. If text fits within width, displays
// normally (no animation). If overflows, scrolls left after a hold,
// snaps back to start, holds again, repeats.
//
// Edges fade to `edgeColor` over `edgeFadePx` so characters slide in
// and out softly rather than being hard-cut at the clipping box —
// iOS marquee style. edgeColor defaults to the island background so
// the fade merges into the capsule; override when embedding on any
// other backdrop.
Item {
    id: root

    property string text: ""
    property color color: "#ffffff"
    property int pixelSize: 13
    property int weight: Font.Normal
    property int holdMs: 1800
    property int speedPxPerSec: 30

    // Edge fade — caller sets edgeColor to the background the Marquee is
    // painted over (typically the capsule bg). Marquee is in components/
    // and avoids depending on the Theme singleton so it stays portable.
    property color edgeColor: "#131316"
    property int edgeFadePx: 12

    clip: true

    readonly property bool _overflows: textItem.implicitWidth > width

    on_OverflowsChanged: _restart()
    onTextChanged: _restart()
    onWidthChanged: _restart()

    function _restart() {
        scrollAnim.stop()
        textItem.x = 0
        if (_overflows && width > 0) {
            holdTimer.restart()
        }
    }

    Text {
        id: textItem
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.color
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.family: Kirigami.Theme.defaultFont.family
    }

    // Left fade — transparent on inner edge, opaque on outer
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.edgeFadePx
        visible: root._overflows
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.edgeColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Right fade — opaque on outer, transparent on inner
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.edgeFadePx
        visible: root._overflows
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: root.edgeColor }
        }
    }

    Timer {
        id: holdTimer
        interval: root.holdMs
        repeat: false
        onTriggered: scrollAnim.start()
    }

    NumberAnimation {
        id: scrollAnim
        target: textItem
        property: "x"
        from: 0
        to: -(textItem.implicitWidth - root.width + 12)
        duration: Math.max(1500,
            ((textItem.implicitWidth - root.width) / root.speedPxPerSec) * 1000)
        easing.type: Easing.InOutQuad
        onFinished: returnTimer.restart()
    }

    Timer {
        id: returnTimer
        interval: root.holdMs
        repeat: false
        onTriggered: {
            textItem.x = 0
            if (root._overflows) holdTimer.restart()
        }
    }

    Component.onCompleted: _restart()
}

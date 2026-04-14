pragma Singleton

import QtQuick

QtObject {
    readonly property color islandBg: "#0a0a0a"

    readonly property int idleWidth: 140
    readonly property int fallbackHeight: 28
    readonly property int panelGap: 4

    readonly property real springSpring: 3.0
    readonly property real springDamping: 0.28
    readonly property real springEpsilon: 0.01

    readonly property color strokeColor: "#25ffffff"
    readonly property int strokeWidth: 1

    readonly property color glossTop: "#12ffffff"
    readonly property real glossHeightRatio: 0.5

    // PHASE-2: re-introduced for expanded states that overflow panel
    // readonly property int shadowPad: 32
    // readonly property real shadowBlur: 1.0
    // readonly property color shadowColor: "#80000000"
    // readonly property real shadowOffsetY: 8
    // readonly property real shadowOffsetX: 0
}

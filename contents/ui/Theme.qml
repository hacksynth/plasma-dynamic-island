pragma Singleton

import QtQuick

QtObject {
    readonly property color islandBg: "#131316"

    // Visually tuned. Not aspect-locked to panelThickness — the capsule's
    // idle shape is a fixed strip, not a proportional pill.
    readonly property int idleWidth: 140
    readonly property int fallbackHeight: 28
    readonly property int panelGap: 4

    readonly property real springSpring: 3.0
    readonly property real springDamping: 0.28
    readonly property real springEpsilon: 0.01

    // ---- Shared design tokens used across content/*.qml ----
    // Colors carry semantic names; fillWhite and textPrimary share a
    // value today but may diverge if we ever introduce tinted variants.
    readonly property color textPrimary: "#f5f5f5"
    readonly property color textSecondary: "#a0a0a0"
    readonly property color fillWhite: "#f5f5f5"
    readonly property color trackWhite: "#30ffffff"

    readonly property int summaryPixelSize: 13
    readonly property int bodyPixelSize: 10
    readonly property int osdTextPixelSize: 13
    readonly property int progressSummaryPixelSize: 12
    readonly property int countdownPixelSize: 14
    readonly property int pctLabelPixelSize: 11

    readonly property int progressBarHeight: 4

    // IslandCapsule contentLoader left/right margin as a fraction of
    // capsule height. Keeps text from touching the rounded-end curves.
    readonly property real contentBreathingRatio: 0.25
}

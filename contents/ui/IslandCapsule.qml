import QtQuick

// Pure presentational capsule. No state, no animation, no controller
// access. Sized by parent via width/height. Used by both the in-panel
// anchor (IslandShell) and the overflow surface (IslandExpandedWindow,
// Phase 2 step 3c).
Item {
    id: capsule
    clip: true

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.islandBg
        radius: parent.height / 2
        antialiasing: true
    }
}

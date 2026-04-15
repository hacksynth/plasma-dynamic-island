import QtQuick

// Pure presentational capsule. No state, no animation, no controller
// access. Sized by parent via width/height. Used by both the in-panel
// anchor (IslandShell) and the overflow surface (IslandExpandedWindow).
//
// The contentLoader exposes alias properties so the caller can:
//   - set contentSource to load a per-state UI (content/*.qml)
//   - pass contentData to that UI
//   - animate contentOpacity for fade-in/out
// IslandShell leaves these unset so the in-panel capsule stays solid.
Item {
    id: capsule
    clip: true

    property alias contentSource: contentLoader.source
    property alias contentData: contentLoader.contentData
    property alias contentOpacity: contentLoader.opacity

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.islandBg
        radius: parent.height / 2
        antialiasing: true
    }

    Loader {
        id: contentLoader
        anchors.fill: parent
        anchors.leftMargin: parent.height * 0.15
        anchors.rightMargin: parent.height * 0.15
        opacity: 0

        property var contentData: ({})

        onLoaded: if (item) item.notifData = contentLoader.contentData
        onContentDataChanged: if (item) item.notifData = contentLoader.contentData

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }
}

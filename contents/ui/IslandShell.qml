import QtQuick

Item {
    id: shell

    implicitWidth: IslandController.targetWidth
    implicitHeight: IslandController.targetHeight

    Item {
        id: capsule
        anchors.fill: parent
        clip: true

        readonly property real radius: height / 2

        Behavior on width  { SpringAnimation { spring: Theme.springSpring; damping: Theme.springDamping; epsilon: Theme.springEpsilon } }
        Behavior on height { SpringAnimation { spring: Theme.springSpring; damping: Theme.springDamping; epsilon: Theme.springEpsilon } }

        Rectangle {
            id: bg
            anchors.fill: parent
            color: Theme.islandBg
            radius: capsule.radius
            antialiasing: true
        }
    }
}

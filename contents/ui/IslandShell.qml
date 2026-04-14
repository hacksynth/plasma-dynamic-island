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

        Rectangle {
            id: gloss
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * Theme.glossHeightRatio
            radius: capsule.radius
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.glossTop }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            id: stroke
            anchors.fill: parent
            color: "transparent"
            radius: capsule.radius
            antialiasing: true
            border.color: Theme.strokeColor
            border.width: Theme.strokeWidth
        }
    }
}

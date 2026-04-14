import QtQuick

Item {
    id: shell

    implicitWidth: IslandController.targetWidth
    implicitHeight: IslandController.targetHeight

    Item {
        id: capsule
        width: IslandController.targetWidth
        height: IslandController.targetHeight
        anchors.centerIn: parent
        clip: true

        Behavior on width {
            SpringAnimation {
                spring: Theme.springSpring
                damping: Theme.springDamping
                epsilon: Theme.springEpsilon
            }
        }
        Behavior on height {
            SpringAnimation {
                spring: Theme.springSpring
                damping: Theme.springDamping
                epsilon: Theme.springEpsilon
            }
        }

        Rectangle {
            id: bg
            anchors.fill: parent
            color: Theme.islandBg
            radius: height / 2
            antialiasing: true
        }
    }
}

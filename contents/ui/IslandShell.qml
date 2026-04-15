import QtQuick

Item {
    id: shell

    implicitWidth: IslandController.targetWidth
    implicitHeight: IslandController.targetHeight

    IslandCapsule {
        id: capsule
        width: IslandController.targetWidth
        height: IslandController.targetHeight
        anchors.centerIn: parent

        // Spring params live in Theme.qml. Do NOT override per-state — the
        // whole island must feel consistent across all transitions.
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
    }
}

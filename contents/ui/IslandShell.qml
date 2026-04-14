import QtQuick
import QtQuick.Effects

Item {
    id: shell

    implicitWidth: IslandController.targetWidth + Theme.shadowPad * 2
    implicitHeight: IslandController.targetHeight + Theme.shadowPad * 2 + Theme.panelGap

    Item {
        id: capsule
        width: IslandController.targetWidth
        height: IslandController.targetHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Theme.shadowPad + Theme.panelGap

        Behavior on width  { SpringAnimation { spring: Theme.springSpring; damping: Theme.springDamping; epsilon: Theme.springEpsilon } }
        Behavior on height { SpringAnimation { spring: Theme.springSpring; damping: Theme.springDamping; epsilon: Theme.springEpsilon } }

        // PHASE-2 TODO: once width/height animates, layer.enabled on the morphing
        // capsule will realloc FBO every frame. Move layer.enabled to a fixed-size
        // outer container and let the inner rect animate freely inside it.
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            color: Theme.islandBg
            radius: height / 2
            antialiasing: true
        }
    }

    MultiEffect {
        anchors.fill: capsule
        source: capsule
        shadowEnabled: true
        blurEnabled: false
        shadowBlur: Theme.shadowBlur
        shadowColor: Theme.shadowColor
        shadowVerticalOffset: Theme.shadowOffsetY
        shadowHorizontalOffset: Theme.shadowOffsetX
        z: -1
    }
}

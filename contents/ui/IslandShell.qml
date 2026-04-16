import QtQuick

// IslandShell stays static at panel-slot size. All morphing happens
// in IslandExpandedWindow's own capsule (cross-surface handoff;
// IslandShell is opacity=0 during expand). No SpringAnimation here.
Item {
    id: shell

    implicitWidth: IslandController.targetWidth
    implicitHeight: IslandController.targetHeight

    IslandCapsule {
        id: capsule
        width: IslandController.targetWidth
        height: IslandController.targetHeight
        anchors.centerIn: parent
    }
}

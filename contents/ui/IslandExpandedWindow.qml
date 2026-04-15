import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmaCore.Dialog {
    id: dialog

    location: Plasmoid.location
    type: PlasmaCore.Dialog.Dock
    backgroundHints: PlasmaCore.Dialog.NoBackground
    hideOnWindowDeactivate: false
    outputOnly: true
    flags: Qt.WindowStaysOnTopHint
         | Qt.WindowDoesNotAcceptFocus
         | Qt.BypassWindowManagerHint

    property Item shellRef: null

    // Phase state machine drives capsule dimensions. String values:
    //   "idle"    — 140 x panelSlotHeight (pre-expand, post-collapse)
    //   "target"  — stateDef width x stateDef expandedHeight
    property string _phase: "idle"

    mainItem: Item {
        id: expandedRoot
        // Fixed max-size container. Dialog window doesn't track mainItem
        // implicitWidth changes at runtime, so we pre-size the surface to fit
        // any state's expanded dimensions. Capsule centers inside; excess area
        // is transparent (backgroundHints=NoBackground). Centering also makes
        // the capsule grow symmetrically rather than left-aligned off
        // visualParent.
        implicitWidth: 300
        implicitHeight: 80

        IslandCapsule {
            id: capsuleExpanded
            anchors.centerIn: parent

            width: dialog._phase === "target"
                ? IslandController.targetWidth
                : Theme.idleWidth
            height: dialog._phase === "target"
                ? IslandController.targetHeight
                : IslandController._panelSlotHeight

            Behavior on width {
                id: widthBehavior
                enabled: false
                SpringAnimation {
                    id: widthSpring
                    spring: Theme.springSpring
                    damping: Theme.springDamping
                    epsilon: Theme.springEpsilon
                }
            }
            Behavior on height {
                id: heightBehavior
                enabled: false
                SpringAnimation {
                    spring: Theme.springSpring
                    damping: Theme.springDamping
                    epsilon: Theme.springEpsilon
                }
            }
        }
    }

    property bool _controllerExpanded: IslandController.expanded

    on_ControllerExpandedChanged: {
        if (_controllerExpanded) {
            _beginExpand()
        } else {
            _beginCollapse()
        }
    }

    function _beginExpand() {
        // Phase β: reset capsule to idle size with Behavior disabled.
        widthBehavior.enabled = false
        heightBehavior.enabled = false
        _phase = "idle"
        dialog.show()

        Qt.callLater(function() {
            // Phase γ: hide in-panel shell; Dialog capsule now represents
            // the island alone.
            if (dialog.shellRef) {
                dialog.shellRef.opacity = 0
            }
            // Enable Behavior on this frame; the 16ms Timer below defers the
            // target assignment to the next frame so QML has a tick to attach
            // the Behavior watcher before the binding change fires.
            widthBehavior.enabled = true
            heightBehavior.enabled = true
            deltaTimer.restart()
        })
    }

    function _beginCollapse() {
        // Behaviors animate the capsule back to idle dimensions. Final cleanup
        // (restore shell opacity + dialog.close()) runs when the spring stops.
        widthBehavior.enabled = true
        heightBehavior.enabled = true
        _phase = "idle"
    }

    data: [
        Timer {
            id: deltaTimer
            interval: 16
            repeat: false
            onTriggered: dialog._phase = "target"
        },
        Connections {
            target: widthSpring
            function onRunningChanged() {
                if (!widthSpring.running && !IslandController.expanded) {
                    if (dialog.shellRef) {
                        dialog.shellRef.opacity = 1
                    }
                    dialog.close()
                    widthBehavior.enabled = false
                    heightBehavior.enabled = false
                }
            }
        }
    ]

    // PlasmaCore.Dialog overrides visible; binding it doesn't hide the window.
    // Force-close at construction regardless of QQuickWindow default so the
    // island stays invisible until the first expand request.
    Component.onCompleted: dialog.close()
}

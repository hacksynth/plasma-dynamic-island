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

    // Display state survives the collapse animation: we keep the content
    // source and data until spring finishes so the content can fade out
    // instead of disappearing on the same frame as activeState -> "idle".
    property string _displayState: "idle"
    property var _displayData: ({})

    readonly property string _displayContentSource: {
        if (_displayState === "notification"
                || _displayState === "notificationCritical") {
            return "content/NotificationContent.qml"
        }
        return ""
    }

    mainItem: Item {
        id: expandedRoot
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

            contentSource: dialog._displayContentSource
            contentData: dialog._displayData

            // Spring params live in Theme.qml. Do NOT override per-state — the
            // whole island must feel consistent across all transitions.
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
        // Cache the active state's data so content survives any later
        // transition to idle (collapse path).
        _displayState = IslandController.activeState
        _displayData = IslandController.activeData

        widthBehavior.enabled = false
        heightBehavior.enabled = false
        _phase = "idle"
        capsuleExpanded.contentOpacity = 0
        dialog.show()

        Qt.callLater(function() {
            // Phase γ: hide in-panel shell; Dialog capsule owns the visual.
            if (dialog.shellRef) {
                dialog.shellRef.opacity = 0
            }
            widthBehavior.enabled = true
            heightBehavior.enabled = true
            deltaTimer.restart()
        })
    }

    function _beginCollapse() {
        // Fade content out first, then shrink the capsule. widthSpring's
        // onRunningChanged finalizes (close dialog, clear display state).
        capsuleExpanded.contentOpacity = 0
        contentFadeOutTimer.restart()
    }

    data: [
        Timer {
            id: deltaTimer
            interval: 16
            repeat: false
            onTriggered: {
                dialog._phase = "target"
                contentFadeInTimer.restart()
            }
        },
        Timer {
            id: contentFadeInTimer
            // Spring takes ~1s; start content fade-in after ~60% of the
            // shape morph so the capsule is near final size when text lands.
            interval: 280
            repeat: false
            onTriggered: capsuleExpanded.contentOpacity = 1
        },
        Timer {
            id: contentFadeOutTimer
            // Content fade (180ms) + small buffer, then start shrink spring.
            interval: 200
            repeat: false
            onTriggered: {
                widthBehavior.enabled = true
                heightBehavior.enabled = true
                dialog._phase = "idle"
            }
        },
        // When a higher-priority non-idle state preempts the current one
        // (notification -> notificationCritical), refresh the cached display
        // data so the content item gets new fields. Loader keeps the same
        // source file loaded across these; item.notifData is re-assigned.
        Connections {
            target: IslandController
            function onActiveStateChanged() {
                if (IslandController.activeState !== "idle") {
                    dialog._displayState = IslandController.activeState
                    dialog._displayData = IslandController.activeData
                }
            }
            function onActiveDataChanged() {
                if (IslandController.activeState !== "idle") {
                    dialog._displayData = IslandController.activeData
                }
            }
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
                    // Now it's safe to unload content.
                    dialog._displayState = "idle"
                    dialog._displayData = ({})
                }
            }
        }
    ]

    // PlasmaCore.Dialog overrides visible; binding it doesn't hide the window.
    // Force-close at construction regardless of QQuickWindow default so the
    // island stays invisible until the first expand request.
    Component.onCompleted: dialog.close()
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    switchWidth: 9999
    switchHeight: 9999

    fullRepresentation: Item {}

    compactRepresentation: IslandShell {
        Layout.preferredWidth: IslandController.targetWidth
        Layout.minimumWidth: IslandController.targetWidth
        Layout.maximumWidth: IslandController.targetWidth
        // Floating-panel applets receive a slot ~6px shorter than raw panel
        // thickness (containmentDisplayHints & ContainmentPrefersFloatingApplets).
        // We intentionally fill the slot — matching all other applets — rather
        // than trying to break out to full panel thickness. Phase 2 expanded
        // states will overflow downward via a separate surface.
        Layout.fillHeight: true

        readonly property int panelThickness: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            ? height
            : Theme.fallbackHeight

        onPanelThicknessChanged: IslandController._panelSlotHeight = panelThickness
        Component.onCompleted: IslandController._panelSlotHeight = panelThickness
    }

    IslandExpandedWindow {
        id: expandedWindow
        visualParent: root.compactRepresentationItem
        shellRef: root.compactRepresentationItem
    }

    NotificationSource {
        id: notificationSource
    }

    OsdSource {
        id: osdSource
    }

    MediaSource {
        id: mediaSource
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation

    compactRepresentation: Item {
        id: anchor

        Layout.minimumWidth: Theme.idleWidth
        Layout.preferredWidth: Theme.idleWidth
        Layout.maximumWidth: Theme.idleWidth
        Layout.fillHeight: true

        readonly property int panelThickness: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            ? height
            : Theme.fallbackHeight

        onPanelThicknessChanged: IslandController.targetHeight = panelThickness
        Component.onCompleted: IslandController.targetHeight = panelThickness

        IslandWindow {
            visualParent: anchor
        }
    }
}

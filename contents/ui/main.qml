pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    switchWidth: 9999
    switchHeight: 9999

    fullRepresentation: Item {}

    compactRepresentation: Item {
        id: anchor

        implicitWidth: Theme.idleWidth
        implicitHeight: Theme.fallbackHeight

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

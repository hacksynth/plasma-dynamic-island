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
        Layout.fillHeight: true

        readonly property int panelThickness: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            ? height
            : Theme.fallbackHeight

        onPanelThicknessChanged: IslandController.targetHeight = panelThickness
        Component.onCompleted: IslandController.targetHeight = panelThickness
    }
}

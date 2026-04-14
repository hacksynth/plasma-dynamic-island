import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "."

PlasmaCore.Dialog {
    id: dialog

    type: PlasmaCore.Dialog.Dock
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: Plasmoid.location
    hideOnWindowDeactivate: false
    visible: true

    mainItem: IslandShell { }

    Component.onCompleted: console.log("[dynamic-island] IslandWindow ready, visible=", visible, "visualParent=", visualParent)
    onVisibleChanged: console.log("[dynamic-island] IslandWindow visible=", visible, "x=", x, "y=", y, "w=", width, "h=", height)
}

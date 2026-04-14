import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmaCore.Dialog {
    id: dialog

    type: PlasmaCore.Dialog.Dock
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: Plasmoid.location
    hideOnWindowDeactivate: false
    outputOnly: true
    visible: Plasmoid.status !== PlasmaCore.Types.PassiveStatus

    mainItem: IslandShell { }
}

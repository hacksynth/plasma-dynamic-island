pragma Singleton

import QtQuick

QtObject {
    readonly property string activeState: "idle"

    property int targetWidth: Theme.idleWidth
    property int targetHeight: Theme.fallbackHeight
}

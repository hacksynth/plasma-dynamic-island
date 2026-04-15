pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.dynamicisland.dbussignal as DBusSignal

// Subscribes to org.kde.osdService.osdProgress and osdText signals,
// forwards each event as a controller.request("osd", {...}) call.
// One signal stream covers volume / brightness / mic / kbd / touchpad /
// wifi / virtual-desktop / power-profile etc — Plasma's native OSD
// service broadcasts everything through these two signals.
QtObject {
    id: source

    property int _eventCount: 0
    property bool _ready: false

    // osdProgress observed to fire 2x per actual change in plugin tests.
    // Also: rapid key presses produce many events. Drop any event whose
    // (icon, value) tuple matches the previous event within _dedupWindowMs.
    property var _lastEvent: null
    readonly property int _dedupWindowMs: 50

    property DBusSignal.DBusSignalListener _listener: DBusSignal.DBusSignalListener {
        id: listener
        service: "org.kde.plasmashell"
        path: "/org/kde/osdService"
        iface: "org.kde.osdService"
        signalNames: ["osdProgress", "osdText"]

        onSignalReceived: (signalName, args) => {
            if (!source._ready) return
            if (signalName === "osdProgress") {
                source._handleProgress(args)
            } else if (signalName === "osdText") {
                source._handleText(args)
            }
        }

        onConnectedChanged: {
            console.log("[osd-source] listener.connected =", listener.connected)
            if (!listener.connected && listener.lastError) {
                console.warn("[osd-source] listener error:", listener.lastError)
            }
        }

        onSubscriptionFailed: (reason) => {
            console.warn("[osd-source] subscription failed:", reason)
        }
    }

    // osdProgress(icon: s, value: i, max: i, label: s)
    function _handleProgress(args) {
        const icon = args[0] || ""
        const value = args[1] | 0
        const max = (args[2] | 0) || 100
        const label = args[3] || ""

        const now = Date.now()
        if (_lastEvent
            && _lastEvent.icon === icon
            && _lastEvent.value === value
            && (now - _lastEvent.t) < _dedupWindowMs) {
            return
        }
        _lastEvent = { icon: icon, value: value, t: now }

        _eventCount++
        const pct = Math.round((value / max) * 100)
        console.log("[osd-source] progress #" + _eventCount,
            "icon=" + icon, "value=" + value + "/" + max + "(" + pct + "%)",
            "label=" + (label || "(none)"))

        IslandController.request("osd", {
            kind: "progress",
            icon: icon,
            value: pct,
            rawValue: value,
            rawMax: max,
            label: label
        })
    }

    // osdText(iconName: s, text: s)
    // Live introspection confirms KDE emits (iconName, text), e.g.
    //   osdText("audio-volume-muted", "静音") for mute toggle.
    function _handleText(args) {
        const iconName = args[0] || ""
        const text = args[1] || ""

        const now = Date.now()
        if (_lastEvent
            && _lastEvent.text === text
            && (now - _lastEvent.t) < _dedupWindowMs) {
            return
        }
        _lastEvent = { text: text, t: now }

        _eventCount++
        console.log("[osd-source] text #" + _eventCount,
            "text=" + text, "icon=" + iconName)

        IslandController.request("osd", {
            kind: "text",
            icon: iconName,
            text: text
        })
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            source._ready = true
            console.log("[osd-source] ready, listener.connected =",
                listener.connected)
        })
    }
}

pragma ComponentBehavior: Bound

// Timer source: manages a single active timer's lifecycle.
// Input comes from ~/.local/state/plasma-dynamic-island/timer.json via
// content-hash polling (XHR with file:// read). State is persisted to
// Plasmoid.configuration (wired in main.qml) so timers survive
// plasmashell restarts.
//
// All timestamps are UNIX SECONDS, never milliseconds — Plasmoid
// Int configuration entries are 32-bit and ms (13 digits) overflows.
//
// Expiry notification (freedesktop Notify method call) is deferred
// to 5e-ui polish. Pure QML can't make outbound D-Bus method calls
// without extending DBusSignalListener. On expiry we clear state,
// log a TODO warning, and dismiss the island.

import QtQuick
import QtCore

QtObject {
    id: source

    property bool _ready: false

    // Plasmoid.configuration passed in by main.qml. Single source of
    // truth for persisted state — we never duplicate its fields as
    // local properties (an earlier version did, which produced a
    // binding-loop wipe on restart when local defaults overwrote
    // the persisted value before Plasmoid had loaded it).
    property var configuration: null

    readonly property int timerStartedAt: configuration ? configuration.timerStartedAt : 0
    readonly property int timerDurationSec: configuration ? configuration.timerDurationSec : 0
    readonly property string timerLabel: configuration ? configuration.timerLabel : ""

    // ---- File watch path ----
    // StandardPaths.writableLocation returns a QUrl. Convert to filesystem
    // path before building the control file URL, or the xhr request ends
    // up with "file://file:///..." which silently returns empty.
    readonly property string _stateDirUrl: StandardPaths.writableLocation(StandardPaths.GenericStateLocation)
        + "/plasma-dynamic-island"
    readonly property string _stateDirPath: {
        const s = "" + _stateDirUrl
        return s.indexOf("file://") === 0 ? s.substring(7) : s
    }
    readonly property string _controlFile: _stateDirPath + "/timer.json"
    readonly property string _controlFileUrl: "file://" + _controlFile

    // ---- Internal change detection ----
    // XHR doesn't expose mtime; hash file body instead. 0 = unprimed.
    property int _lastHash: 0

    readonly property bool _timerActive: timerStartedAt > 0 && timerDurationSec > 0

    // ---- File watcher (polling, 500ms) ----
    property Timer _filePoll: Timer {
        id: filePoll
        interval: 500
        repeat: true
        running: false
        onTriggered: source._checkControlFile()
    }

    // ---- Countdown ticker (1 Hz while timer active) ----
    property Timer _ticker: Timer {
        id: ticker
        interval: 1000
        repeat: true
        running: false
        onTriggered: source._tick()
    }

    on_TimerActiveChanged: {
        if (_timerActive) ticker.start()
        else ticker.stop()
    }

    function _readControlFile() {
        const xhr = new XMLHttpRequest()
        try {
            xhr.open("GET", _controlFileUrl, false)
            xhr.send()
            if (xhr.status !== 200 && xhr.status !== 0) return ""
            return xhr.responseText || ""
        } catch (e) {
            console.warn("[timer] xhr exception:", e.message)
            return ""
        }
    }

    function _primeControlFile() {
        // On startup, populate _lastHash from whatever is in the file
        // so we don't re-dispatch the last persisted command.
        const txt = _readControlFile()
        if (txt) _lastHash = _djb2(txt)
    }

    function _checkControlFile() {
        const txt = _readControlFile()
        if (!txt || txt.trim() === "") return

        const h = _djb2(txt)
        if (h === _lastHash) return
        _lastHash = h

        let cmd
        try { cmd = JSON.parse(txt) }
        catch (e) {
            console.warn("[timer] malformed control file:", e.message)
            return
        }

        _dispatch(cmd)
    }

    function _djb2(s) {
        let h = 5381
        for (let i = 0; i < s.length; i++) {
            h = ((h << 5) + h + s.charCodeAt(i)) | 0
        }
        return h
    }

    function _dispatch(cmd) {
        if (!cmd || typeof cmd.op !== "string") {
            console.warn("[timer] missing op in control:", JSON.stringify(cmd))
            return
        }
        console.log("[timer] dispatch op=" + cmd.op,
            "duration=" + (cmd.duration | 0),
            "label=" + (cmd.label || ""))

        if (cmd.op === "start") {
            const dur = cmd.duration | 0
            if (dur <= 0) {
                console.warn("[timer] start with invalid duration")
                return
            }
            _startTimer(dur, cmd.label || "")
        } else if (cmd.op === "cancel") {
            _cancelTimer()
        } else if (cmd.op === "extend") {
            const extra = cmd.seconds | 0
            if (_timerActive && extra > 0 && configuration) {
                configuration.timerDurationSec = timerDurationSec + extra
                console.log("[timer] extended by " + extra + "s,"
                    + " new duration=" + (timerDurationSec + extra) + "s")
                _publish()
            }
        } else {
            console.warn("[timer] unknown op:", cmd.op)
        }
    }

    function _nowSec() {
        return Math.floor(Date.now() / 1000)
    }

    function _startTimer(durationSec, label) {
        if (!configuration) return
        configuration.timerStartedAt = _nowSec()
        configuration.timerDurationSec = durationSec
        configuration.timerLabel = label
        console.log("[timer] started duration=" + durationSec
            + "s label='" + label + "'")
        _publish()
    }

    function _cancelTimer() {
        if (!_timerActive) return
        console.log("[timer] cancelled")
        _clearState()
        IslandController.dismiss("timer")
    }

    function _tick() {
        if (!_timerActive) return
        const remaining = Math.max(0, timerDurationSec - (_nowSec() - timerStartedAt))
        if (remaining <= 0) {
            _expireTimer()
            return
        }
        _publish(remaining)
    }

    function _publish(remainingOverride) {
        const remaining = (remainingOverride !== undefined)
            ? remainingOverride
            : Math.max(0, timerDurationSec - (_nowSec() - timerStartedAt))

        IslandController.request("timer", {
            label: timerLabel,
            totalSeconds: timerDurationSec,
            remainingSeconds: remaining,
            startedAt: timerStartedAt
        })
    }

    function _expireTimer() {
        const label = timerLabel || "Timer"
        console.log("[timer] expired, firing notification for:", label)
        _fireExpiryNotification(label)
        _clearState()
        IslandController.dismiss("timer")
    }

    function _clearState() {
        if (!configuration) return
        configuration.timerStartedAt = 0
        configuration.timerDurationSec = 0
        configuration.timerLabel = ""
    }

    function _fireExpiryNotification(label) {
        // Pure QML can't make outbound D-Bus method calls to invoke
        // org.freedesktop.Notifications.Notify. DBusSignalListener is
        // currently subscribe-only. Revisit in 5e-ui polish — likely by
        // adding a minimal callMethod Q_INVOKABLE to the plugin.
        console.warn("[timer] EXPIRY NOTIFICATION TODO: timer '"
            + label + "' expired, but outbound D-Bus Notify is not yet "
            + "wired from QML. Deferred to Phase 2 step 5e-ui polish.")
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            source._primeControlFile()
            source._ready = true
            filePoll.start()

            // Restore persisted timer if one is active.
            if (source._timerActive) {
                const remaining = Math.max(0,
                    source.timerDurationSec - (source._nowSec() - source.timerStartedAt))
                console.log("[timer] restoring persisted timer, remaining="
                    + remaining + "s")
                if (remaining <= 0) {
                    source._expireTimer()
                } else {
                    source._publish(remaining)
                    ticker.start()
                }
            }

            console.log("[timer] source ready, active=" + source._timerActive
                + " controlFile=" + source._controlFile)
        })
    }
}

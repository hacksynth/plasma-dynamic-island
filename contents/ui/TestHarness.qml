import QtQuick

Item {
    id: harness

    readonly property var script: [
        { at:     0, fn: function() { console.log("[harness] start; idle 140") } },
        { at:  2000, fn: function() { IslandController.request("media", { title: "Track" }) } },
        { at:  5000, fn: function() { IslandController.request("notification", { title: "Msg" }) } },
        { at: 12000, fn: function() { IslandController.request("osd", { kind: "vol", val: 40 }) } },
        { at: 16000, fn: function() { IslandController.request("progress", { name: "DL", pct: 0.3 }) } },
        { at: 19000, fn: function() { IslandController.dismiss("progress") } },
        { at: 22000, fn: function() { IslandController.dismiss("media") } },
        { at: 25000, fn: function() { console.log("[harness] done; back to idle") } }
    ]

    property int _idx: 0
    // NOTE: real, not int — Date.now() overflows 32-bit int.
    property real _startedAt: 0

    Timer {
        id: tick
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (harness._startedAt === 0) harness._startedAt = Date.now()
            const elapsed = Date.now() - harness._startedAt
            while (harness._idx < harness.script.length
                   && harness.script[harness._idx].at <= elapsed) {
                const step = harness.script[harness._idx]
                console.log("[harness] t=" + elapsed + " step " + harness._idx)
                step.fn()
                harness._idx++
            }
            if (harness._idx >= harness.script.length) {
                tick.stop()
            }
        }
    }
}

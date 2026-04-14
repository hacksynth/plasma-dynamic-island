import QtQuick

QtObject {
    id: harness

    readonly property var script: [
        { at:     0, fn: function() { IslandController.request("media", { title: "Song A" }) } },
        { at:  2000, fn: function() { IslandController.request("notification", { title: "Msg 1" }) } },
        { at:  4000, fn: function() { IslandController.request("osd", { kind: "volume", value: 40 }) } },
        { at:  7000, fn: function() { IslandController.request("progress", { name: "Download", pct: 0.3 }) } },
        { at: 13000, fn: function() { IslandController.dismiss("progress") } },
        { at: 15000, fn: function() { IslandController.dismiss("media") } }
    ]

    property int _idx: 0
    property int _startMs: 0

    property QtObject _tick: Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (harness._startMs === 0) harness._startMs = Date.now()
            const elapsed = Date.now() - harness._startMs
            while (harness._idx < harness.script.length
                   && harness.script[harness._idx].at <= elapsed) {
                const step = harness.script[harness._idx]
                console.log("[harness] t=" + elapsed + "ms step", harness._idx)
                step.fn()
                harness._idx++
            }
            if (harness._idx >= harness.script.length && elapsed > 17000) {
                console.log("[harness] done")
                stop()
            }
        }
    }
}

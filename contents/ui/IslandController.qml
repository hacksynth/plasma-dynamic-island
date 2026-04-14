pragma Singleton

import QtQuick

QtObject {
    id: ctrl

    readonly property var stateDefs: ({
        idle:         { priority: 0, persistent: true  },
        timer:        { priority: 1, persistent: true  },
        media:        { priority: 2, persistent: true  },
        progress:     { priority: 3, persistent: true  },
        notification: { priority: 4, persistent: false, defaultTimeout: 5000 },
        osd:          { priority: 5, persistent: false, defaultTimeout: 2000 }
    })

    property string activeState: "idle"
    property var    activeData: ({})

    property var persistentSlots: ({ timer: null, media: null, progress: null })

    property var temporaryQueue: []

    property QtObject _expiryTimer: Timer {
        interval: 0
        repeat: false
        onTriggered: ctrl._onTemporaryExpired()
    }

    property int targetWidth: Theme.idleWidth
    property int targetHeight: Theme.fallbackHeight

    function request(stateName, data, timeoutOverride) {
        const def = stateDefs[stateName]
        if (!def) {
            console.warn("[ctrl] unknown state:", stateName)
            return
        }
        data = data || {}
        console.log("[ctrl] request", stateName,
            "prio=", def.priority,
            "persistent=", def.persistent,
            "data=", JSON.stringify(data))

        if (def.persistent) {
            const next = Object.assign({}, persistentSlots)
            next[stateName] = data
            persistentSlots = next
        } else {
            const entry = {
                state: stateName,
                data: data,
                timeout: timeoutOverride !== undefined
                    ? timeoutOverride
                    : def.defaultTimeout,
                enqueuedAt: Date.now()
            }
            const q = temporaryQueue.slice()
            q.push(entry)
            q.sort(function(a, b) {
                const pa = stateDefs[a.state].priority
                const pb = stateDefs[b.state].priority
                if (pa !== pb) return pb - pa
                return a.enqueuedAt - b.enqueuedAt
            })
            temporaryQueue = q
        }
        _resolve()
    }

    function dismiss(stateName) {
        console.log("[ctrl] dismiss", stateName)
        const def = stateDefs[stateName]
        if (!def || !def.persistent) return
        if (persistentSlots[stateName] !== null) {
            const next = Object.assign({}, persistentSlots)
            next[stateName] = null
            persistentSlots = next
            _resolve()
        }
    }

    function _onTemporaryExpired() {
        if (temporaryQueue.length === 0) return
        const expired = temporaryQueue[0]
        console.log("[ctrl] temporary expired:", expired.state)
        const q = temporaryQueue.slice(1)
        temporaryQueue = q
        _resolve()
    }

    function _resolve() {
        let nextState = "idle"
        let nextData = {}
        let nextTimeout = 0

        if (temporaryQueue.length > 0) {
            const head = temporaryQueue[0]
            nextState = head.state
            nextData = head.data
            nextTimeout = head.timeout
        } else {
            let bestName = null
            let bestPrio = -1
            for (const name in persistentSlots) {
                if (persistentSlots[name] !== null) {
                    const p = stateDefs[name].priority
                    if (p > bestPrio) {
                        bestPrio = p
                        bestName = name
                    }
                }
            }
            if (bestName !== null) {
                nextState = bestName
                nextData = persistentSlots[bestName]
            }
        }

        const changed = (nextState !== activeState)
        if (changed) {
            console.log("[ctrl] transition:",
                activeState, "->", nextState,
                "prio=", stateDefs[nextState].priority)
        }
        activeState = nextState
        activeData = nextData

        _expiryTimer.stop()
        if (nextTimeout > 0) {
            _expiryTimer.interval = nextTimeout
            _expiryTimer.start()
            console.log("[ctrl] expiry armed:", nextTimeout, "ms")
        }
    }
}

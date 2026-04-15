pragma ComponentBehavior: Bound

import QtQuick
import org.kde.notificationmanager as NM

// Subscribes to KDE NotificationManager filtered to JobType rows.
// Independent Notifications model instance from NotificationSource —
// they don't share state.
QtObject {
    id: source

    property int _eventCount: 0
    property bool _ready: false
    property int _currentJobRow: -1
    property bool _enumsPrinted: false

    property NM.Notifications _model: NM.Notifications {
        id: model
        limit: 50
        showJobs: true
        showNotifications: false
        showExpired: false
        showDismissed: false
        groupMode: NM.Notifications.GroupDisabled
        sortMode: NM.Notifications.SortByDate

        onRowsInserted: (parent, first, last) => {
            if (!source._ready) return
            console.log("[progress] rowsInserted", first, "..", last,
                "count=" + count)
            source._scheduleRescan()
        }

        onRowsAboutToBeRemoved: (parent, first, last) => {
            if (!source._ready) return
            console.log("[progress] rowsAboutToBeRemoved", first, "..", last,
                "count=" + count)
            source._scheduleRescan()
        }

        onDataChanged: (topLeft, bottomRight) => {
            if (!source._ready) return
            if (source._currentJobRow < 0) return
            if (topLeft.row <= source._currentJobRow
                    && bottomRight.row >= source._currentJobRow) {
                source._refresh()
            }
        }
    }

    // Throttle rescan calls (rapid insert/remove cycles) and defer past
    // the synchronous row-removal phase so deleted rows don't get read.
    property Timer _rescanTimer: Timer {
        id: rescanTimer
        interval: 30
        repeat: false
        onTriggered: source._rescan()
    }

    function _scheduleRescan() {
        rescanTimer.restart()
    }

    function _rescan() {
        if (!_enumsPrinted) {
            console.log("[progress] enum constants:",
                "JobType=" + NM.Notifications.JobType,
                "NotificationType=" + NM.Notifications.NotificationType,
                "JobStateRunning=" + NM.Notifications.JobStateRunning,
                "JobStateSuspended=" + NM.Notifications.JobStateSuspended,
                "JobStateStopped=" + NM.Notifications.JobStateStopped)
            _enumsPrinted = true
        }

        const count = model.count
        for (let r = 0; r < count; r++) {
            const idx = model.index(r, 0)
            if (!idx.valid) continue
            const type = model.data(idx, NM.Notifications.TypeRole)
            if (type !== NM.Notifications.JobType) continue
            const state = model.data(idx, NM.Notifications.JobStateRole)
            if (state !== NM.Notifications.JobStateRunning) continue
            if (_currentJobRow !== r) {
                console.log("[progress] _currentJobRow",
                    _currentJobRow, "->", r)
                _currentJobRow = r
            }
            _refresh()
            return
        }

        if (_currentJobRow >= 0) {
            console.log("[progress] no active job, dismissing")
            _currentJobRow = -1
            IslandController.dismiss("progress")
        }
    }

    function _refresh() {
        if (_currentJobRow < 0) return
        const idx = model.index(_currentJobRow, 0)
        if (!idx.valid) {
            _currentJobRow = -1
            return
        }

        const summary = model.data(idx, NM.Notifications.SummaryRole) || ""
        const appName = model.data(idx, NM.Notifications.ApplicationNameRole) || ""
        const iconName = model.data(idx, NM.Notifications.ApplicationIconNameRole) || ""
        const pct = model.data(idx, NM.Notifications.PercentageRole)
        const state = model.data(idx, NM.Notifications.JobStateRole)

        _eventCount++
        console.log("[progress] refresh #" + _eventCount,
            "app=" + appName, "pct=" + pct, "state=" + state,
            "summary=" + summary.substring(0, 40))

        IslandController.request("progress", {
            summary: summary,
            appName: appName,
            iconName: iconName,
            percentage: (pct | 0),
            running: state === NM.Notifications.JobStateRunning
        })
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            source._ready = true
            console.log("[progress] source ready, model count=" + model.count)
            source._scheduleRescan()
        })
    }
}

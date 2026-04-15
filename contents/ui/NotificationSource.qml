pragma ComponentBehavior: Bound

import QtQuick
import org.kde.notificationmanager as NM

// Subscribes to KDE NotificationManager and forwards new notifications
// to IslandController. Stays passive — does not claim the
// org.freedesktop.Notifications service (Plasma keeps that), does not
// dismiss or modify notifications. Native notification popups, history,
// and Do Not Disturb continue to work exactly as before.
QtObject {
    id: source

    readonly property alias modelCount: notifModel.count
    property int _consumedCount: 0
    property bool _ready: false

    property NM.Notifications notifModel: NM.Notifications {
        id: notifModel

        // Don't use limit:1. With limit:1, bursts of notifications get
        // truncated before we can consume them. Use a generous limit
        // (model is cheap; we only react to onRowsInserted, never iterate).
        limit: 50

        showExpired: false
        showDismissed: false
        groupMode: NM.Notifications.GroupDisabled
        sortMode: NM.Notifications.SortByDate
        // SortByDate gives us [newest, ..., oldest]. New rows insert
        // at index 0, so onRowsInserted with first=0 is the new arrival.

        onRowsInserted: (parent, first, last) => {
            if (!source._ready) {
                // Initial population from the existing notification history
                // when the model is first created. Skip these — they are not
                // "new" events.
                return
            }
            for (let r = first; r <= last; r++) {
                source._consumeRow(r)
            }
        }
    }

    function _consumeRow(row) {
        const idx = notifModel.index(row, 0)
        if (!idx.valid) return

        const summary = notifModel.data(idx, NM.Notifications.SummaryRole) || ""
        const body    = notifModel.data(idx, NM.Notifications.BodyRole) || ""
        const appName = notifModel.data(idx, NM.Notifications.ApplicationNameRole) || ""
        const urgency = notifModel.data(idx, NM.Notifications.UrgencyRole)
        // NM.Notifications.Urgency is a flag enum: LowUrgency=1, NormalUrgency=2,
        // CriticalUrgency=4 — NOT the freedesktop urgency byte (0/1/2).

        source._consumedCount++
        console.log("[notif] received #" + source._consumedCount,
            "app=" + appName,
            "urgency=" + urgency,
            "summary=" + summary.substring(0, 40))

        const isCritical = (urgency === NM.Notifications.CriticalUrgency)
        const stateName = isCritical ? "notificationCritical" : "notification"

        IslandController.request(stateName, {
            appName: appName,
            summary: summary,
            body: body,
            urgency: urgency
        })
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            source._ready = true
            console.log("[notif] source ready, initial model count=" +
                notifModel.count)
        })
    }
}

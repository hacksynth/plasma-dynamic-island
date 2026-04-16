import QtQuick
import QtQuick.Window
import org.kde.plasma.dynamicisland.dbussignal as DBusSignal

Window {
    width: 480
    height: 220
    visible: true
    title: "DBusSignalListener test"
    color: "#1a1a1a"

    DBusSignal.DBusSignalListener {
        id: listener
        service: "org.kde.plasmashell"
        path: "/org/kde/osdService"
        iface: "org.kde.osdService"
        signalNames: ["osdProgress", "osdText"]

        onSignalReceived: (signalName, args) => {
            console.log("[test] got", signalName, "args=", JSON.stringify(args))
        }
        onConnectedChanged: console.log("[test] connected =", connected)
        onSubscriptionFailed: (reason) => console.log("[test] FAIL:", reason)
    }

    property string callResult: "(pending)"

    Text {
        anchors.centerIn: parent
        color: listener.connected ? "#7ee787" : "#ff7b72"
        font.pixelSize: 18
        font.family: "monospace"
        horizontalAlignment: Text.AlignHCenter
        text: (listener.connected
            ? "✓ subscribed\n" + listener.signalNames.join(", ")
            : "✗ " + (listener.lastError || "(idle)"))
            + "\n\ncall() → " + callResult
    }

    Timer {
        interval: 3000
        running: true
        repeat: false
        onTriggered: {
            console.log("[test] firing test notification via call()")
            const args = [
                "plugin-test",              // app_name
                0,                          // replaces_id
                "dialog-information",       // app_icon
                "Plugin call() works",      // summary
                "If you see this, callMethod is working",  // body
                [],                         // actions
                { "urgency": 1 },           // hints
                3000                        // expire_timeout
            ]
            const reply = listener.call(
                "org.freedesktop.Notifications",
                "/org/freedesktop/Notifications",
                "org.freedesktop.Notifications",
                "Notify",
                args,
                "susssasa{sv}i"
            )
            reply.finished.connect(function(ok, result, err) {
                if (ok) {
                    console.log("[test] notify OK, id=" + result)
                    callResult = "OK id=" + result
                } else {
                    console.log("[test] notify FAIL: " + err)
                    callResult = "FAIL " + err
                }
            })
        }
    }
}

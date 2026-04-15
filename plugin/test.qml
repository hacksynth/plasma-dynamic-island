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

    Text {
        anchors.centerIn: parent
        color: listener.connected ? "#7ee787" : "#ff7b72"
        font.pixelSize: 18
        font.family: "monospace"
        horizontalAlignment: Text.AlignHCenter
        text: listener.connected
            ? "✓ subscribed\n" + listener.signalNames.join(", ")
            : "✗ " + (listener.lastError || "(idle)")
    }
}

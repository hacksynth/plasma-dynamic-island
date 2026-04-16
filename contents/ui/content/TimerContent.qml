pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var notifData: ({})

    readonly property int _remaining: {
        const r = notifData.remainingSeconds
        return (r === undefined || r === null) ? 0 : Math.max(0, r | 0)
    }
    readonly property int _total: {
        const t = notifData.totalSeconds
        return (t === undefined || t === null) ? 0 : Math.max(1, t | 0)
    }
    readonly property string _label: notifData.label || ""

    function _fmt(sec) {
        if (sec < 0) sec = 0
        const h = Math.floor(sec / 3600)
        const m = Math.floor((sec % 3600) / 60)
        const s = sec % 60
        const pad = (n) => (n < 10 ? "0" + n : "" + n)
        if (h > 0) return h + ":" + pad(m) + ":" + pad(s)
        return pad(m) + ":" + pad(s)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Text {
                id: countdownText
                text: root._fmt(root._remaining)
                color: "#f5f5f5"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: Kirigami.Theme.defaultFont.family
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                id: labelText
                text: root._label
                color: "#a0a0a0"
                font.pixelSize: 11
                font.weight: Font.Normal
                font.family: Kirigami.Theme.defaultFont.family
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignRight
                visible: text !== ""
            }
        }

        // Progress bar: shrinks from full to empty (remaining / total).
        // Shorter = less time left. 400ms ease-out smooths the 1Hz ticks.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            Layout.alignment: Qt.AlignBottom

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: "#30ffffff"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * root._remaining / root._total
                    radius: 2
                    color: "#f5f5f5"
                    visible: width > 0

                    Behavior on width {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var notifData: ({})

    readonly property string _kind: notifData.kind || "progress"
    readonly property string _icon: notifData.icon || ""
    readonly property int _value: notifData.value !== undefined ? notifData.value : 0
    readonly property string _text: notifData.text || ""

    // muted: icon contains "muted", or progress with value === 0
    readonly property bool _isMuted: _kind === "progress"
        && (_icon.indexOf("muted") !== -1 || _value === 0)

    // 0 = progress, 1 = muted (icon-only), 2 = text
    readonly property int _mode: {
        if (_kind === "text") return 2
        if (_isMuted) return 1
        return 0
    }

    // ---- Mode 0: progress (icon + bar) ----
    RowLayout {
        anchors.fill: parent
        spacing: 8
        visible: root._mode === 0

        Kirigami.Icon {
            source: root._icon
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter
            fallback: "dialog-information"
        }

        Item {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 4

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
                    width: parent.width * Math.max(0, Math.min(100, root._value)) / 100
                    radius: 2
                    color: "#f5f5f5"
                    visible: width > 0

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    // ---- Mode 1: muted (icon centered, no bar) ----
    Item {
        anchors.fill: parent
        visible: root._mode === 1

        // Icon color is determined by the active KDE icon theme
        // (Breeze tints audio-volume-muted red as an alert hint).
        // Do NOT force single-color tinting — respect the user's theme
        // and the inherent semantic of the icon.
        Kirigami.Icon {
            anchors.centerIn: parent
            source: root._icon
            width: 22
            height: 22
            fallback: "audio-volume-muted"
        }
    }

    // ---- Mode 2: text (icon + single-line text) ----
    // Use Row + anchors.centerIn (not RowLayout) so the icon+text pair
    // visually centers in the capsule rather than stretching to fill.
    // osdText payloads are typically very short (Mute / desktop name);
    // forcing fillWidth would left-align them awkwardly.
    Row {
        anchors.centerIn: parent
        spacing: 8
        visible: root._mode === 2

        Kirigami.Icon {
            source: root._icon
            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            fallback: "dialog-information"
            visible: root._icon !== ""
        }

        Text {
            text: root._text
            color: "#f5f5f5"
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.family: Kirigami.Theme.defaultFont.family
            anchors.verticalCenter: parent.verticalCenter
            // Not fillWidth, not elide: short labels look best when allowed
            // to size naturally. Re-add elide if a long-text osdText case
            // surfaces in the wild.
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".." as UI
import "../components" as Components

Item {
    id: root

    property var notifData: ({})

    readonly property string _summary: notifData.summary || ""
    readonly property string _appName: notifData.appName || ""
    readonly property string _iconName: notifData.iconName || ""
    readonly property int _percentage: {
        const p = notifData.percentage
        return (p === undefined || p === null) ? 0 : Math.max(0, Math.min(100, p | 0))
    }
    readonly property bool _running: notifData.running === true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Kirigami.Icon {
            source: root._iconName !== "" ? root._iconName : root._appName
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter
            fallback: "system-run"
            // Subtle communication that the job isn't actively progressing.
            opacity: root._running ? 1.0 : 0.55
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Components.Marquee {
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                text: root._summary
                color: UI.Theme.textPrimary
                pixelSize: UI.Theme.progressSummaryPixelSize
                weight: Font.DemiBold
                edgeColor: UI.Theme.islandBg
            }

            // Progress bar track
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: UI.Theme.progressBarHeight

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: UI.Theme.progressBarHeight
                    radius: 2
                    color: UI.Theme.trackWhite

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * root._percentage / 100
                        radius: 2
                        color: UI.Theme.fillWhite
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

        // Fixed-width % label so layout doesn't shift as 5% -> 100%.
        Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 28
            text: root._percentage + "%"
            color: UI.Theme.textSecondary
            font.pixelSize: UI.Theme.pctLabelPixelSize
            font.weight: Font.Normal
            font.family: Kirigami.Theme.defaultFont.family
            horizontalAlignment: Text.AlignRight
        }
    }
}

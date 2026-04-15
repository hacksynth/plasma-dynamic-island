pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import "../components" as Components

Item {
    id: root

    property var notifData: ({})

    readonly property string _track: notifData.track || ""
    readonly property string _artist: notifData.artist || ""
    readonly property string _artUrl: notifData.artUrl || ""
    readonly property string _iconName: notifData.iconName || ""
    readonly property bool _playing: notifData.playing === true

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // ---- Album art / app icon ----
        Item {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter

            Image {
                id: artImage
                anchors.fill: parent
                source: root._artUrl
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready

                layer.enabled: status === Image.Ready
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: ShaderEffectSource {
                        sourceItem: artMask
                        hideSource: true
                    }
                }
            }

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: 8
                visible: false
                color: "white"
            }

            Kirigami.Icon {
                anchors.fill: parent
                source: root._iconName
                visible: artImage.status !== Image.Ready
                fallback: "audio-x-generic"
            }
        }

        // ---- Track + Artist ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Components.Marquee {
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                text: root._track
                color: "#f5f5f5"
                pixelSize: 13
                weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root._artist
                color: "#a0a0a0"
                font.pixelSize: 10
                font.weight: Font.Normal
                font.family: Kirigami.Theme.defaultFont.family
                elide: Text.ElideRight
                maximumLineCount: 1
                lineHeight: 1.0
                visible: text !== ""
                verticalAlignment: Text.AlignVCenter
            }
        }

        // ---- Playback state indicator ----
        Item {
            Layout.preferredWidth: 10
            Layout.preferredHeight: 10
            Layout.alignment: Qt.AlignVCenter

            // Playing: pulsing triangle
            Item {
                anchors.fill: parent
                visible: root._playing

                Canvas {
                    anchors.fill: parent
                    opacity: 0.85
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = "#f5f5f5"
                        ctx.beginPath()
                        ctx.moveTo(2, 1)
                        ctx.lineTo(2, 9)
                        ctx.lineTo(9, 5)
                        ctx.closePath()
                        ctx.fill()
                    }

                    SequentialAnimation on opacity {
                        running: root._playing
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.45; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.85; duration: 700; easing.type: Easing.InOutSine }
                    }
                }
            }

            // Paused: two vertical bars
            Item {
                anchors.fill: parent
                visible: !root._playing

                Rectangle {
                    x: 1; y: 1
                    width: 3; height: 8
                    radius: 1
                    color: "#a0a0a0"
                }
                Rectangle {
                    x: 6; y: 1
                    width: 3; height: 8
                    radius: 1
                    color: "#a0a0a0"
                }
            }
        }
    }
}

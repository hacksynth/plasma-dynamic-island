pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    // Data dict is injected by the Loader (capsule.contentData → loader.item.notifData).
    property var notifData: ({})

    readonly property string _appIcon: notifData.appIcon || ""
    readonly property string _summary: notifData.summary || ""
    readonly property string _body: _stripBodyWrapper(notifData.body || "")

    // KDE wraps body in <?xml ?><html>...</html>. Strip wrapper, drop tags
    // that don't render meaningfully in a single-line capsule. Keep the
    // plain text only for now — step 5 polish may re-enable basic inline
    // formatting via Text.RichText.
    function _stripBodyWrapper(raw) {
        if (!raw) return ""
        let s = raw.replace(/<\?xml[^>]*\?>/g, "")
        s = s.replace(/<\/?html[^>]*>/g, "")
        s = s.replace(/<\/?body[^>]*>/g, "")
        s = s.replace(/<[^>]+>/g, "")
        s = s.replace(/&amp;/g, "&")
             .replace(/&lt;/g, "<")
             .replace(/&gt;/g, ">")
             .replace(/&quot;/g, "\"")
             .replace(/&#39;/g, "'")
             .replace(/&nbsp;/g, " ")
        return s.trim()
    }

    readonly property string _iconName: _appIcon !== ""
        ? _appIcon
        : "preferences-desktop-notification"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Kirigami.Icon {
            source: root._iconName
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            fallback: "preferences-desktop-notification"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root._summary
                color: "#f5f5f5"
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
                verticalAlignment: Text.AlignVCenter
                font.family: Kirigami.Theme.defaultFont.family
                renderType: Text.NativeRendering
            }

            Text {
                Layout.fillWidth: true
                text: root._body
                color: "#a0a0a0"
                font.pixelSize: 11
                font.weight: Font.Normal
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text !== ""
                verticalAlignment: Text.AlignVCenter
                font.family: Kirigami.Theme.defaultFont.family
                renderType: Text.NativeRendering
            }
        }
    }
}

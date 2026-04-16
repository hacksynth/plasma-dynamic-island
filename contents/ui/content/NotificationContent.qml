pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import ".." as UI

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
        : "dialog-information"

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        spacing: 10

        Kirigami.Icon {
            source: root._iconName
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            fallback: "dialog-information"
        }

        ColumnLayout {
            id: textColumn
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                id: summaryText
                Layout.fillWidth: true
                text: root._summary
                color: UI.Theme.textPrimary
                font.pixelSize: UI.Theme.summaryPixelSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
                lineHeight: 1.0
                verticalAlignment: Text.AlignVCenter
                font.family: Kirigami.Theme.defaultFont.family
            }

            Text {
                id: bodyText
                Layout.fillWidth: true
                text: root._body
                color: UI.Theme.textSecondary
                font.pixelSize: UI.Theme.bodyPixelSize
                font.weight: Font.Normal
                elide: Text.ElideRight
                maximumLineCount: 1
                lineHeight: 1.0
                visible: text !== ""
                verticalAlignment: Text.AlignVCenter
                font.family: Kirigami.Theme.defaultFont.family
            }
        }
    }
}

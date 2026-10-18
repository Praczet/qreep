import QtQuick

// /browse preview (Alt+P): the selected entry's first bytes as text, an
// image, or a plain note about what it is. Read-only, never the whole file.
Rectangle {
    id: rootKipBrowsePreview

    required property QtObject kipTheme
    required property QtObject browser

    readonly property string kind: browser.previewKind

    radius: kipTheme.rowRadius
    color: kipTheme.inputColor
    border.width: 1
    border.color: kipTheme.borderColor
    clip: true

    Image {
        anchors.fill: parent
        anchors.margins: 8
        visible: rootKipBrowsePreview.kind === "image"
        source: visible ? "file://" + rootKipBrowsePreview.browser.previewPath.split("/").map(encodeURIComponent).join("/") : ""
        sourceSize.width: Math.round(width * 1.5)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 8
        visible: rootKipBrowsePreview.kind === "text"
        contentHeight: previewText.implicitHeight
        contentWidth: width
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Text {
            id: previewText

            width: parent.width
            text: rootKipBrowsePreview.browser.previewText
            textFormat: Text.PlainText
            color: rootKipBrowsePreview.kipTheme.primaryTextColor
            font.family: rootKipBrowsePreview.kipTheme.monoFontFamily
            font.pixelSize: rootKipBrowsePreview.kipTheme.metaPixelSize + 1
            wrapMode: Text.WrapAnywhere
        }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 24
        visible: rootKipBrowsePreview.kind !== "image" && rootKipBrowsePreview.kind !== "text"
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: ({
                none: "nothing selected",
                loading: "reading…",
                dir: "a folder · Enter goes in",
                binary: "binary · not printing that",
                error: rootKipBrowsePreview.browser.previewText
            })[rootKipBrowsePreview.kind] || ""
        color: rootKipBrowsePreview.kipTheme.secondaryTextColor
        font.pixelSize: rootKipBrowsePreview.kipTheme.metaPixelSize + 1
    }
}

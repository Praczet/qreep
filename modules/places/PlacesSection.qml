import QtQuick

// A titled card in the detail pane. Children go into a Column.
Rectangle {
    id: rootPlacesSection

    required property QtObject pt
    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    implicitHeight: body.y + body.implicitHeight + pt.cardPadding
    radius: pt.cardRadius
    color: pt.cardColor
    border.width: 1
    border.color: Qt.rgba(pt.borderColor.r, pt.borderColor.g, pt.borderColor.b, 0.6)

    Text {
        id: titleText

        x: rootPlacesSection.pt.cardPadding
        y: rootPlacesSection.pt.cardPadding - 2
        text: rootPlacesSection.title
        color: rootPlacesSection.pt.sectionColor
        font.pixelSize: rootPlacesSection.pt.sectionPixelSize
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    Text {
        anchors {
            left: titleText.right
            leftMargin: 10
            right: parent.right
            rightMargin: rootPlacesSection.pt.cardPadding
            baseline: titleText.baseline
        }
        text: rootPlacesSection.subtitle
        color: rootPlacesSection.pt.secondaryTextColor
        font.pixelSize: rootPlacesSection.pt.metaPixelSize
        elide: Text.ElideRight
    }

    Column {
        id: body

        x: rootPlacesSection.pt.cardPadding
        y: titleText.y + titleText.height + 10
        width: parent.width - 2 * rootPlacesSection.pt.cardPadding
        spacing: 6
    }
}

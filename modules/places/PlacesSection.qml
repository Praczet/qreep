import QtQuick

// A titled card in the detail pane. Children go into a Column.
Rectangle {
    id: rootPlacesSection

    required property QtObject pt
    property string title: ""
    property string subtitle: ""
    // Keyboard: the Alt+number that jumps here, and whether it has focus.
    property string shortcut: ""
    property bool focused: false
    default property alias content: body.data

    implicitHeight: body.y + body.implicitHeight + pt.cardPadding
    radius: pt.cardRadius
    color: pt.cardColor
    border.width: 1
    border.color: focused ? pt.selectedBorderColor : Qt.rgba(pt.borderColor.r, pt.borderColor.g, pt.borderColor.b, 0.6)

    // Key cap in the top-right corner, dimmed like the action button hints.
    Rectangle {
        visible: rootPlacesSection.shortcut.length > 0
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: rootPlacesSection.pt.cardPadding - 2
            topMargin: rootPlacesSection.pt.cardPadding - 4
        }
        width: shortcutText.implicitWidth + 12
        height: shortcutText.implicitHeight + 4
        radius: 5
        color: rootPlacesSection.focused ? rootPlacesSection.pt.selectedRowColor : rootPlacesSection.pt.withAlpha(rootPlacesSection.pt.primaryTextColor, 0.06)
        border.width: 1
        border.color: rootPlacesSection.focused ? rootPlacesSection.pt.selectedBorderColor : rootPlacesSection.pt.withAlpha(rootPlacesSection.pt.primaryTextColor, 0.22)

        Text {
            id: shortcutText

            anchors.centerIn: parent
            text: rootPlacesSection.shortcut
            color: rootPlacesSection.focused ? rootPlacesSection.pt.accentColor : rootPlacesSection.pt.primaryTextColor
            opacity: rootPlacesSection.focused ? 1 : 0.68
            font.family: rootPlacesSection.pt.monoFontFamily
            font.pixelSize: rootPlacesSection.pt.metaPixelSize
        }
    }

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
            // Leave room for the key cap.
            rightMargin: rootPlacesSection.pt.cardPadding + (rootPlacesSection.shortcut.length > 0 ? 64 : 0)
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

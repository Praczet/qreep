import QtQuick

// Action chooser: "Open with" for notes, actions for screenshots and files.
// Rows are numbered; the first option is the default.
Rectangle {
    id: rootKipChooser

    required property QtObject kipTheme
    required property string iconFontFamily
    required property string title
    required property var options
    property int selectedIndex: 0
    // Optional image left of the options (screenshots). Empty hides it.
    property string previewSource: ""
    readonly property bool previewShown: previewSource.length > 0

    signal picked(int index)

    // Label column fits the longest label in bold, so hints never overlap.
    // FontMetrics.advanceWidth(text) measures without setting a property;
    // writing TextMetrics.text inside this binding was a binding loop.
    readonly property real labelWidth: {
        let widest = 0;

        for (let index = 0; index < options.length; index++)
            widest = Math.max(widest, labelMetrics.advanceWidth((index + 1) + "  " + options[index].label));
        return Math.ceil(widest) + 12;
    }

    FontMetrics {
        id: labelMetrics

        font.pixelSize: rootKipChooser.kipTheme.bodyPixelSize
        font.bold: true
    }

    height: chooserColumn.implicitHeight + 16
    radius: rootKipChooser.kipTheme.rowRadius
    color: rootKipChooser.kipTheme.inputColor
    border.width: 1
    border.color: rootKipChooser.kipTheme.focusBorderColor

    Column {
        id: chooserColumn

        anchors {
            left: rootKipChooser.previewShown ? previewFrame.right : parent.left
            right: parent.right
            top: parent.top
            margins: 8
        }
        spacing: 2

        Text {
            width: parent.width
            text: rootKipChooser.title
            color: rootKipChooser.kipTheme.secondaryTextColor
            font.pixelSize: rootKipChooser.kipTheme.metaPixelSize + 1
            elide: Text.ElideMiddle
            bottomPadding: 4
        }

        Repeater {
            model: rootKipChooser.options

            // Options may carry a "section"; the first option of each section
            // gets a small header above it. Without sections (KIP), rows are
            // exactly as before.
            Column {
                id: openerItem

                required property var modelData
                required property int index
                readonly property bool newSection: modelData.section !== undefined && (index === 0 || rootKipChooser.options[index - 1].section !== modelData.section)

                width: parent.width

                Text {
                    visible: openerItem.newSection
                    leftPadding: 8
                    topPadding: openerItem.index === 0 ? 0 : 6
                    bottomPadding: 2
                    text: openerItem.modelData.section || ""
                    color: rootKipChooser.kipTheme.tertiaryAccentColor
                    font.pixelSize: rootKipChooser.kipTheme.metaPixelSize
                    font.bold: true
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1
                }

                Rectangle {
                    id: openerRow

                    readonly property var modelData: openerItem.modelData
                    readonly property int index: openerItem.index

                    readonly property bool selected: index === rootKipChooser.selectedIndex

                    width: openerItem.width
                    height: rootKipChooser.kipTheme.commandRowHeight - 6
                    radius: rootKipChooser.kipTheme.rowRadius
                    color: selected ? rootKipChooser.kipTheme.selectedRowColor : (openerMouse.containsMouse ? rootKipChooser.kipTheme.hoveredRowColor : "transparent")

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            text: openerRow.modelData.icon
                            color: rootKipChooser.kipTheme.accentColor
                            font.family: rootKipChooser.iconFontFamily
                            font.pixelSize: rootKipChooser.kipTheme.iconPixelSize - 2
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: rootKipChooser.labelWidth
                            text: (openerRow.index + 1) + "  " + openerRow.modelData.label
                            color: rootKipChooser.kipTheme.primaryTextColor
                            font.pixelSize: rootKipChooser.kipTheme.bodyPixelSize
                            font.bold: openerRow.selected
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: openerRow.modelData.hint
                            color: rootKipChooser.kipTheme.secondaryTextColor
                            font.pixelSize: rootKipChooser.kipTheme.metaPixelSize + 1
                        }
                    }

                    MouseArea {
                        id: openerMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            rootKipChooser.picked(openerRow.index);
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: previewFrame

        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 8
        }
        width: rootKipChooser.kipTheme.chooserPreviewWidth
        visible: rootKipChooser.previewShown
        radius: rootKipChooser.kipTheme.rowRadius
        color: rootKipChooser.kipTheme.inputColor
        clip: true

        Image {
            id: previewImage

            anchors.fill: parent
            anchors.margins: 4
            source: rootKipChooser.previewSource
            sourceSize.width: Math.round(width * 1.5)
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
        }

        Text {
            anchors.centerIn: parent
            visible: previewImage.status === Image.Error
            text: "preview failed"
            color: rootKipChooser.kipTheme.secondaryTextColor
            font.pixelSize: rootKipChooser.kipTheme.metaPixelSize
        }
    }
}

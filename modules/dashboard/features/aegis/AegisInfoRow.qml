import QtQuick
import Quickshell

Item {
    id: rootAegisInfoRow

    required property QtObject theme
    property QtObject service
    property string label: ""
    property string value: ""
    property string copyValue: value
    property bool hasProgress: false
    property real progress: 0
    readonly property real indent: 14
    readonly property real rightInset: 14
    readonly property real labelWidth: Math.min(170, Math.max(86, width * 0.34))
    readonly property real valueWidth: Math.max(1, content.width - labelWidth - row.spacing)
    readonly property real normalizedProgress: Math.max(0, Math.min(1, progress))

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            if (rootAegisInfoRow.service)
                rootAegisInfoRow.service.copyValue(rootAegisInfoRow.copyValue, rootAegisInfoRow.label);
            else
                Quickshell.clipboardText = rootAegisInfoRow.copyValue;
            mouse.accepted = true;
        }
    }

    Column {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: rootAegisInfoRow.indent
            rightMargin: rootAegisInfoRow.rightInset
        }
        spacing: 4

        Row {
            id: row

            width: parent.width
            spacing: 10

            Text {
                id: labelText

                width: rootAegisInfoRow.labelWidth
                text: rootAegisInfoRow.label
                color: rootAegisInfoRow.theme.modules.aegis.secondaryTextColor
                font.pixelSize: rootAegisInfoRow.theme.modules.aegis.bodyPixelSize
                elide: Text.ElideRight
            }

            Text {
                id: valueText

                width: rootAegisInfoRow.valueWidth
                text: rootAegisInfoRow.value
                color: rootAegisInfoRow.theme.modules.aegis.primaryTextColor
                font.pixelSize: rootAegisInfoRow.theme.modules.aegis.bodyPixelSize
                maximumLineCount: 1
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
        }

        Item {
            visible: rootAegisInfoRow.hasProgress
            width: parent.width
            height: 8

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: rootAegisInfoRow.labelWidth + row.spacing
                    verticalCenter: parent.verticalCenter
                }
                height: Math.max(4, Math.min(6, rootAegisInfoRow.theme.modules.aegis.graphBarHeight))
                radius: height / 2
                color: Qt.rgba(rootAegisInfoRow.theme.modules.aegis.secondaryTextColor.r, rootAegisInfoRow.theme.modules.aegis.secondaryTextColor.g, rootAegisInfoRow.theme.modules.aegis.secondaryTextColor.b, 0.16)

                Rectangle {
                    width: parent.width * rootAegisInfoRow.normalizedProgress
                    height: parent.height
                    radius: parent.radius
                    color: rootAegisInfoRow.theme.modules.aegis.accentColor
                }
            }
        }
    }
}

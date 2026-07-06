import QtQuick
import Quickshell

Item {
    id: rootAegisInfoRow

    required property QtObject theme
    property QtObject service
    property string label: ""
    property string value: ""
    property string copyValue: value

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

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

    Row {
        id: row

        anchors.fill: parent
        spacing: 10

        Text {
            id: labelText

            width: Math.min(160, Math.max(78, rootAegisInfoRow.width * 0.34))
            text: rootAegisInfoRow.label
            color: rootAegisInfoRow.theme.modules.aegis.secondaryTextColor
            font.pixelSize: rootAegisInfoRow.theme.modules.aegis.bodyPixelSize
            elide: Text.ElideRight
        }

        Text {
            id: valueText

            width: Math.max(1, rootAegisInfoRow.width - labelText.width - row.spacing)
            text: rootAegisInfoRow.value
            color: rootAegisInfoRow.theme.modules.aegis.primaryTextColor
            font.pixelSize: rootAegisInfoRow.theme.modules.aegis.bodyPixelSize
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}

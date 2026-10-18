import QtQuick

// Header row: icon and title on the left, Help and backend status chips on the
// right. reveal (0 → 1) slides the two sides in from the middle; the panel
// owns placement and opacity.
Item {
    id: rootKipHeader

    required property QtObject kipTheme
    required property QtObject service
    property string iconFontFamily: ""
    property real reveal: 1
    property bool helpOpen: false

    signal helpClicked

    Row {
        anchors.verticalCenter: parent.verticalCenter
        x: (1 - rootKipHeader.reveal) * 36
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: rootKipHeader.kipTheme.kipIcon
            color: rootKipHeader.kipTheme.accentColor
            font.family: rootKipHeader.iconFontFamily
            font.pixelSize: rootKipHeader.kipTheme.headerIconPixelSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "KIP"
            color: rootKipHeader.kipTheme.primaryTextColor
            font.pixelSize: rootKipHeader.kipTheme.titlePixelSize
            font.bold: true
            font.letterSpacing: 2
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Knowledge & Intelligence Presence"
            color: rootKipHeader.kipTheme.secondaryTextColor
            font.pixelSize: rootKipHeader.kipTheme.subtitlePixelSize
        }
    }

    // Help chip, left of the status chip: opens the keys sheet.
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: statusChip.x - width - 8
        width: helpRow.implicitWidth + 16
        height: statusChip.height
        radius: rootKipHeader.kipTheme.chipRadius
        color: rootKipHeader.helpOpen ? rootKipHeader.kipTheme.commandHighlightColor : (helpMouse.containsMouse ? rootKipHeader.kipTheme.hoveredRowColor : rootKipHeader.kipTheme.chipColor)
        border.width: rootKipHeader.helpOpen ? 1 : 0
        border.color: rootKipHeader.kipTheme.focusBorderColor

        Row {
            id: helpRow

            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰌌"
                color: rootKipHeader.kipTheme.accentColor
                font.family: rootKipHeader.iconFontFamily
                font.pixelSize: rootKipHeader.kipTheme.metaPixelSize + 3
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Help"
                color: rootKipHeader.kipTheme.secondaryTextColor
                font.pixelSize: rootKipHeader.kipTheme.metaPixelSize
            }
        }

        MouseArea {
            id: helpMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: rootKipHeader.helpClicked()
        }
    }

    Rectangle {
        id: statusChip

        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - (1 - rootKipHeader.reveal) * 36
        width: statusRow.implicitWidth + 16
        height: statusRow.implicitHeight + 8
        radius: rootKipHeader.kipTheme.chipRadius
        color: rootKipHeader.kipTheme.chipColor

        Row {
            id: statusRow

            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 7
                height: 7
                radius: 4
                // Mock backend: amber, not green. Green is for things that exist.
                color: rootKipHeader.service.status === "error" || !rootKipHeader.service.backendAvailable ? rootKipHeader.kipTheme.errorColor : (rootKipHeader.service.mock ? rootKipHeader.kipTheme.warningColor : rootKipHeader.kipTheme.successColor)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: rootKipHeader.service.mock ? "Local AI · mock" : (rootKipHeader.service.model.length > 0 ? "Local AI · " + rootKipHeader.service.model : "Local AI")
                color: rootKipHeader.kipTheme.secondaryTextColor
                font.pixelSize: rootKipHeader.kipTheme.metaPixelSize
            }
        }
    }
}

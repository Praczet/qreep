import QtQuick

// /qreep rows: icon, human label, and the raw "target function <args>" dim on
// the right so the actual call is never a mystery. Grouped by catalog group;
// the service sorts so each group is contiguous, which ListView sections need.
ListView {
    id: rootKipQreepList

    required property QtObject kipTheme
    required property string iconFontFamily
    required property var results
    // Group title -> icon, from the catalog, for section headers.
    property var groupIcons: ({})

    signal activated(int index)

    model: results
    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    implicitHeight: contentHeight

    section.property: "groupTitle"
    section.criteria: ViewSection.FullString
    section.delegate: Item {
        id: sectionHeader

        required property string section

        width: ListView.view.width
        height: rootKipQreepList.kipTheme.qreepSectionHeight

        Row {
            anchors {
                left: parent.left
                leftMargin: 6
                bottom: parent.bottom
                bottomMargin: 6
            }
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: rootKipQreepList.groupIcons[sectionHeader.section] || ""
                color: rootKipQreepList.kipTheme.tertiaryAccentColor
                font.family: rootKipQreepList.iconFontFamily
                font.pixelSize: rootKipQreepList.kipTheme.qreepSectionIconPixelSize
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: sectionHeader.section
                color: rootKipQreepList.kipTheme.tertiaryAccentColor
                font.pixelSize: rootKipQreepList.kipTheme.qreepSectionPixelSize
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1
            }
        }
    }

    onCurrentIndexChanged: {
        if (currentIndex >= 0)
            positionViewAtIndex(currentIndex, ListView.Contain);
    }

    delegate: Rectangle {
        id: qreepRow

        required property var modelData
        required property int index

        readonly property bool selected: index === rootKipQreepList.currentIndex

        width: ListView.view.width
        height: rootKipQreepList.kipTheme.qreepRowHeight
        radius: rootKipQreepList.kipTheme.rowRadius
        color: selected ? rootKipQreepList.kipTheme.selectedRowColor : (rowMouse.containsMouse ? rootKipQreepList.kipTheme.hoveredRowColor : "transparent")
        border.width: selected ? 1 : 0
        border.color: rootKipQreepList.kipTheme.focusBorderColor
        // Debug/hidden rows only show with Ctrl+H; dim them so they look borrowed.
        opacity: qreepRow.modelData.listed ? 1 : 0.62

        Behavior on color {
            ColorAnimation {
                duration: rootKipQreepList.kipTheme.reducedMotion ? 0 : 90
            }
        }

        Rectangle {
            id: iconBox

            anchors {
                left: parent.left
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
            width: rootKipQreepList.kipTheme.qreepIconBoxSize
            height: width
            radius: rootKipQreepList.kipTheme.chipRadius
            color: qreepRow.selected ? rootKipQreepList.kipTheme.accentColor : rootKipQreepList.kipTheme.chipColor

            Text {
                anchors.centerIn: parent
                text: qreepRow.modelData.icon
                color: qreepRow.selected ? rootKipQreepList.kipTheme.chooserColor : rootKipQreepList.kipTheme.accentColor
                font.family: rootKipQreepList.iconFontFamily
                font.pixelSize: rootKipQreepList.kipTheme.qreepIconPixelSize
            }
        }

        Text {
            id: titleText

            anchors {
                left: iconBox.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: Math.min(implicitWidth, parent.width - iconBox.width - 40 - callText.implicitWidth)
            text: qreepRow.modelData.title
            color: rootKipQreepList.kipTheme.primaryTextColor
            font.pixelSize: rootKipQreepList.kipTheme.bodyPixelSize
            font.bold: qreepRow.selected
            elide: Text.ElideRight
        }

        Text {
            id: callText

            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: Math.min(implicitWidth, parent.width * 0.45)
            horizontalAlignment: Text.AlignRight
            text: qreepRow.modelData.shortName + " " + qreepRow.modelData.name + qreepRow.modelData.params.map(param => " <" + param.name + ">").join("")
            color: rootKipQreepList.kipTheme.secondaryTextColor
            font.family: rootKipQreepList.kipTheme.monoFontFamily
            font.pixelSize: rootKipQreepList.kipTheme.metaPixelSize
            elide: Text.ElideLeft
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                rootKipQreepList.currentIndex = qreepRow.index;
                rootKipQreepList.activated(qreepRow.index);
            }
        }
    }
}

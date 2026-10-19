import QtQuick

// /qreep toggle list: one row per item of a catalog `toggles` action, with a
// switch showing the state the shell last reported. Clicking a row flips it.
ListView {
    id: rootKipQreepToggleList

    required property QtObject kipTheme
    required property string iconFontFamily
    required property var items
    property string title: ""
    property string icon: ""

    signal activated(int index)

    model: items
    clip: true
    spacing: 2
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    implicitHeight: contentHeight

    header: Item {
        width: ListView.view.width
        height: rootKipQreepToggleList.kipTheme.qreepSectionHeight

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
                text: rootKipQreepToggleList.icon
                color: rootKipQreepToggleList.kipTheme.tertiaryAccentColor
                font.family: rootKipQreepToggleList.iconFontFamily
                font.pixelSize: rootKipQreepToggleList.kipTheme.qreepSectionIconPixelSize
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: rootKipQreepToggleList.title
                color: rootKipQreepToggleList.kipTheme.tertiaryAccentColor
                font.pixelSize: rootKipQreepToggleList.kipTheme.qreepSectionPixelSize
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
        id: toggleRow

        required property var modelData
        required property int index

        readonly property bool selected: index === rootKipQreepToggleList.currentIndex
        readonly property bool on: modelData.on

        width: ListView.view.width
        height: rootKipQreepToggleList.kipTheme.qreepToggleRowHeight
        radius: rootKipQreepToggleList.kipTheme.rowRadius
        color: selected ? rootKipQreepToggleList.kipTheme.selectedRowColor : (rowMouse.containsMouse ? rootKipQreepToggleList.kipTheme.hoveredRowColor : "transparent")
        border.width: selected ? 1 : 0
        border.color: rootKipQreepToggleList.kipTheme.focusBorderColor

        Behavior on color {
            ColorAnimation {
                duration: rootKipQreepToggleList.kipTheme.reducedMotion ? 0 : 90
            }
        }

        // Switch: track plus a knob that slides right when on.
        Rectangle {
            id: track

            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            width: rootKipQreepToggleList.kipTheme.qreepSwitchWidth
            height: rootKipQreepToggleList.kipTheme.qreepSwitchHeight
            radius: height / 2
            color: toggleRow.on ? rootKipQreepToggleList.kipTheme.accentColor : rootKipQreepToggleList.kipTheme.chipColor
            border.width: 1
            border.color: toggleRow.on ? rootKipQreepToggleList.kipTheme.accentColor : rootKipQreepToggleList.kipTheme.borderColor

            Rectangle {
                width: parent.height - 6
                height: width
                radius: width / 2
                y: 3
                x: toggleRow.on ? parent.width - width - 3 : 3
                color: toggleRow.on ? rootKipQreepToggleList.kipTheme.chooserColor : rootKipQreepToggleList.kipTheme.secondaryTextColor

                Behavior on x {
                    NumberAnimation {
                        duration: rootKipQreepToggleList.kipTheme.reducedMotion ? 0 : 120
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: rootKipQreepToggleList.kipTheme.reducedMotion ? 0 : 120
                }
            }
        }

        Text {
            anchors {
                left: track.right
                leftMargin: 12
                right: stateText.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: toggleRow.modelData.id
            color: toggleRow.on ? rootKipQreepToggleList.kipTheme.primaryTextColor : rootKipQreepToggleList.kipTheme.secondaryTextColor
            font.family: rootKipQreepToggleList.kipTheme.monoFontFamily
            font.pixelSize: rootKipQreepToggleList.kipTheme.bodyPixelSize
            font.bold: toggleRow.selected
            elide: Text.ElideRight
        }

        Text {
            id: stateText

            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            text: toggleRow.on ? "on" : "off"
            color: toggleRow.on ? rootKipQreepToggleList.kipTheme.accentColor : rootKipQreepToggleList.kipTheme.secondaryTextColor
            font.family: rootKipQreepToggleList.kipTheme.monoFontFamily
            font.pixelSize: rootKipQreepToggleList.kipTheme.metaPixelSize
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                rootKipQreepToggleList.currentIndex = toggleRow.index;
                rootKipQreepToggleList.activated(toggleRow.index);
            }
        }
    }
}

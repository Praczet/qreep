import QtQuick
import QtQuick.Effects

// Help sheet: every shortcut, grouped by where it applies, floating over the
// body like the action chooser. The group for what you are doing right now
// comes first and wears the accent.
Rectangle {
    id: rootKipShortcuts

    required property QtObject kipTheme
    required property var groups
    property string activeGroup: ""
    property real maxHeight: 500

    signal closeRequested

    // Current context first, the rest in their registry order.
    readonly property var orderedGroups: groups.filter(group => group.id === activeGroup).concat(groups.filter(group => group.id !== activeGroup))

    height: Math.min(sheetFlick.contentHeight + titleRow.height + 28, maxHeight)
    radius: kipTheme.rowRadius + 3
    color: kipTheme.chooserColor
    border.width: 1
    border.color: kipTheme.focusBorderColor

    layer.enabled: visible
    layer.effect: MultiEffect {
        shadowEnabled: true
        autoPaddingEnabled: true
        shadowHorizontalOffset: 0
        shadowVerticalOffset: rootKipShortcuts.kipTheme.chooserShadowOffset
        shadowBlur: rootKipShortcuts.kipTheme.chooserShadowBlur
        shadowColor: rootKipShortcuts.kipTheme.chooserShadowColor
    }

    // Clicks inside the sheet must not fall through to the card.
    MouseArea {
        anchors.fill: parent
    }

    Item {
        id: titleRow

        x: 14
        y: 10
        width: parent.width - 28
        height: 22

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Keys"
            color: rootKipShortcuts.kipTheme.primaryTextColor
            font.pixelSize: rootKipShortcuts.kipTheme.bodyPixelSize + 1
            font.bold: true
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            text: "Esc or Ctrl+/ closes · /help for commands"
            color: rootKipShortcuts.kipTheme.secondaryTextColor
            font.pixelSize: rootKipShortcuts.kipTheme.metaPixelSize

            MouseArea {
                anchors.fill: parent
                onClicked: rootKipShortcuts.closeRequested()
            }
        }
    }

    Flickable {
        id: sheetFlick

        x: 14
        y: titleRow.y + titleRow.height + 8
        width: parent.width - 28
        height: parent.height - y - 10
        contentHeight: groupFlow.implicitHeight
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Flow {
            id: groupFlow

            width: parent.width
            spacing: 14

            Repeater {
                model: rootKipShortcuts.orderedGroups

                Column {
                    id: groupColumn

                    required property var modelData

                    readonly property bool active: modelData.id === rootKipShortcuts.activeGroup

                    width: (groupFlow.width - groupFlow.spacing) / 2
                    spacing: 3

                    Text {
                        text: groupColumn.modelData.title + (groupColumn.active ? "  · here" : "")
                        color: groupColumn.active ? rootKipShortcuts.kipTheme.accentColor : rootKipShortcuts.kipTheme.tertiaryAccentColor
                        font.pixelSize: rootKipShortcuts.kipTheme.metaPixelSize + 1
                        font.bold: true
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.6
                        bottomPadding: 3
                    }

                    Repeater {
                        model: groupColumn.modelData.keys

                        Row {
                            id: keyRow

                            required property var modelData

                            spacing: 10

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 108
                                height: keyText.implicitHeight + 6
                                radius: rootKipShortcuts.kipTheme.chipRadius
                                color: groupColumn.active ? rootKipShortcuts.kipTheme.commandHighlightColor : rootKipShortcuts.kipTheme.chipColor

                                Text {
                                    id: keyText

                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    horizontalAlignment: Text.AlignHCenter
                                    text: keyRow.modelData[0]
                                    color: rootKipShortcuts.kipTheme.primaryTextColor
                                    font.family: rootKipShortcuts.kipTheme.monoFontFamily
                                    font.pixelSize: rootKipShortcuts.kipTheme.metaPixelSize + 1
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: groupColumn.width - 118
                                text: keyRow.modelData[1]
                                color: rootKipShortcuts.kipTheme.secondaryTextColor
                                font.pixelSize: rootKipShortcuts.kipTheme.metaPixelSize + 2
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}

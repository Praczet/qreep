import QtQuick
import Quickshell

PopupWindow {
    id: rootCalendarPullConfirmPopup

    required property QtObject theme
    required property Item anchorItem

    signal confirmed

    anchor {
        item: rootCalendarPullConfirmPopup.anchorItem
        rect.x: rootCalendarPullConfirmPopup.anchorItem.width / 2 - rootCalendarPullConfirmPopup.width / 2
        rect.y: rootCalendarPullConfirmPopup.anchorItem.height + rootCalendarPullConfirmPopup.theme.modules.bar.calendar.popupOffsetY
    }

    implicitWidth: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmWidth
    implicitHeight: confirmLayout.implicitHeight + rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmPadding * 2
    color: "transparent"
    grabFocus: true

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootCalendarPullConfirmPopup.visible
        onActivated: rootCalendarPullConfirmPopup.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: rootCalendarPullConfirmPopup.theme.modules.bar.pill.radius
        color: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.backgroundColor
        border.color: rootCalendarPullConfirmPopup.theme.modules.bar.moduleHoverBackgroundColor

        Column {
            id: confirmLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmPadding
            }
            spacing: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmSpacing

            Text {
                width: parent.width
                text: "Pull calendar events?"
                color: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.headerTextColor
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmTitlePixelSize
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: "Google and Microsoft calendars will be refreshed."
                color: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.mutedTextColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmContentPixelSize
            }

            Row {
                width: parent.width
                spacing: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmButtonSpacing

                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmButtonHeight
                    radius: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmButtonRadius
                    color: cancelHover.hovered
                        ? rootCalendarPullConfirmPopup.theme.modules.bar.moduleHoverBackgroundColor
                        : rootCalendarPullConfirmPopup.theme.modules.bar.pill.backgroundColor
                    border.color: rootCalendarPullConfirmPopup.theme.modules.bar.moduleHoverBackgroundColor

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.dayTextColor
                        font.pixelSize: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmButtonPixelSize
                        font.weight: Font.Medium
                    }

                    HoverHandler {
                        id: cancelHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: rootCalendarPullConfirmPopup.visible = false
                    }
                }

                Rectangle {
                    width: (parent.width - parent.spacing) / 2
                    height: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmButtonHeight
                    radius: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmButtonRadius
                    color: confirmHover.hovered
                        ? rootCalendarPullConfirmPopup.theme.modules.bar.calendar.selectedDayBackgroundColor
                        : rootCalendarPullConfirmPopup.theme.modules.bar.accentColor

                    Text {
                        anchors.centerIn: parent
                        text: "Pull"
                        color: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.todayTextColor
                        font.pixelSize: rootCalendarPullConfirmPopup.theme.modules.bar.calendar.pullConfirmButtonPixelSize
                        font.weight: Font.DemiBold
                    }

                    HoverHandler {
                        id: confirmHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            rootCalendarPullConfirmPopup.confirmed();
                            rootCalendarPullConfirmPopup.visible = false;
                        }
                    }
                }
            }
        }
    }
}

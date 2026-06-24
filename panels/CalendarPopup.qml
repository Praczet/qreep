import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
    id: rootCalendarPopup

    required property QtObject theme
    required property Item anchorItem
    required property QtObject events

    readonly property date today: new Date()
    readonly property var agendaEvents:
        events.eventsForNextDays(today, rootCalendarPopup.theme.calendarAgendaDays)

    anchor {
        item: rootCalendarPopup.anchorItem
        rect.x: rootCalendarPopup.anchorItem.width / 2 - rootCalendarPopup.width / 2
        rect.y: rootCalendarPopup.anchorItem.height + rootCalendarPopup.theme.calendarPopupOffsetY
    }

    implicitWidth: rootCalendarPopup.theme.calendarPopupWidth
    implicitHeight: calendarBackground.implicitHeight
    color: "transparent"
    grabFocus: true

    Rectangle {
        id: calendarBackground

        anchors.fill: parent
        implicitHeight: popupLayout.implicitHeight + rootCalendarPopup.theme.calendarPopupPadding * 2
        radius: rootCalendarPopup.theme.moduleRadius
        color: rootCalendarPopup.theme.calendarBackground
        border.color: rootCalendarPopup.theme.moduleHoverBackground

        Row {
            id: popupLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: rootCalendarPopup.theme.calendarPopupPadding
            }
            spacing: rootCalendarPopup.theme.calendarSectionSpacing

            Column {
                id: calendarLayout

                width: rootCalendarPopup.theme.calendarSectionWidth
                spacing: rootCalendarPopup.theme.calendarItemSpacing

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(rootCalendarPopup.today, "dddd, dd MMMM")
                    color: rootCalendarPopup.theme.calendarHeaderText
                    font.pixelSize: rootCalendarPopup.theme.calendarHeaderPixelSize
                    font.weight: Font.DemiBold
                }

                DayOfWeekRow {
                    id: weekDays

                    width: parent.width
                    height: rootCalendarPopup.theme.calendarWeekDayHeight
                    locale: monthGrid.locale

                    delegate: Text {
                        required property var model

                        text: model.shortName
                        color: rootCalendarPopup.theme.calendarMutedText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: rootCalendarPopup.theme.calendarWeekDayPixelSize
                    }
                }

                MonthGrid {
                    id: monthGrid

                    width: parent.width
                    height: rootCalendarPopup.theme.calendarMonthGridHeight
                    month: rootCalendarPopup.today.getMonth()
                    year: rootCalendarPopup.today.getFullYear()

                    delegate: Rectangle {
                        required property var model

                        readonly property int eventCount: rootCalendarPopup.events.eventCountForDate(model.date)

                        implicitWidth: monthGrid.width / 7
                        implicitHeight: rootCalendarPopup.theme.calendarDayCellHeight
                        radius: rootCalendarPopup.theme.calendarDayRadius
                        color: model.today ? rootCalendarPopup.theme.calendarTodayBackground : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.today ? rootCalendarPopup.theme.calendarTodayText : model.month === monthGrid.month ? rootCalendarPopup.theme.calendarDayText : rootCalendarPopup.theme.calendarMutedText
                            font.pixelSize: rootCalendarPopup.theme.calendarDayPixelSize
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }

                            height: rootCalendarPopup.theme.calendarEventMarkerHeight
                            radius: rootCalendarPopup.theme.calendarEventMarkerRadius
                            color: parent.eventCount > 0
                                ? rootCalendarPopup.theme.eventIndicator
                                : "transparent"
                        }
                    }
                }
            }

            Rectangle {
                width: rootCalendarPopup.theme.calendarDividerWidth
                height: calendarLayout.height
                color: rootCalendarPopup.theme.moduleHoverBackground
            }

            Column {
                width: rootCalendarPopup.theme.calendarSectionWidth
                height: calendarLayout.height
                spacing: rootCalendarPopup.theme.calendarItemSpacing

                Text {
                    text: "Today + " + rootCalendarPopup.theme.calendarAgendaDays + " days"
                    color: rootCalendarPopup.theme.calendarHeaderText
                    font.pixelSize: rootCalendarPopup.theme.calendarHeaderPixelSize
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: rootCalendarPopup.agendaEvents.length === 0
                    text: "No events"
                    color: rootCalendarPopup.theme.calendarMutedText
                    font.pixelSize: rootCalendarPopup.theme.agendaTitlePixelSize
                }

                ListView {
                    width: parent.width
                    height: parent.height - rootCalendarPopup.theme.agendaListReservedHeight
                    clip: true
                    spacing: rootCalendarPopup.theme.agendaItemSpacing
                    model: rootCalendarPopup.agendaEvents

                    delegate: Row {
                        required property var modelData

                        width: ListView.view.width
                        height: eventDetails.implicitHeight
                        spacing: rootCalendarPopup.theme.agendaRowSpacing

                        Text {
                            width: rootCalendarPopup.theme.agendaDateWidth
                            text: Qt.formatDate(
                                new Date(modelData.date + "T00:00:00"),
                                "ddd dd"
                            )
                            color: rootCalendarPopup.theme.eventIndicator
                            font.pixelSize: rootCalendarPopup.theme.agendaDatePixelSize
                            font.weight: Font.DemiBold
                        }

                        Column {
                            id: eventDetails

                            width: parent.width - rootCalendarPopup.theme.agendaDetailsWidthOffset
                            spacing: rootCalendarPopup.theme.agendaDetailsSpacing

                            Text {
                                width: parent.width
                                text: modelData.title
                                color: rootCalendarPopup.theme.calendarDayText
                                font.pixelSize: rootCalendarPopup.theme.agendaTitlePixelSize
                                elide: Text.ElideRight
                            }

                            Text {
                                text: rootCalendarPopup.events.eventTimeLabel(
                                    modelData
                                )
                                color: rootCalendarPopup.theme.calendarMutedText
                                font.pixelSize: rootCalendarPopup.theme.agendaTimePixelSize
                            }
                        }
                    }
                }
            }
        }
    }
}

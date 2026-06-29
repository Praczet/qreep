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
        events.eventsForNextDays(today, rootCalendarPopup.theme.calendar.agendaDays)

    anchor {
        item: rootCalendarPopup.anchorItem
        rect.x: rootCalendarPopup.anchorItem.width / 2 - rootCalendarPopup.width / 2
        rect.y: rootCalendarPopup.anchorItem.height + rootCalendarPopup.theme.calendar.popupOffsetY
    }

    implicitWidth: rootCalendarPopup.theme.calendar.popupWidth
    implicitHeight: calendarBackground.implicitHeight
    color: "transparent"
    grabFocus: true

    Rectangle {
        id: calendarBackground

        anchors.fill: parent
        implicitHeight: popupLayout.implicitHeight + rootCalendarPopup.theme.calendar.popupPadding * 2
        radius: rootCalendarPopup.theme.modules.bar.pill.radius
        color: rootCalendarPopup.theme.calendarBackground
        border.color: rootCalendarPopup.theme.moduleHoverBackground

        Row {
            id: popupLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: rootCalendarPopup.theme.calendar.popupPadding
            }
            spacing: rootCalendarPopup.theme.calendar.sectionSpacing

            Column {
                id: calendarLayout

                width: rootCalendarPopup.theme.calendar.sectionWidth
                spacing: rootCalendarPopup.theme.calendar.itemSpacing

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(rootCalendarPopup.today, "dddd, dd MMMM")
                    color: rootCalendarPopup.theme.calendarHeaderText
                    font.pixelSize: rootCalendarPopup.theme.calendar.headerPixelSize
                    font.weight: Font.DemiBold
                }

                DayOfWeekRow {
                    id: weekDays

                    width: parent.width
                    height: rootCalendarPopup.theme.calendar.weekDayHeight
                    locale: monthGrid.locale

                    delegate: Text {
                        required property var model

                        text: model.shortName
                        color: rootCalendarPopup.theme.calendarMutedText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: rootCalendarPopup.theme.calendar.weekDayPixelSize
                    }
                }

                MonthGrid {
                    id: monthGrid

                    width: parent.width
                    height: rootCalendarPopup.theme.calendar.monthGridHeight
                    month: rootCalendarPopup.today.getMonth()
                    year: rootCalendarPopup.today.getFullYear()

                    delegate: Rectangle {
                        required property var model

                        readonly property int eventCount: rootCalendarPopup.events.eventCountForDate(model.date)

                        implicitWidth: monthGrid.width / 7
                        implicitHeight: rootCalendarPopup.theme.calendar.dayCellHeight
                        radius: rootCalendarPopup.theme.calendar.dayRadius
                        color: model.today ? rootCalendarPopup.theme.calendarTodayBackground : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.today ? rootCalendarPopup.theme.calendarTodayText : model.month === monthGrid.month ? rootCalendarPopup.theme.calendarDayText : rootCalendarPopup.theme.calendarMutedText
                            font.pixelSize: rootCalendarPopup.theme.calendar.dayPixelSize
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }

                            height: rootCalendarPopup.theme.calendar.eventMarkerHeight
                            radius: rootCalendarPopup.theme.calendar.eventMarkerRadius
                            color: parent.eventCount > 0
                                ? rootCalendarPopup.theme.eventIndicator
                                : "transparent"
                        }
                    }
                }
            }

            Rectangle {
                width: rootCalendarPopup.theme.calendar.dividerWidth
                height: calendarLayout.height
                color: rootCalendarPopup.theme.moduleHoverBackground
            }

            Column {
                width: rootCalendarPopup.theme.calendar.sectionWidth
                height: calendarLayout.height
                spacing: rootCalendarPopup.theme.calendar.itemSpacing

                Text {
                    text: "Today + " + rootCalendarPopup.theme.calendar.agendaDays + " days"
                    color: rootCalendarPopup.theme.calendarHeaderText
                    font.pixelSize: rootCalendarPopup.theme.calendar.headerPixelSize
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: rootCalendarPopup.agendaEvents.length === 0
                    text: "No events"
                    color: rootCalendarPopup.theme.calendarMutedText
                    font.pixelSize: rootCalendarPopup.theme.calendar.agendaTitlePixelSize
                }

                ListView {
                    width: parent.width
                    height: parent.height - rootCalendarPopup.theme.calendar.agendaListReservedHeight
                    clip: true
                    spacing: rootCalendarPopup.theme.calendar.agendaItemSpacing
                    model: rootCalendarPopup.agendaEvents

                    delegate: Row {
                        required property var modelData

                        width: ListView.view.width
                        height: eventDetails.implicitHeight
                        spacing: rootCalendarPopup.theme.calendar.agendaRowSpacing

                        Text {
                            width: rootCalendarPopup.theme.calendar.agendaDateWidth
                            text: Qt.formatDate(
                                new Date(modelData.date + "T00:00:00"),
                                "ddd dd"
                            )
                            color: rootCalendarPopup.theme.eventIndicator
                            font.pixelSize: rootCalendarPopup.theme.calendar.agendaDatePixelSize
                            font.weight: Font.DemiBold
                        }

                        Column {
                            id: eventDetails

                            width: parent.width - rootCalendarPopup.theme.calendar.agendaDetailsWidthOffset
                            spacing: rootCalendarPopup.theme.calendar.agendaDetailsSpacing

                            Text {
                                width: parent.width
                                text: modelData.title
                                color: rootCalendarPopup.theme.calendarDayText
                                font.pixelSize: rootCalendarPopup.theme.calendar.agendaTitlePixelSize
                                elide: Text.ElideRight
                            }

                            Text {
                                text: rootCalendarPopup.events.eventTimeLabel(
                                    modelData
                                )
                                color: rootCalendarPopup.theme.calendarMutedText
                                font.pixelSize: rootCalendarPopup.theme.calendar.agendaTimePixelSize
                            }
                        }
                    }
                }
            }
        }
    }
}

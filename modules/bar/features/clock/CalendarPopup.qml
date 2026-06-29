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
        events.eventsForNextDays(today, rootCalendarPopup.theme.modules.bar.calendar.agendaDays)

    anchor {
        item: rootCalendarPopup.anchorItem
        rect.x: rootCalendarPopup.anchorItem.width / 2 - rootCalendarPopup.width / 2
        rect.y: rootCalendarPopup.anchorItem.height + rootCalendarPopup.theme.modules.bar.calendar.popupOffsetY
    }

    implicitWidth: rootCalendarPopup.theme.modules.bar.calendar.popupWidth
    implicitHeight: calendarBackground.implicitHeight
    color: "transparent"
    grabFocus: true

    Rectangle {
        id: calendarBackground

        anchors.fill: parent
        implicitHeight: popupLayout.implicitHeight + rootCalendarPopup.theme.modules.bar.calendar.popupPadding * 2
        radius: rootCalendarPopup.theme.modules.bar.pill.radius
        color: rootCalendarPopup.theme.modules.bar.calendar.backgroundColor
        border.color: rootCalendarPopup.theme.modules.bar.moduleHoverBackgroundColor

        Row {
            id: popupLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: rootCalendarPopup.theme.modules.bar.calendar.popupPadding
            }
            spacing: rootCalendarPopup.theme.modules.bar.calendar.sectionSpacing

            Column {
                id: calendarLayout

                width: rootCalendarPopup.theme.modules.bar.calendar.sectionWidth
                spacing: rootCalendarPopup.theme.modules.bar.calendar.itemSpacing

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(rootCalendarPopup.today, "dddd, dd MMMM")
                    color: rootCalendarPopup.theme.modules.bar.calendar.headerTextColor
                    font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.headerPixelSize
                    font.weight: Font.DemiBold
                }

                DayOfWeekRow {
                    id: weekDays

                    width: parent.width
                    height: rootCalendarPopup.theme.modules.bar.calendar.weekDayHeight
                    locale: monthGrid.locale

                    delegate: Text {
                        required property var model

                        text: model.shortName
                        color: rootCalendarPopup.theme.modules.bar.calendar.mutedTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.weekDayPixelSize
                    }
                }

                MonthGrid {
                    id: monthGrid

                    width: parent.width
                    height: rootCalendarPopup.theme.modules.bar.calendar.monthGridHeight
                    month: rootCalendarPopup.today.getMonth()
                    year: rootCalendarPopup.today.getFullYear()

                    delegate: Rectangle {
                        required property var model

                        readonly property int eventCount: rootCalendarPopup.events.eventCountForDate(model.date)

                        implicitWidth: monthGrid.width / 7
                        implicitHeight: rootCalendarPopup.theme.modules.bar.calendar.dayCellHeight
                        radius: rootCalendarPopup.theme.modules.bar.calendar.dayRadius
                        color: model.today ? rootCalendarPopup.theme.modules.bar.calendar.todayBackgroundColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.today ? rootCalendarPopup.theme.modules.bar.calendar.todayTextColor : model.month === monthGrid.month ? rootCalendarPopup.theme.modules.bar.calendar.dayTextColor : rootCalendarPopup.theme.modules.bar.calendar.mutedTextColor
                            font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.dayPixelSize
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }

                            height: rootCalendarPopup.theme.modules.bar.calendar.eventMarkerHeight
                            radius: rootCalendarPopup.theme.modules.bar.calendar.eventMarkerRadius
                            color: parent.eventCount > 0
                                ? rootCalendarPopup.theme.modules.bar.accentColor
                                : "transparent"
                        }
                    }
                }
            }

            Rectangle {
                width: rootCalendarPopup.theme.modules.bar.calendar.dividerWidth
                height: calendarLayout.height
                color: rootCalendarPopup.theme.modules.bar.moduleHoverBackgroundColor
            }

            Column {
                width: rootCalendarPopup.theme.modules.bar.calendar.sectionWidth
                height: calendarLayout.height
                spacing: rootCalendarPopup.theme.modules.bar.calendar.itemSpacing

                Text {
                    text: "Today + " + rootCalendarPopup.theme.modules.bar.calendar.agendaDays + " days"
                    color: rootCalendarPopup.theme.modules.bar.calendar.headerTextColor
                    font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.headerPixelSize
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: rootCalendarPopup.agendaEvents.length === 0
                    text: "No events"
                    color: rootCalendarPopup.theme.modules.bar.calendar.mutedTextColor
                    font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaTitlePixelSize
                }

                ListView {
                    width: parent.width
                    height: parent.height - rootCalendarPopup.theme.modules.bar.calendar.agendaListReservedHeight
                    clip: true
                    spacing: rootCalendarPopup.theme.modules.bar.calendar.agendaItemSpacing
                    model: rootCalendarPopup.agendaEvents

                    delegate: Row {
                        required property var modelData

                        width: ListView.view.width
                        height: eventDetails.implicitHeight
                        spacing: rootCalendarPopup.theme.modules.bar.calendar.agendaRowSpacing

                        Text {
                            width: rootCalendarPopup.theme.modules.bar.calendar.agendaDateWidth
                            text: Qt.formatDate(
                                new Date(modelData.date + "T00:00:00"),
                                "ddd dd"
                            )
                            color: rootCalendarPopup.theme.modules.bar.accentColor
                            font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaDatePixelSize
                            font.weight: Font.DemiBold
                        }

                        Column {
                            id: eventDetails

                            width: parent.width - rootCalendarPopup.theme.modules.bar.calendar.agendaDetailsWidthOffset
                            spacing: rootCalendarPopup.theme.modules.bar.calendar.agendaDetailsSpacing

                            Text {
                                width: parent.width
                                text: modelData.title
                                color: rootCalendarPopup.theme.modules.bar.calendar.dayTextColor
                                font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaTitlePixelSize
                                elide: Text.ElideRight
                            }

                            Text {
                                text: rootCalendarPopup.events.eventTimeLabel(
                                    modelData
                                )
                                color: rootCalendarPopup.theme.modules.bar.calendar.mutedTextColor
                                font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaTimePixelSize
                            }
                        }
                    }
                }
            }
        }
    }
}

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
        events.eventsForNextDays(today, 5)

    anchor {
        item: rootCalendarPopup.anchorItem
        rect.x: rootCalendarPopup.anchorItem.width / 2 - rootCalendarPopup.width / 2
        rect.y: rootCalendarPopup.anchorItem.height + 6
    }

    implicitWidth: 590
    implicitHeight: calendarBackground.implicitHeight
    color: "transparent"
    grabFocus: true

    Rectangle {
        id: calendarBackground

        anchors.fill: parent
        implicitHeight: popupLayout.implicitHeight + 32
        radius: rootCalendarPopup.theme.moduleRadius
        color: rootCalendarPopup.theme.calendarBackground
        border.color: rootCalendarPopup.theme.moduleHoverBackground

        Row {
            id: popupLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
            spacing: 16

            Column {
                id: calendarLayout

                width: 264
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(rootCalendarPopup.today, "dddd, dd MMMM")
                    color: rootCalendarPopup.theme.calendarHeaderText
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                DayOfWeekRow {
                    id: weekDays

                    width: parent.width
                    height: 24
                    locale: monthGrid.locale

                    delegate: Text {
                        required property var model

                        text: model.shortName
                        color: rootCalendarPopup.theme.calendarMutedText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 12
                    }
                }

                MonthGrid {
                    id: monthGrid

                    width: parent.width
                    height: 180
                    month: rootCalendarPopup.today.getMonth()
                    year: rootCalendarPopup.today.getFullYear()

                    delegate: Rectangle {
                        required property var model

                        readonly property int eventCount: rootCalendarPopup.events.eventCountForDate(model.date)

                        implicitWidth: monthGrid.width / 7
                        implicitHeight: 30
                        radius: 8
                        color: model.today ? rootCalendarPopup.theme.calendarTodayBackground : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: model.today ? rootCalendarPopup.theme.calendarTodayText : model.month === monthGrid.month ? rootCalendarPopup.theme.calendarDayText : rootCalendarPopup.theme.calendarMutedText
                            font.pixelSize: 13
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }

                            height: 2
                            radius: 1
                            color: parent.eventCount > 0
                                ? rootCalendarPopup.theme.eventIndicator
                                : "transparent"
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: calendarLayout.height
                color: rootCalendarPopup.theme.moduleHoverBackground
            }

            Column {
                width: 264
                height: calendarLayout.height
                spacing: 10

                Text {
                    text: "Today + 5 days"
                    color: rootCalendarPopup.theme.calendarHeaderText
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: rootCalendarPopup.agendaEvents.length === 0
                    text: "No events"
                    color: rootCalendarPopup.theme.calendarMutedText
                    font.pixelSize: 13
                }

                ListView {
                    width: parent.width
                    height: parent.height - 34
                    clip: true
                    spacing: 8
                    model: rootCalendarPopup.agendaEvents

                    delegate: Row {
                        required property var modelData

                        width: ListView.view.width
                        height: eventDetails.implicitHeight
                        spacing: 10

                        Text {
                            width: 46
                            text: Qt.formatDate(
                                new Date(modelData.date + "T00:00:00"),
                                "ddd dd"
                            )
                            color: rootCalendarPopup.theme.eventIndicator
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Column {
                            id: eventDetails

                            width: parent.width - 56
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.title
                                color: rootCalendarPopup.theme.calendarDayText
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }

                            Text {
                                text: rootCalendarPopup.events.eventTimeLabel(
                                    modelData
                                )
                                color: rootCalendarPopup.theme.calendarMutedText
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
}

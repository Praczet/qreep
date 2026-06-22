import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
    id: rootCalendarPopup

    required property QtObject theme
    required property Item anchorItem
    required property QtObject events

    readonly property date today: new Date()

    anchor {
        item: rootCalendarPopup.anchorItem
        rect.x: rootCalendarPopup.anchorItem.width / 2
            - rootCalendarPopup.width / 2
        rect.y: rootCalendarPopup.anchorItem.height + 6
    }

    implicitWidth: 280
    implicitHeight: calendarBackground.implicitHeight
    color: "transparent"
    grabFocus: true

    Rectangle {
        id: calendarBackground

        anchors.fill: parent
        implicitHeight: calendarLayout.implicitHeight + 32
        radius: rootCalendarPopup.theme.moduleRadius
        color: rootCalendarPopup.theme.calendarBackground
        border.color: rootCalendarPopup.theme.moduleHoverBackground

        Column {
            id: calendarLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 16
            }
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

                    readonly property int eventCount:
                        rootCalendarPopup.events.eventCountForDate(model.date)

                    implicitWidth: monthGrid.width / 7
                    implicitHeight: 30
                    radius: 8
                    color: model.today
                        ? rootCalendarPopup.theme.calendarTodayBackground
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: model.day
                        color: model.today
                            ? rootCalendarPopup.theme.calendarTodayText
                            : model.month === monthGrid.month
                                ? rootCalendarPopup.theme.calendarDayText
                                : rootCalendarPopup.theme.calendarMutedText
                        font.pixelSize: 13
                    }

                    Rectangle {
                        visible: parent.eventCount > 0

                        anchors {
                            right: parent.right
                            top: parent.top
                            margins: 2
                        }

                        width: 13
                        height: 13
                        radius: 7
                        color: rootCalendarPopup.theme.eventIndicator

                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.eventCount
                            color: rootCalendarPopup.theme.calendarTodayText
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }
}

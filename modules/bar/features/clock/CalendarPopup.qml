import QtQuick
import QtQuick.Controls
import Quickshell

PopupWindow {
    id: rootCalendarPopup

    required property QtObject theme
    required property Item anchorItem
    required property QtObject events

    readonly property date today: new Date()
    property date selectedDate: new Date()
    property date visibleMonth: new Date(today.getFullYear(), today.getMonth(), 1)
    readonly property string selectedDateKey: events.dateKey(selectedDate)
    readonly property string todayKey: events.dateKey(today)
    readonly property var agendaEvents: events.visibleEventsForDate(selectedDate, today)

    anchor {
        item: rootCalendarPopup.anchorItem
        rect.x: rootCalendarPopup.anchorItem.width / 2 - rootCalendarPopup.width / 2
        rect.y: rootCalendarPopup.anchorItem.height + rootCalendarPopup.theme.modules.bar.calendar.popupOffsetY
    }

    implicitWidth: rootCalendarPopup.theme.modules.bar.calendar.popupWidth
    implicitHeight: rootCalendarPopup.theme.modules.bar.calendar.popupHeight
    color: "transparent"
    grabFocus: true

    onVisibleChanged: {
        if (!visible)
            return;

        selectToday();
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootCalendarPopup.visible
        onActivated: rootCalendarPopup.visible = false
    }

    function monthStart(date) {
        return new Date(date.getFullYear(), date.getMonth(), 1);
    }

    function selectDate(date) {
        selectedDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
        visibleMonth = monthStart(selectedDate);
    }

    function selectToday() {
        selectDate(today);
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function moveVisibleMonth(offset) {
        const targetMonth = new Date(visibleMonth.getFullYear(), visibleMonth.getMonth() + offset, 1);
        const targetDay = Math.min(selectedDate.getDate(), daysInMonth(targetMonth.getFullYear(), targetMonth.getMonth()));
        selectDate(new Date(targetMonth.getFullYear(), targetMonth.getMonth(), targetDay));
    }

    function dayBackgroundColor(model, hovered) {
        const key = events.dateKey(model.date);

        if (key === selectedDateKey)
            return rootCalendarPopup.theme.modules.bar.calendar.selectedDayBackgroundColor;

        if (model.today)
            return rootCalendarPopup.theme.modules.bar.calendar.todayBackgroundColor;

        if (hovered)
            return rootCalendarPopup.theme.modules.bar.calendar.hoveredDayBackgroundColor;

        return "transparent";
    }

    function dayTextColor(model) {
        const key = events.dateKey(model.date);

        if (key === selectedDateKey)
            return rootCalendarPopup.theme.modules.bar.calendar.selectedDayTextColor;

        if (model.today)
            return rootCalendarPopup.theme.modules.bar.calendar.todayTextColor;

        return model.month === monthGrid.month
            ? rootCalendarPopup.theme.modules.bar.calendar.dayTextColor
            : rootCalendarPopup.theme.modules.bar.calendar.mutedTextColor;
    }

    Rectangle {
        id: calendarBackground

        anchors.fill: parent
        implicitHeight: rootCalendarPopup.theme.modules.bar.calendar.popupHeight
        radius: rootCalendarPopup.theme.modules.bar.pill.radius
        color: rootCalendarPopup.theme.modules.bar.calendar.backgroundColor
        border.color: rootCalendarPopup.theme.modules.bar.moduleHoverBackgroundColor

        Row {
            id: popupLayout

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: rootCalendarPopup.theme.modules.bar.calendar.popupPadding
            }
            spacing: rootCalendarPopup.theme.modules.bar.calendar.sectionSpacing

            Column {
                id: calendarLayout

                width: rootCalendarPopup.theme.modules.bar.calendar.sectionWidth
                spacing: rootCalendarPopup.theme.modules.bar.calendar.itemSpacing

                Row {
                    width: parent.width
                    spacing: rootCalendarPopup.theme.modules.bar.calendar.itemSpacing

                    Rectangle {
                        width: rootCalendarPopup.theme.modules.bar.calendar.headerButtonSize
                        height: width
                        radius: rootCalendarPopup.theme.modules.bar.calendar.headerButtonRadius
                        color: previousMonthHover.hovered ? rootCalendarPopup.theme.modules.bar.calendar.hoveredDayBackgroundColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "<"
                            color: rootCalendarPopup.theme.modules.bar.calendar.headerTextColor
                            font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.headerPixelSize
                            font.weight: Font.DemiBold
                        }

                        HoverHandler {
                            id: previousMonthHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: rootCalendarPopup.moveVisibleMonth(-1)
                        }
                    }

                    Text {
                        width: parent.width - rootCalendarPopup.theme.modules.bar.calendar.headerButtonSize * 2 - parent.spacing * 2
                        height: rootCalendarPopup.theme.modules.bar.calendar.headerButtonSize
                        text: Qt.formatDate(rootCalendarPopup.visibleMonth, "MMMM yyyy")
                        color: rootCalendarPopup.theme.modules.bar.calendar.headerTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.headerPixelSize
                        font.weight: Font.DemiBold
                    }

                    Rectangle {
                        width: rootCalendarPopup.theme.modules.bar.calendar.headerButtonSize
                        height: width
                        radius: rootCalendarPopup.theme.modules.bar.calendar.headerButtonRadius
                        color: nextMonthHover.hovered ? rootCalendarPopup.theme.modules.bar.calendar.hoveredDayBackgroundColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: ">"
                            color: rootCalendarPopup.theme.modules.bar.calendar.headerTextColor
                            font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.headerPixelSize
                            font.weight: Font.DemiBold
                        }

                        HoverHandler {
                            id: nextMonthHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: rootCalendarPopup.moveVisibleMonth(1)
                        }
                    }
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
                    month: rootCalendarPopup.visibleMonth.getMonth()
                    year: rootCalendarPopup.visibleMonth.getFullYear()

                    delegate: Rectangle {
                        required property var model

                        readonly property int eventCount: rootCalendarPopup.events.eventCountForDate(model.date)

                        implicitWidth: monthGrid.width / 7
                        implicitHeight: rootCalendarPopup.theme.modules.bar.calendar.dayCellHeight
                        radius: rootCalendarPopup.theme.modules.bar.calendar.dayRadius
                        color: rootCalendarPopup.dayBackgroundColor(model, dayHover.hovered)

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: rootCalendarPopup.dayTextColor(model)
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

                        HoverHandler {
                            id: dayHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: rootCalendarPopup.selectDate(model.date)
                        }
                    }
                }
            }

            Rectangle {
                width: rootCalendarPopup.theme.modules.bar.calendar.dividerWidth
                height: popupLayout.height
                color: rootCalendarPopup.theme.modules.bar.moduleHoverBackgroundColor
            }

            Column {
                width: rootCalendarPopup.theme.modules.bar.calendar.agendaSectionWidth
                height: popupLayout.height
                spacing: rootCalendarPopup.theme.modules.bar.calendar.itemSpacing

                Text {
                    id: agendaHeader

                    text: Qt.formatDate(rootCalendarPopup.selectedDate, rootCalendarPopup.selectedDateKey === rootCalendarPopup.todayKey ? "'Today,' dddd dd MMMM" : "dddd dd MMMM")
                    color: rootCalendarPopup.theme.modules.bar.calendar.headerTextColor
                    font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.headerPixelSize
                    font.weight: Font.DemiBold
                }

                Text {
                    id: emptyAgendaMessage

                    visible: rootCalendarPopup.agendaEvents.length === 0
                    text: "No events"
                    color: rootCalendarPopup.theme.modules.bar.calendar.mutedTextColor
                    font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaTitlePixelSize
                }

                Item {
                    width: parent.width
                    height: Math.max(0, parent.height - agendaHeader.height - (emptyAgendaMessage.visible ? emptyAgendaMessage.height + parent.spacing : 0) - rootCalendarPopup.theme.modules.bar.calendar.agendaListTopSpacing)

                    ListView {
                        x: rootCalendarPopup.theme.modules.bar.calendar.agendaListIndent
                        y: rootCalendarPopup.theme.modules.bar.calendar.agendaListTopSpacing
                        width: parent.width
                            - rootCalendarPopup.theme.modules.bar.calendar.agendaListIndent
                        height: Math.max(0, parent.height - rootCalendarPopup.theme.modules.bar.calendar.agendaListTopSpacing)
                        clip: true
                        spacing: rootCalendarPopup.theme.modules.bar.calendar.agendaItemSpacing
                        model: rootCalendarPopup.agendaEvents

                        delegate: Rectangle {
                            required property var modelData

                            readonly property bool personalEvent: rootCalendarPopup.events.isPersonalEvent(modelData)

                            width: ListView.view.width
                            height: eventRow.implicitHeight + rootCalendarPopup.theme.modules.bar.calendar.agendaItemVerticalPadding * 2
                            radius: rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalRadius
                            color: personalEvent
                                ? rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalBackgroundColor
                                : "transparent"
                            border.width: personalEvent ? rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalBorderWidth : 0
                            border.color: rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalBorderColor

                            Row {
                                id: eventRow

                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: rootCalendarPopup.theme.modules.bar.calendar.agendaItemHorizontalPadding
                                    rightMargin: rootCalendarPopup.theme.modules.bar.calendar.agendaItemHorizontalPadding
                                }
                                spacing: rootCalendarPopup.theme.modules.bar.calendar.agendaRowSpacing

                                Rectangle {
                                    width: personalEvent
                                        ? rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalColorWidth
                                        : rootCalendarPopup.theme.modules.bar.calendar.agendaColorWidth
                                    height: eventDetails.implicitHeight
                                    radius: rootCalendarPopup.theme.modules.bar.calendar.agendaColorRadius
                                    color: personalEvent
                                        ? rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalAccentColor
                                        : rootCalendarPopup.events.eventColor(modelData, rootCalendarPopup.theme.modules.bar.accentColor)
                                }

                                Text {
                                    width: rootCalendarPopup.theme.modules.bar.calendar.agendaDateWidth
                                    text: rootCalendarPopup.events.eventTimeLabel(modelData)
                                    color: personalEvent
                                        ? rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalAccentColor
                                        : rootCalendarPopup.events.eventColor(modelData, rootCalendarPopup.theme.modules.bar.accentColor)
                                    font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaDatePixelSize
                                    font.weight: Font.DemiBold
                                }

                                Column {
                                    id: eventDetails

                                    width: parent.width - rootCalendarPopup.theme.modules.bar.calendar.agendaDetailsWidthOffset - rootCalendarPopup.theme.modules.bar.calendar.agendaItemHorizontalPadding * 2
                                    spacing: rootCalendarPopup.theme.modules.bar.calendar.agendaDetailsSpacing

                                    Text {
                                        width: parent.width
                                        text: modelData.title
                                        color: personalEvent
                                            ? rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalTitleColor
                                            : rootCalendarPopup.theme.modules.bar.calendar.dayTextColor
                                        font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaTitlePixelSize
                                        font.weight: personalEvent ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: rootCalendarPopup.events.eventMetaLabel(modelData)
                                        visible: text.length > 0
                                        color: personalEvent
                                            ? rootCalendarPopup.theme.modules.bar.calendar.agendaPersonalMetaColor
                                            : rootCalendarPopup.theme.modules.bar.calendar.mutedTextColor
                                        font.pixelSize: rootCalendarPopup.theme.modules.bar.calendar.agendaTimePixelSize
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

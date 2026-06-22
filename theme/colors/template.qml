import QtQuick

QtObject {
    id: rootTemplate

    readonly property color barBackground: "{{bar_background}}"
    readonly property color moduleBackground: "{{module_background}}"
    readonly property color moduleHoverBackground: "{{module_hover_background}}"
    readonly property color primaryText: "{{primary_text}}"
    readonly property color secondaryText: "{{secondary_text}}"
    readonly property color calendarBackground: "{{calendar_background}}"
    readonly property color calendarHeaderText: "{{calendar_header_text}}"
    readonly property color calendarDayText: "{{calendar_day_text}}"
    readonly property color calendarMutedText: "{{calendar_muted_text}}"
    readonly property color calendarTodayBackground: "{{calendar_today_background}}"
    readonly property color calendarTodayText: "{{calendar_today_text}}"
    readonly property color eventIndicator: "{{event_indicator}}"
}

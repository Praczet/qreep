import QtQuick

QtObject {
    id: rootCalendarTheme

    required property QtObject qreep

    readonly property color backgroundColor: qreep.surface
    readonly property color borderColor: qreep.surfaceContainerHigh
    readonly property color headerTextColor: qreep.on_surface
    readonly property color dayTextColor: qreep.on_surface
    readonly property color mutedTextColor: qreep.on_surface_variant
    readonly property color todayBackgroundColor: qreep.primaryContainer
    readonly property color todayTextColor: qreep.on_primary_container
    readonly property color selectedDayBackgroundColor: qreep.surfaceContainerHigh
    readonly property color selectedDayTextColor: qreep.on_surface
    readonly property color hoveredDayBackgroundColor: qreep.surfaceContainer
    readonly property color eventIndicatorColor: qreep.primary
    readonly property color agendaPersonalBackgroundColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.12)
    readonly property color agendaPersonalBorderColor: Qt.rgba(qreep.primary.r, qreep.primary.g, qreep.primary.b, 0.32)
    readonly property color agendaPersonalAccentColor: qreep.primary
    readonly property color agendaPersonalTitleColor: qreep.on_surface
    readonly property color agendaPersonalMetaColor: qreep.on_surface_variant
    readonly property color agendaSourceBadgeBackgroundColor: qreep.surfaceContainerHigh
    readonly property color agendaSourceBadgeTextColor: qreep.on_surface
    readonly property color footerTextColor: qreep.on_surface_variant

    readonly property int popupWidth: 860
    readonly property int popupHeight: 420
    readonly property int popupOffsetY: 6
    readonly property int popupPadding: 16
    readonly property int agendaDays: 5
    readonly property int sectionWidth: 248
    readonly property int agendaSectionWidth: 540
    readonly property int sectionSpacing: 22
    readonly property int itemSpacing: 8
    readonly property int headerButtonSize: 28
    readonly property int headerButtonRadius: 8
    readonly property int headerPixelSize: 18
    readonly property int weekDayHeight: 22
    readonly property int weekDayPixelSize: 12
    readonly property int monthGridHeight: 156
    readonly property int dayCellHeight: 26
    readonly property int dayRadius: 8
    readonly property int dayPixelSize: 13
    readonly property int eventMarkerHeight: 2
    readonly property int eventMarkerRadius: 1
    readonly property int dividerWidth: 1
    readonly property int agendaListTopSpacing: 10
    readonly property int agendaListIndent: 14
    readonly property int agendaItemSpacing: 14
    readonly property int agendaItemHorizontalPadding: 8
    readonly property int agendaItemVerticalPadding: 5
    readonly property int agendaRowSpacing: 10
    readonly property int agendaColorWidth: 3
    readonly property int agendaPersonalColorWidth: 5
    readonly property int agendaColorRadius: 2
    readonly property int agendaPersonalRadius: 6
    readonly property int agendaPersonalBorderWidth: 1
    readonly property int agendaDateWidth: 78
    readonly property int agendaDetailsWidthOffset: agendaDateWidth + agendaColorWidth + agendaRowSpacing * 2
    readonly property int agendaDatePixelSize: 12
    readonly property int agendaTitlePixelSize: 13
    readonly property int agendaTimePixelSize: 11
    readonly property int agendaBadgePixelSize: 10
    readonly property int agendaBadgeHorizontalPadding: 6
    readonly property int agendaBadgeHeight: 16
    readonly property int agendaBadgeRadius: 5
    readonly property int agendaDetailsSpacing: 2
    readonly property int footerPixelSize: 10
    readonly property int footerTopSpacing: 8
    readonly property int footerBottomMargin: 8
    readonly property bool useDefaultReminders: true
    readonly property int defaultReminderMinutes: 10
    readonly property int reminderCheckInterval: 60000
    readonly property int eventCacheRefreshInterval: 60000
}

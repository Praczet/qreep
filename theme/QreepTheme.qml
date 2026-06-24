import QtQuick
import "../core" as Core
import "colors" as Colors

QtObject {
    id: rootQreepTheme

    readonly property QtObject palette: Colors.UnclaimedBloomColors {}
    readonly property var requiredPaletteColors: ["barBackground", "moduleBackground", "moduleHoverBackground", "primaryText", "secondaryText", "calendarBackground", "calendarHeaderText", "calendarDayText", "calendarMutedText", "calendarTodayBackground", "calendarTodayText", "eventIndicator", "powerActionBackground", "powerActionHoverBackground", "powerActionText", "powerActionIconColor", "powerConfirmText"]

    readonly property color barBackground: paletteColor("barBackground", "#171b22")
    readonly property color moduleBackground: paletteColor("moduleBackground", "#2e3440")
    readonly property color moduleHoverBackground: paletteColor("moduleHoverBackground", "#3b4252")
    readonly property color primaryText: paletteColor("primaryText", "#b8c7e8")
    readonly property color secondaryText: paletteColor("secondaryText", "#697386")
    readonly property color calendarBackground: paletteColor("calendarBackground", "#242933")
    readonly property color calendarHeaderText: paletteColor("calendarHeaderText", "#d8dee9")
    readonly property color calendarDayText: paletteColor("calendarDayText", "#b8c7e8")
    readonly property color calendarMutedText: paletteColor("calendarMutedText", "#697386")
    readonly property color calendarTodayBackground: paletteColor("calendarTodayBackground", "#5e81ac")
    readonly property color calendarTodayText: paletteColor("calendarTodayText", "#eceff4")
    readonly property color eventIndicator: paletteColor("eventIndicator", "#88c0d0")
    readonly property color powerActionBackground: paletteColor("powerActionBackground", "#9aadd4")
    readonly property color powerActionHoverBackground: paletteColor("powerActionHoverBackground", "#b8c7e8")
    readonly property color powerActionText: paletteColor("powerActionText", "#2e3440")
    readonly property color powerActionIconColor: paletteColor("powerActionIconColor", "#3e4554")
    readonly property color powerConfirmText: paletteColor("powerConfirmText", "#d8dee9")

    readonly property string iconFontFamily: "FiraCode Nerd Font"
    readonly property int animationFastDuration: 100

    readonly property string logNotificationBackend: "notify-send"
    readonly property bool logNotifyWarnings: true
    readonly property bool logNotifyErrors: true
    readonly property int logNotificationDuration: 5000
    readonly property string logWarningColor: "rgb(f9e2af)"
    readonly property string logErrorColor: "rgb(ffb4ab)"

    readonly property Core.Log paletteLog: Core.Log {
        notificationBackend: rootQreepTheme.logNotificationBackend
        notifyWarnings: rootQreepTheme.logNotifyWarnings
        notifyErrors: rootQreepTheme.logNotifyErrors
        notificationDuration: rootQreepTheme.logNotificationDuration
        warningColor: rootQreepTheme.logWarningColor
        errorColor: rootQreepTheme.logErrorColor
    }

    readonly property int barHeight: 46
    readonly property int barPowerButtonRightMargin: 4

    readonly property int moduleHeight: 48
    readonly property int moduleRadius: 20
    readonly property int moduleHorizontalPadding: 20
    readonly property int moduleSpacing: 8

    readonly property int clockTimePixelSize: 42
    readonly property int clockDatePixelSize: 14
    readonly property int clockSecondRefreshInterval: 1000
    readonly property int clockMinuteRefreshInterval: 60000
    readonly property int clockMinimumRefreshInterval: 50
    readonly property int clockEventIndicatorSize: 8
    readonly property int clockEventIndicatorRadius: 4
    readonly property int clockEventIndicatorSpacing: 4
    readonly property int clockMaxEventIndicators: 5

    readonly property int powerButtonIconPixelSize: 20

    readonly property int powerSidebarWidth: 360
    readonly property real powerSidebarOpacity: 0.82
    readonly property int powerCardWidth: 260
    readonly property int powerCardPadding: 20
    readonly property int powerCardRadius: 18
    readonly property int powerActionHeight: 54
    readonly property int powerActionRadius: 10
    readonly property int powerActionSpacing: 8
    readonly property int powerActionContentSpacing: 14
    readonly property int powerActionIconSize: 30
    readonly property real powerActionIconColorization: 1
    readonly property real powerActionIconBrightness: 1.2
    readonly property int powerActionLabelWidth: 92
    readonly property int powerActionTextPixelSize: 14
    readonly property int powerConfirmTitlePixelSize: 16
    readonly property int powerConfirmContentPixelSize: 12
    readonly property int powerConfirmContentBottomPadding: 10
    readonly property int powerConfirmButtonSpacing: 10

    readonly property int calendarPopupWidth: 590
    readonly property int calendarPopupOffsetY: 6
    readonly property int calendarPopupPadding: 16
    readonly property int calendarAgendaDays: 5
    readonly property int calendarSectionWidth: 264
    readonly property int calendarSectionSpacing: 16
    readonly property int calendarItemSpacing: 10
    readonly property int calendarHeaderPixelSize: 18
    readonly property int calendarWeekDayHeight: 24
    readonly property int calendarWeekDayPixelSize: 12
    readonly property int calendarMonthGridHeight: 180
    readonly property int calendarDayCellHeight: 30
    readonly property int calendarDayRadius: 8
    readonly property int calendarDayPixelSize: 13
    readonly property int calendarEventMarkerHeight: 2
    readonly property int calendarEventMarkerRadius: 1
    readonly property int calendarDividerWidth: 1
    readonly property int agendaListReservedHeight: 34
    readonly property int agendaItemSpacing: 8
    readonly property int agendaRowSpacing: 10
    readonly property int agendaDateWidth: 46
    readonly property int agendaDetailsWidthOffset: 56
    readonly property int agendaDatePixelSize: 12
    readonly property int agendaTitlePixelSize: 13
    readonly property int agendaTimePixelSize: 11
    readonly property int agendaDetailsSpacing: 2

    readonly property int tooltipOffsetY: 8
    readonly property int tooltipMinimumWidth: 180
    readonly property int tooltipHorizontalPadding: 16
    readonly property int tooltipVerticalPadding: 12
    readonly property int tooltipRadius: 10
    readonly property int tooltipBorderWidth: 1
    readonly property int tooltipPadding: 12
    readonly property int tooltipSpacing: 4
    readonly property int tooltipTitlePixelSize: 13
    readonly property int tooltipContentPixelSize: 12
    readonly property real tooltipContentLineHeight: 1.15
    readonly property int tooltipShowDelay: 400
    readonly property int tooltipHideDelay: 500
    readonly property real tooltipPopScale: 1.2
    readonly property int tooltipShowOutDuration: 120
    readonly property int tooltipShowSettleDuration: 90
    readonly property int tooltipHideOutDuration: 80
    readonly property int tooltipHideInDuration: 120

    readonly property int osdPanelHeight: 160
    readonly property int osdTopMargin: 58
    readonly property int osdScreenPadding: 24
    readonly property int osdHorizontalPadding: 22
    readonly property int osdVerticalPadding: 14
    readonly property int osdRadius: 14
    readonly property int osdBorderWidth: 1
    readonly property real osdOpacity: 0.5
    readonly property int osdTitleTextPixelSize: 15
    readonly property int osdMessageTextPixelSize: 13
    readonly property int osdIconSize: 30
    readonly property int osdContentSpacing: 12
    readonly property int osdTextSpacing: 3
    readonly property int osdDefaultDuration: 1600
    readonly property string osdDefaultPosition: "top"
    readonly property int osdTestButtonLeftMargin: 4
    readonly property int osdTestButtonTextPixelSize: 13

    function paletteColor(propertyName, fallbackColor) {
        const value = palette[propertyName];
        return value === undefined ? fallbackColor : value;
    }

    function validatePalette() {
        const missingColors = requiredPaletteColors.filter(propertyName => palette[propertyName] === undefined);

        if (missingColors.length === 0)
            return;
        const message = "Missing generated palette properties: " + missingColors.join(", ");

        paletteLog.error("Qreep theme error:", message);
    }

    Component.onCompleted: validatePalette()
}

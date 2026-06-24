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

    readonly property QtObject bar: BarTheme {}
    readonly property QtObject module: ModuleTheme {}
    readonly property QtObject clock: ClockTheme {}
    readonly property QtObject power: PowerTheme {}
    readonly property QtObject calendar: CalendarTheme {}
    readonly property QtObject tooltip: TooltipTheme {}
    readonly property QtObject osd: OsdTheme {}
    readonly property QtObject borg: BorgTheme {}

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

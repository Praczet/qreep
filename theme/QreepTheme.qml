import QtQuick
import "../core" as Core
import "../modules" as Modules
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
    readonly property color overlaySurfaceBackground: Qt.rgba(calendarBackground.r, calendarBackground.g, calendarBackground.b, power.sidebarOpacity)
    readonly property color overlaySurfaceBorder: moduleHoverBackground

    readonly property QtObject modules: Modules.ModulesTheme {
        qreep: rootQreepTheme
    }

    readonly property QtObject bar: modules.bar
    readonly property QtObject dashboard: modules.dashboard
    readonly property QtObject osd: modules.osd

    readonly property QtObject module: modules.bar.pill
    readonly property QtObject tooltip: modules.bar.tooltip
    readonly property QtObject clock: modules.bar.clock
    readonly property QtObject calendar: modules.bar.calendar
    readonly property QtObject power: modules.bar.power
    readonly property QtObject borg: modules.bar.borg
    readonly property QtObject upchecker: modules.bar.upchecker
    readonly property QtObject monitorProfile: modules.bar.monitorProfile
    readonly property QtObject mpris: modules.bar.mpris
    readonly property QtObject workspaces: modules.bar.workspaces
    readonly property QtObject launcher: modules.bar.launcher

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

    function borgClassColor(className) {
        switch (className) {
        case "ok":
            return borg.okColor;
        case "warning":
            return borg.warningColor;
        case "error":
            return borg.errorColor;
        default:
            return primaryText;
        }
    }

    function borgTokenColor(token) {
        switch (String(token || "")) {
        case "{{primary}}":
            return primaryText;
        case "{{secondary}}":
            return secondaryText;
        case "{{tertiary}}":
            return borg.okColor;
        case "{{on_surface}}":
            return calendarHeaderText;
        case "{{on_surface_variant}}":
            return calendarMutedText;
        case "{{error}}":
            return borg.errorColor;
        default:
            return calendarDayText;
        }
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

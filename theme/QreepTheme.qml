import QtQuick
import Quickshell.Io
import "colors" as Colors

QtObject {
    id: rootQreepTheme

    readonly property QtObject palette: Colors.UnclaimedBloomColors {}
    readonly property var requiredPaletteColors: ["barBackground", "moduleBackground", "moduleHoverBackground", "primaryText", "secondaryText", "calendarBackground", "calendarHeaderText", "calendarDayText", "calendarMutedText", "calendarTodayBackground", "calendarTodayText", "eventIndicator", "powerActionBackground", "powerActionHoverBackground", "powerActionText", "powerActionIconColor"]
    readonly property Process paletteErrorNotifier: Process {}

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

    readonly property int barHeight: 46
    readonly property int moduleHeight: 48
    readonly property int moduleRadius: 20
    readonly property int moduleHorizontalPadding: 20
    readonly property int moduleSpacing: 8

    readonly property int clockTimePixelSize: 42
    readonly property int clockDatePixelSize: 14

    readonly property int powerSidebarWidth: 360
    readonly property real powerSidebarOpacity: 0.82
    readonly property int powerCardWidth: 260
    readonly property int powerCardPadding: 20
    readonly property int powerCardRadius: 18
    readonly property int powerActionHeight: 54
    readonly property int powerActionRadius: 10
    readonly property int powerActionSpacing: 8

    function paletteColor(propertyName, fallbackColor) {
        const value = palette[propertyName];
        return value === undefined ? fallbackColor : value;
    }

    function validatePalette() {
        const missingColors = requiredPaletteColors.filter(propertyName => palette[propertyName] === undefined);

        if (missingColors.length === 0)
            return;
        const message = "Missing generated palette properties: " + missingColors.join(", ");

        console.error("Qreep theme error:", message);

        paletteErrorNotifier.command = ["notify-send", "--urgency=critical", "--app-name=Qreep", "Qreep theme error", message];
        paletteErrorNotifier.running = true;
    }

    Component.onCompleted: validatePalette()
}

import QtQuick
import "../core" as Core
import "../modules" as Modules
import "colors" as Colors

QtObject {
    id: rootQreepTheme

    readonly property QtObject palette: Colors.UnclaimedBloomColors {}
    readonly property var requiredPaletteColors: ["background", "surface", "surfaceContainer", "surfaceContainerHigh", "surfaceContainerHighest", "primary", "primaryContainer", "primaryFixedDim", "on_surface", "on_surface_variant", "on_primary", "on_primary_container", "outline", "outlineVariant", "error", "warningColor", "successColor"]

    readonly property color background: paletteColor("background", "#171b22")
    readonly property color surface: paletteColor("surface", "#242933")
    readonly property color surfaceVariant: paletteColor("surfaceVariant", "#3b4252")
    readonly property color surfaceContainer: paletteColor("surfaceContainer", "#2e3440")
    readonly property color surfaceContainerLow: paletteColor("surfaceContainerLow", "#242933")
    readonly property color surfaceContainerLowest: paletteColor("surfaceContainerLowest", "#171b22")
    readonly property color surfaceContainerHigh: paletteColor("surfaceContainerHigh", "#3b4252")
    readonly property color surfaceContainerHighest: paletteColor("surfaceContainerHighest", "#3b4252")

    readonly property color primary: paletteColor("primary", "#88c0d0")
    readonly property color primaryContainer: paletteColor("primaryContainer", "#5e81ac")
    readonly property color primaryFixedDim: paletteColor("primaryFixedDim", "#b8c7e8")
    readonly property color primaryFixed: paletteColor("primaryFixed", "#b8c7e8")
    readonly property color secondary: paletteColor("secondary", "#b8c7e8")
    readonly property color tertiary: paletteColor("tertiary", "#a8be97")

    readonly property color on_background: paletteColor("on_background", "#b8c7e8")
    readonly property color on_surface: paletteColor("on_surface", "#b8c7e8")
    readonly property color on_surface_variant: paletteColor("on_surface_variant", "#697386")
    readonly property color on_primary: paletteColor("on_primary", "#2e3440")
    readonly property color on_primary_container: paletteColor("on_primary_container", "#eceff4")

    readonly property color outline: paletteColor("outline", "#3b4252")
    readonly property color outlineVariant: paletteColor("outlineVariant", "#3b4252")
    readonly property color error: paletteColor("error", "#ff9898")
    readonly property color warningColor: paletteColor("warningColor", "#f9e2af")
    readonly property color successColor: paletteColor("successColor", "#a8be97")

    readonly property QtObject modules: Modules.ModulesTheme {
        qreep: rootQreepTheme
    }

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

    function colorToken(token, fallbackColor) {
        switch (String(token || "")) {
        case "{{background}}":
            return background;
        case "{{surface}}":
            return surface;
        case "{{surface_variant}}":
            return surfaceVariant;
        case "{{surface_container}}":
            return surfaceContainer;
        case "{{surface_container_high}}":
            return surfaceContainerHigh;
        case "{{surface_container_highest}}":
            return surfaceContainerHighest;
        case "{{primary}}":
            return primary;
        case "{{primary_container}}":
            return primaryContainer;
        case "{{primary_fixed_dim}}":
            return primaryFixedDim;
        case "{{primary_fixed}}":
            return primaryFixed;
        case "{{secondary}}":
            return secondary;
        case "{{tertiary}}":
            return tertiary;
        case "{{on_background}}":
            return on_background;
        case "{{on_surface}}":
            return on_surface;
        case "{{on_surface_variant}}":
            return on_surface_variant;
        case "{{on_primary}}":
            return on_primary;
        case "{{on_primary_container}}":
            return on_primary_container;
        case "{{outline}}":
            return outline;
        case "{{outline_variant}}":
            return outlineVariant;
        case "{{error}}":
            return error;
        case "{{warning}}":
            return warningColor;
        case "{{success}}":
            return successColor;
        default:
            return fallbackColor;
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

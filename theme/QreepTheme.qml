import QtQuick
import Quickshell.Io
import "colors" as Colors

QtObject {
    id: rootQreepTheme

    readonly property QtObject palette: Colors.UnclaimedBloomColors {}
    readonly property var requiredPaletteColors: [
        "barBackground",
        "moduleBackground",
        "primaryText",
        "secondaryText"
    ]
    readonly property Process paletteErrorNotifier: Process {}

    readonly property color barBackground:
        paletteColor("barBackground", "#171b22")
    readonly property color moduleBackground:
        paletteColor("moduleBackground", "#2e3440")
    readonly property color primaryText:
        paletteColor("primaryText", "#b8c7e8")
    readonly property color secondaryText:
        paletteColor("secondaryText", "#697386")

    readonly property int barHeight: 52
    readonly property int moduleHeight: 44
    readonly property int moduleRadius: 12
    readonly property int moduleHorizontalPadding: 20
    readonly property int moduleSpacing: 8

    readonly property int clockTimePixelSize: 28
    readonly property int clockDatePixelSize: 14

    function paletteColor(propertyName, fallbackColor) {
        const value = palette[propertyName]
        return value === undefined ? fallbackColor : value
    }

    function validatePalette() {
        const missingColors = requiredPaletteColors.filter(
            propertyName => palette[propertyName] === undefined
        )

        if (missingColors.length === 0)
            return

        const message =
            "Missing generated palette properties: " + missingColors.join(", ")

        console.error("Qreep theme error:", message)

        paletteErrorNotifier.command = [
            "notify-send",
            "--urgency=critical",
            "--app-name=Qreep",
            "Qreep theme error",
            message
        ]
        paletteErrorNotifier.running = true
    }

    Component.onCompleted: validatePalette()
}

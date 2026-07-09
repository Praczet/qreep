import QtQuick
import Quickshell

PopupWindow {
    id: rootClockEventIndicators

    required property QtObject theme
    required property Item anchorItem
    required property QtObject events
    property var eventItems: []

    readonly property var visibleEventItems: eventItems.slice(0, theme.modules.bar.clock.maxEventIndicators)

    anchor {
        item: rootClockEventIndicators.anchorItem
        rect.x: rootClockEventIndicators.anchorItem.width / 2 - rootClockEventIndicators.width / 2
        rect.y: rootClockEventIndicators.anchorItem.height - rootClockEventIndicators.theme.modules.bar.clock.eventIndicatorSize / 2
    }

    visible: rootClockEventIndicators.anchorItem.visible && rootClockEventIndicators.visibleEventItems.length > 0
    implicitWidth: indicatorRow.implicitWidth
    implicitHeight: rootClockEventIndicators.theme.modules.bar.clock.personalEventIndicatorSize
    color: "transparent"
    grabFocus: false

    Row {
        id: indicatorRow

        anchors.centerIn: parent
        spacing: rootClockEventIndicators.theme.modules.bar.clock.eventIndicatorSpacing

        Repeater {
            model: rootClockEventIndicators.visibleEventItems

            delegate: Rectangle {
                required property var modelData

                readonly property bool personalEvent: rootClockEventIndicators.events.isPersonalEvent(modelData)

                width: personalEvent
                    ? rootClockEventIndicators.theme.modules.bar.clock.personalEventIndicatorSize
                    : rootClockEventIndicators.theme.modules.bar.clock.eventIndicatorSize
                height: width
                radius: personalEvent
                    ? rootClockEventIndicators.theme.modules.bar.clock.personalEventIndicatorRadius
                    : rootClockEventIndicators.theme.modules.bar.clock.eventIndicatorRadius
                color: personalEvent
                    ? rootClockEventIndicators.theme.warningColor
                    : rootClockEventIndicators.theme.modules.bar.accentColor
            }
        }
    }
}

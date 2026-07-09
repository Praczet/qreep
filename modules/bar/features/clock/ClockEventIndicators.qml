import QtQuick
import Quickshell

PopupWindow {
    id: rootClockEventIndicators

    required property QtObject theme
    required property Item anchorItem
    required property QtObject events
    property var eventItems: []
    property int pendingPulseIndex: -1
    property int pendingPulseLoopsRemaining: 0
    property var pulseItems: []

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

    function notifyChanged(eventId) {
        const targetId = String(eventId || "").trim();

        if (targetId.length > 0) {
            for (let index = 0; index < visibleEventItems.length; index++) {
                if (String(visibleEventItems[index].id || "") === targetId) {
                    pulseItems = [index];
                    startPulseSequence();
                    return;
                }
            }
        }

        pulseAll();
    }

    function pulseAll() {
        const indexes = [];

        for (let index = 0; index < visibleEventItems.length; index++)
            indexes.push(index);

        pulseItems = indexes;
        startPulseSequence();
    }

    function startPulseSequence() {
        pendingPulseLoopsRemaining = rootClockEventIndicators.theme.modules.bar.clock.changePulseLoops;
        pendingPulseIndex = -1;
        runNextPulse();
    }

    function runNextPulse() {
        if (pulseItems.length === 0 || pendingPulseLoopsRemaining <= 0)
            return;

        pendingPulseIndex++;

        if (pendingPulseIndex >= pulseItems.length) {
            pendingPulseIndex = 0;
            pendingPulseLoopsRemaining--;

            if (pendingPulseLoopsRemaining <= 0)
                return;
        }

        const item = pulseRepeater.itemAt(pulseItems[pendingPulseIndex]);

        if (item)
            item.pulse();
    }

    function pulseColorAt(index, fallbackColor) {
        const colors = rootClockEventIndicators.theme.modules.bar.clock.changePulseColors;

        if (!Array.isArray(colors) || index < 0 || index >= colors.length)
            return fallbackColor;

        return colors[index];
    }

    Connections {
        target: rootClockEventIndicators.events

        function onEventChangeNotified(eventId) {
            rootClockEventIndicators.notifyChanged(eventId);
        }
    }

    Row {
        id: indicatorRow

        anchors.centerIn: parent
        spacing: rootClockEventIndicators.theme.modules.bar.clock.eventIndicatorSpacing

        Repeater {
            id: pulseRepeater

            model: rootClockEventIndicators.visibleEventItems

            delegate: Rectangle {
                id: eventIndicator

                required property var modelData

                readonly property bool personalEvent: rootClockEventIndicators.events.isPersonalEvent(modelData)
                readonly property color baseColor: personalEvent
                    ? rootClockEventIndicators.theme.warningColor
                    : rootClockEventIndicators.theme.modules.bar.accentColor
                property bool pulseColorActive: false
                property color pulseColor: baseColor

                width: personalEvent
                    ? rootClockEventIndicators.theme.modules.bar.clock.personalEventIndicatorSize
                    : rootClockEventIndicators.theme.modules.bar.clock.eventIndicatorSize
                height: width
                radius: personalEvent
                    ? rootClockEventIndicators.theme.modules.bar.clock.personalEventIndicatorRadius
                    : rootClockEventIndicators.theme.modules.bar.clock.eventIndicatorRadius
                color: pulseColorActive ? pulseColor : baseColor

                function pulse() {
                    pulseAnimation.restart();
                }

                SequentialAnimation {
                    id: pulseAnimation

                    ScriptAction {
                        script: {
                            eventIndicator.pulseColorActive = true;
                            eventIndicator.pulseColor = rootClockEventIndicators.pulseColorAt(0, eventIndicator.baseColor);
                        }
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: eventIndicator
                            property: "scale"
                            from: 1
                            to: rootClockEventIndicators.theme.modules.bar.clock.changePulseScale
                            duration: rootClockEventIndicators.theme.modules.bar.clock.changePulseDuration
                            easing.type: Easing.OutCubic
                        }

                        ColorAnimation {
                            target: eventIndicator
                            property: "pulseColor"
                            from: rootClockEventIndicators.pulseColorAt(0, eventIndicator.baseColor)
                            to: rootClockEventIndicators.pulseColorAt(1, eventIndicator.baseColor)
                            duration: rootClockEventIndicators.theme.modules.bar.clock.changePulseDuration
                            easing.type: Easing.InOutCubic
                        }
                    }

                    ColorAnimation {
                        target: eventIndicator
                        property: "pulseColor"
                        from: rootClockEventIndicators.pulseColorAt(1, eventIndicator.baseColor)
                        to: rootClockEventIndicators.pulseColorAt(2, eventIndicator.baseColor)
                        duration: rootClockEventIndicators.theme.modules.bar.clock.changePulseDuration
                        easing.type: Easing.InOutCubic
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: eventIndicator
                            property: "scale"
                            from: rootClockEventIndicators.theme.modules.bar.clock.changePulseScale
                            to: 1
                            duration: rootClockEventIndicators.theme.modules.bar.clock.changePulseDuration
                            easing.type: Easing.InOutCubic
                        }

                        ColorAnimation {
                            target: eventIndicator
                            property: "pulseColor"
                            from: rootClockEventIndicators.pulseColorAt(2, eventIndicator.baseColor)
                            to: rootClockEventIndicators.pulseColorAt(3, eventIndicator.baseColor)
                            duration: rootClockEventIndicators.theme.modules.bar.clock.changePulseDuration
                            easing.type: Easing.InOutCubic
                        }
                    }

                    ScriptAction {
                        script: {
                            eventIndicator.pulseColorActive = false;
                            eventIndicator.pulseColor = eventIndicator.baseColor;
                        }
                    }

                    ScriptAction {
                        script: rootClockEventIndicators.runNextPulse()
                    }
                }
            }
        }
    }
}

import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootPotatoFastButton

    required property QtObject service

    readonly property color statusColor: statusColorForClass(service.className)
    readonly property string displayTime: service.remainingText.length > 0 ? service.remainingText : service.timeText

    implicitWidth: expandedPill ? theme.modules.bar.potatoFast.width : theme.modules.bar.pill.horizontalPadding
    tooltipTitle: "Potato Fast"
    tooltipContent: service.tooltipContent
    tooltipStyle: service.className === "done" || service.className === "reached-open" ? "normal" : "warning"
    transformOrigin: Item.Center

    function pulse() {
        pulseAnimation.restart();
    }

    function statusColorForClass(className) {
        if (className === "active")
            return theme.modules.bar.potatoFast.activeColor;

        if (className === "done" || className === "reached-open")
            return theme.modules.bar.potatoFast.doneColor;

        if (className === "short" || className === "error")
            return theme.modules.bar.potatoFast.errorColor;

        return theme.modules.bar.potatoFast.idleColor;
    }

    Connections {
        target: rootPotatoFastButton.service

        function onPulseRequested() {
            rootPotatoFastButton.pulse();
        }
    }

    Row {
        id: potatoFastContent

        spacing: rootPotatoFastButton.theme.modules.bar.potatoFast.contentSpacing

        Item {
            id: potatoFastIconWrapper

            width: potatoFastIcon.implicitWidth
            height: potatoFastIcon.implicitHeight
            transformOrigin: Item.Center

            Text {
                id: potatoFastIcon

                text: ""
                color: rootPotatoFastButton.statusColor
                font.family: rootPotatoFastButton.theme.iconFontFamily
                font.pixelSize: rootPotatoFastButton.theme.modules.bar.potatoFast.iconPixelSize
            }
        }

        Column {
            id: potatoFastStatus

            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                id: potatoFastLabel

                width: rootPotatoFastButton.theme.modules.bar.potatoFast.labelWidth
                text: rootPotatoFastButton.displayTime.length > 0 ? rootPotatoFastButton.displayTime : rootPotatoFastButton.service.state
                color: rootPotatoFastButton.statusColor
                elide: Text.ElideRight
                font.pixelSize: rootPotatoFastButton.theme.modules.bar.potatoFast.labelPixelSize
                font.weight: Font.DemiBold
            }

            Rectangle {
                id: potatoFastTrack

                width: rootPotatoFastButton.theme.modules.bar.potatoFast.progressWidth
                height: rootPotatoFastButton.theme.modules.bar.potatoFast.progressHeight
                radius: rootPotatoFastButton.theme.modules.bar.potatoFast.progressRadius
                color: rootPotatoFastButton.theme.modules.bar.potatoFast.trackColor
                clip: true
                opacity: rootPotatoFastButton.service.success ? 1 : rootPotatoFastButton.theme.modules.bar.potatoFast.inactiveOpacity

                Rectangle {
                    id: potatoFastFill

                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                    }
                    width: rootPotatoFastButton.service.percentage <= 0 ? 0 : Math.max(rootPotatoFastButton.theme.modules.bar.potatoFast.progressHeight, parent.width * rootPotatoFastButton.service.percentage / 100)
                    radius: parent.radius
                    color: rootPotatoFastButton.statusColor

                    Behavior on width {
                        NumberAnimation {
                            duration: rootPotatoFastButton.theme.animationFastDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: pulseAnimation

        NumberAnimation {
            target: rootPotatoFastButton
            property: "scale"
            from: 1
            to: 1.08
            duration: 140
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: rootPotatoFastButton
            property: "scale"
            from: 1.08
            to: 1
            duration: 180
            easing.type: Easing.InOutCubic
        }
    }
}

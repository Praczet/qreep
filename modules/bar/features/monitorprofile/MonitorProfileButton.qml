import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootMonitorProfileButton

    required property QtObject service
    readonly property color statusColor: theme.modules.bar.primaryTextColor

    tooltipTitle: "Monitor Profile"
    tooltipContent: service.tooltipContent
    tooltipStyle: "warning"
    function pulse() {
        pulseAnimation.restart();
    }

    Connections {
        target: rootMonitorProfileButton.service

        function onPulseRequested() {
            rootMonitorProfileButton.pulse();
        }
    }

    Row {
        id: monitorProfileContent

        spacing: rootMonitorProfileButton.theme.modules.bar.monitorProfile.buttonContentSpacing

        Item {
            id: monitorProfileIconWrapper

            width: monitorProfileIcon.implicitWidth
            height: monitorProfileIcon.implicitHeight
            transformOrigin: Item.Center

            Text {
                id: monitorProfileIcon

                text: rootMonitorProfileButton.service.connectedMonitorsText || "󰍹"
                color: rootMonitorProfileButton.statusColor
                font.family: rootMonitorProfileButton.theme.iconFontFamily
                font.pixelSize: rootMonitorProfileButton.theme.modules.bar.monitorProfile.buttonIconPixelSize
            }
        }
    }

    SequentialAnimation {
        id: pulseAnimation

        ParallelAnimation {
            NumberAnimation {
                target: monitorProfileIconWrapper
                property: "scale"
                from: 1
                to: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseScale
                duration: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseOutDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: monitorProfileIconWrapper
                from: 0
                to: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseRotation
                duration: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseOutDuration
                direction: RotationAnimation.Clockwise
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: monitorProfileIconWrapper
                property: "scale"
                from: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseScale
                to: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseSettleScale
                duration: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }

            RotationAnimation {
                target: monitorProfileIconWrapper
                from: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseRotation
                to: -rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseRotationSettle
                duration: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: monitorProfileIconWrapper
                property: "scale"
                from: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseSettleScale
                to: 1
                duration: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseInDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: monitorProfileIconWrapper
                from: -rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseRotationSettle
                to: 0
                duration: rootMonitorProfileButton.theme.modules.bar.monitorProfile.pulseInDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}

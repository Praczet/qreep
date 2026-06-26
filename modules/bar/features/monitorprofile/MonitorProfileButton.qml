import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootMonitorProfileButton

    required property QtObject service
    readonly property color statusColor: theme.primaryText

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

        spacing: rootMonitorProfileButton.theme.monitorProfile.buttonContentSpacing

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
                font.pixelSize: rootMonitorProfileButton.theme.monitorProfile.buttonIconPixelSize
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
                to: rootMonitorProfileButton.theme.monitorProfile.pulseScale
                duration: rootMonitorProfileButton.theme.monitorProfile.pulseOutDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: monitorProfileIconWrapper
                from: 0
                to: rootMonitorProfileButton.theme.monitorProfile.pulseRotation
                duration: rootMonitorProfileButton.theme.monitorProfile.pulseOutDuration
                direction: RotationAnimation.Clockwise
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: monitorProfileIconWrapper
                property: "scale"
                from: rootMonitorProfileButton.theme.monitorProfile.pulseScale
                to: rootMonitorProfileButton.theme.monitorProfile.pulseSettleScale
                duration: rootMonitorProfileButton.theme.monitorProfile.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }

            RotationAnimation {
                target: monitorProfileIconWrapper
                from: rootMonitorProfileButton.theme.monitorProfile.pulseRotation
                to: -rootMonitorProfileButton.theme.monitorProfile.pulseRotationSettle
                duration: rootMonitorProfileButton.theme.monitorProfile.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: monitorProfileIconWrapper
                property: "scale"
                from: rootMonitorProfileButton.theme.monitorProfile.pulseSettleScale
                to: 1
                duration: rootMonitorProfileButton.theme.monitorProfile.pulseInDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: monitorProfileIconWrapper
                from: -rootMonitorProfileButton.theme.monitorProfile.pulseRotationSettle
                to: 0
                duration: rootMonitorProfileButton.theme.monitorProfile.pulseInDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}

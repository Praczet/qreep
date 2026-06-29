import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootUpcheckerButton

    required property QtObject service
    readonly property bool restartOnly: service.updates.length === 0 && service.restartNeeded
    readonly property color statusColor: restartOnly ? theme.modules.bar.borg.warningColor : theme.modules.bar.primaryTextColor

    tooltipTitle: "Upchecker"
    tooltipContent: restartOnly ? service.restartSummary : service.updates.length + " package updates available"
    tooltipStyle: "warning"
    function pulse() {
        pulseAnimation.restart();
    }

    Connections {
        target: rootUpcheckerButton.service

        function onPulseRequested() {
            rootUpcheckerButton.pulse();
        }
    }

    Row {
        id: upcheckerContent

        spacing: rootUpcheckerButton.theme.modules.bar.upchecker.buttonContentSpacing

        Item {
            id: upcheckerIconWrapper

            width: upcheckerIcon.implicitWidth
            height: upcheckerIcon.implicitHeight
            transformOrigin: Item.Center

            Text {
                id: upcheckerIcon

                text: "󰮯"
                color: rootUpcheckerButton.statusColor
                font.family: rootUpcheckerButton.theme.iconFontFamily
                font.pixelSize: rootUpcheckerButton.theme.modules.bar.upchecker.buttonIconPixelSize
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: rootUpcheckerButton.service.updates.length
            color: rootUpcheckerButton.statusColor
            font.pixelSize: rootUpcheckerButton.theme.modules.bar.upchecker.buttonTextPixelSize
            font.weight: Font.DemiBold
        }
    }

    SequentialAnimation {
        id: pulseAnimation

        ParallelAnimation {
            NumberAnimation {
                target: upcheckerIconWrapper
                property: "scale"
                from: 1
                to: rootUpcheckerButton.theme.modules.bar.upchecker.pulseScale
                duration: rootUpcheckerButton.theme.modules.bar.upchecker.pulseOutDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: upcheckerIconWrapper
                from: 0
                to: rootUpcheckerButton.theme.modules.bar.upchecker.pulseRotation
                duration: rootUpcheckerButton.theme.modules.bar.upchecker.pulseOutDuration
                direction: RotationAnimation.Clockwise
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: upcheckerIconWrapper
                property: "scale"
                from: rootUpcheckerButton.theme.modules.bar.upchecker.pulseScale
                to: rootUpcheckerButton.theme.modules.bar.upchecker.pulseSettleScale
                duration: rootUpcheckerButton.theme.modules.bar.upchecker.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }

            RotationAnimation {
                target: upcheckerIconWrapper
                from: rootUpcheckerButton.theme.modules.bar.upchecker.pulseRotation
                to: -rootUpcheckerButton.theme.modules.bar.upchecker.pulseRotationSettle
                duration: rootUpcheckerButton.theme.modules.bar.upchecker.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: upcheckerIconWrapper
                property: "scale"
                from: rootUpcheckerButton.theme.modules.bar.upchecker.pulseSettleScale
                to: 1
                duration: rootUpcheckerButton.theme.modules.bar.upchecker.pulseInDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: upcheckerIconWrapper
                from: -rootUpcheckerButton.theme.modules.bar.upchecker.pulseRotationSettle
                to: 0
                duration: rootUpcheckerButton.theme.modules.bar.upchecker.pulseInDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}

import QtQuick
import "../../components" as Components

Components.QreepModule {
    id: rootUpcheckerButton

    required property QtObject service
    readonly property bool restartOnly: service.updates.length === 0 && service.restartNeeded
    readonly property color statusColor: restartOnly ? theme.borg.warningColor : theme.primaryText

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

        spacing: rootUpcheckerButton.theme.upchecker.buttonContentSpacing

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
                font.pixelSize: rootUpcheckerButton.theme.upchecker.buttonIconPixelSize
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: rootUpcheckerButton.service.updates.length
            color: rootUpcheckerButton.statusColor
            font.pixelSize: rootUpcheckerButton.theme.upchecker.buttonTextPixelSize
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
                to: rootUpcheckerButton.theme.upchecker.pulseScale
                duration: rootUpcheckerButton.theme.upchecker.pulseOutDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: upcheckerIconWrapper
                from: 0
                to: rootUpcheckerButton.theme.upchecker.pulseRotation
                duration: rootUpcheckerButton.theme.upchecker.pulseOutDuration
                direction: RotationAnimation.Clockwise
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: upcheckerIconWrapper
                property: "scale"
                from: rootUpcheckerButton.theme.upchecker.pulseScale
                to: rootUpcheckerButton.theme.upchecker.pulseSettleScale
                duration: rootUpcheckerButton.theme.upchecker.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }

            RotationAnimation {
                target: upcheckerIconWrapper
                from: rootUpcheckerButton.theme.upchecker.pulseRotation
                to: -rootUpcheckerButton.theme.upchecker.pulseRotationSettle
                duration: rootUpcheckerButton.theme.upchecker.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: upcheckerIconWrapper
                property: "scale"
                from: rootUpcheckerButton.theme.upchecker.pulseSettleScale
                to: 1
                duration: rootUpcheckerButton.theme.upchecker.pulseInDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: upcheckerIconWrapper
                from: -rootUpcheckerButton.theme.upchecker.pulseRotationSettle
                to: 0
                duration: rootUpcheckerButton.theme.upchecker.pulseInDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}

import QtQuick
import "../../../components" as Components

Components.QreepModule {
    id: rootBorg

    required property QtObject service

    tooltipTitle: "Borg"
    tooltipContent: service.status
    tooltipStyle: service.className === "ok" ? "normal" : "warning"

    transformOrigin: Item.Center

    function pulse() {
        pulseAnimation.restart();
    }

    Connections {
        target: rootBorg.service

        function onPulseRequested() {
            rootBorg.pulse();
        }
    }

    Item {
        id: borgTextWrapper

        implicitWidth: borgText.implicitWidth
        implicitHeight: borgText.implicitHeight
        transformOrigin: Item.Center

        Text {
            id: borgText

            text: rootBorg.service.text
            color: rootBorg.theme.borgClassColor(rootBorg.service.className)
            font.family: rootBorg.theme.iconFontFamily
            font.pixelSize: rootBorg.theme.borg.iconPixelSize
        }
    }

    SequentialAnimation {
        id: pulseAnimation

        ParallelAnimation {
            NumberAnimation {
                target: rootBorg
                property: "scale"
                from: 1
                to: rootBorg.theme.borg.pulseScale
                duration: rootBorg.theme.borg.pulseOutDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: borgTextWrapper
                from: 0
                to: rootBorg.theme.borg.pulseRotation
                duration: rootBorg.theme.borg.pulseOutDuration
                direction: RotationAnimation.Clockwise
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: rootBorg
                property: "scale"
                from: rootBorg.theme.borg.pulseScale
                to: rootBorg.theme.borg.pulseSettleScale
                duration: rootBorg.theme.borg.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }

            RotationAnimation {
                target: borgTextWrapper
                from: rootBorg.theme.borg.pulseRotation
                to: -rootBorg.theme.borg.pulseRotationSettle
                duration: rootBorg.theme.borg.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: rootBorg
                property: "scale"
                from: rootBorg.theme.borg.pulseSettleScale
                to: 1
                duration: rootBorg.theme.borg.pulseInDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: borgTextWrapper
                from: -rootBorg.theme.borg.pulseRotationSettle
                to: 0
                duration: rootBorg.theme.borg.pulseInDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}

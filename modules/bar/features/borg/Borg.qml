import QtQuick
import "../../../../components" as Components

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
            color: rootBorg.theme.modules.bar.borg.classColor(rootBorg.service.className)
            font.family: rootBorg.theme.iconFontFamily
            font.pixelSize: rootBorg.theme.modules.bar.borg.iconPixelSize
        }
    }

    SequentialAnimation {
        id: pulseAnimation

        ParallelAnimation {
            NumberAnimation {
                target: rootBorg
                property: "scale"
                from: 1
                to: rootBorg.theme.modules.bar.borg.pulseScale
                duration: rootBorg.theme.modules.bar.borg.pulseOutDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: borgTextWrapper
                from: 0
                to: rootBorg.theme.modules.bar.borg.pulseRotation
                duration: rootBorg.theme.modules.bar.borg.pulseOutDuration
                direction: RotationAnimation.Clockwise
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: rootBorg
                property: "scale"
                from: rootBorg.theme.modules.bar.borg.pulseScale
                to: rootBorg.theme.modules.bar.borg.pulseSettleScale
                duration: rootBorg.theme.modules.bar.borg.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }

            RotationAnimation {
                target: borgTextWrapper
                from: rootBorg.theme.modules.bar.borg.pulseRotation
                to: -rootBorg.theme.modules.bar.borg.pulseRotationSettle
                duration: rootBorg.theme.modules.bar.borg.pulseSettleDuration
                easing.type: Easing.InOutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: rootBorg
                property: "scale"
                from: rootBorg.theme.modules.bar.borg.pulseSettleScale
                to: 1
                duration: rootBorg.theme.modules.bar.borg.pulseInDuration
                easing.type: Easing.OutCubic
            }

            RotationAnimation {
                target: borgTextWrapper
                from: -rootBorg.theme.modules.bar.borg.pulseRotationSettle
                to: 0
                duration: rootBorg.theme.modules.bar.borg.pulseInDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}

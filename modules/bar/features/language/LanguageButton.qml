import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootLanguageButton

    required property QtObject service

    tooltipTitle: rootLanguageButton.service.tooltipTitle
    tooltipContent: rootLanguageButton.service.tooltipContent
    tooltipStyle: rootLanguageButton.service.available ? "normal" : "warning"

    readonly property color statusColor: rootLanguageButton.service.available ? rootLanguageButton.theme.modules.bar.language.primaryTextColor : rootLanguageButton.theme.modules.bar.language.unavailableColor

    function pulse() {
        pulseAnimation.restart();
    }

    Connections {
        target: rootLanguageButton.service

        function onPulseRequested() {
            rootLanguageButton.pulse();
        }
    }

    Row {
        id: languageContent

        spacing: rootLanguageButton.theme.modules.bar.language.buttonContentSpacing

        Item {
            id: languageIconWrapper

            width: rootLanguageButton.theme.modules.bar.language.buttonIconPixelSize
            height: rootLanguageButton.theme.modules.bar.language.buttonIconPixelSize
            transformOrigin: Item.Center

            Text {
                id: languageIcon

                anchors.centerIn: parent
                text: "󰌌"
                color: rootLanguageButton.statusColor
                font.family: rootLanguageButton.theme.iconFontFamily
                font.pixelSize: rootLanguageButton.theme.modules.bar.language.buttonIconPixelSize
                lineHeight: 1
            }
        }

        Text {
            id: languageLabel

            anchors.verticalCenter: parent.verticalCenter
            text: rootLanguageButton.service.displayText
            color: rootLanguageButton.statusColor
            font.pixelSize: rootLanguageButton.theme.modules.bar.language.buttonTextPixelSize
            font.bold: true
        }
    }

    SequentialAnimation {
        id: pulseAnimation

        NumberAnimation {
            target: languageContent
            property: "scale"
            from: 1
            to: rootLanguageButton.theme.modules.bar.language.pulseScale
            duration: rootLanguageButton.theme.modules.bar.language.pulseOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: languageContent
            property: "scale"
            from: rootLanguageButton.theme.modules.bar.language.pulseScale
            to: 1
            duration: rootLanguageButton.theme.modules.bar.language.pulseInDuration
            easing.type: Easing.OutCubic
        }
    }
}

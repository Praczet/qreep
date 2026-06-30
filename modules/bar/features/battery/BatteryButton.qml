import QtQuick
import Quickshell.Widgets
import "../../../../components" as Components

Components.QreepModule {
    id: rootBatteryButton

    required property QtObject service

    tooltipTitle: "Battery"
    tooltipContent: service.tooltipContent
    tooltipStyle: "warning"
    readonly property int iconSize: theme.modules.bar.battery.buttonIconPixelSize

    readonly property color statusColor: getColorForStatus()

    function getColorForStatus() {
        if (!service.available) {
            return theme.modules.bar.battery.unavailableColor;
        } else if (service.isCritical) {
            return theme.modules.bar.battery.criticalColor;
        } else if (service.isLow) {
            return theme.modules.bar.battery.lowColor;
        } else {
            return theme.modules.bar.primaryTextColor;
        }
    }

    Connections {
        target: rootBatteryButton.service
    }

    Row {
        id: batteryContent
        spacing: rootBatteryButton.theme.modules.bar.battery.buttonContentSpacing

        Item {
            id: batteryIconWrapper

            width: rootBatteryButton.iconSize
            height: rootBatteryButton.iconSize
            transformOrigin: Item.Center

            IconImage {
                id: batteryIcon
                anchors.fill: parent
                source: rootBatteryButton.service.icon
            }
        }
        Text {
            id: batteryPercent
            color: rootBatteryButton.statusColor
            visible: rootBatteryButton.service.isCritical

            anchors.verticalCenter: parent.verticalCenter

            text: rootBatteryButton.service.strPercent
        }
    }
}

import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../../../components" as Components

Components.QreepModule {
    id: rootVolumeButton

    required property QtObject service

    signal volumeChangedByScroll

    tooltipTitle: "Volume"
    tooltipContent: service.sinkTooltip
    tooltipStyle: service.sinkMuted ? "warning" : "normal"

    Row {
        id: volumeContent

        spacing: rootVolumeButton.theme.modules.bar.volume.buttonContentSpacing

        Item {
            id: volumeIconWrapper

            width: rootVolumeButton.theme.modules.bar.volume.buttonIconPixelSize
            height: rootVolumeButton.theme.modules.bar.volume.buttonIconPixelSize
            transformOrigin: Item.Center

            IconImage {
                id: volumeIcon

                anchors.fill: parent
                source: Quickshell.iconPath(rootVolumeButton.service.sinkIcon, rootVolumeButton.service.sinkIcon)
            }
        }
    }

    overlay: MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                rootVolumeButton.service.increaseVolume();
                rootVolumeButton.volumeChangedByScroll();
            } else if (wheel.angleDelta.y < 0) {
                rootVolumeButton.service.decreaseVolume();
                rootVolumeButton.volumeChangedByScroll();
            }

            wheel.accepted = true;
        }
    }
}

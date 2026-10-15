import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootQreeperButton

    required property QtObject service
    readonly property color stateColor: service.displayState === "valid" ? theme.modules.qreeper.successColor : service.displayState === "stale" ? theme.modules.qreeper.noteColor : service.displayState === "error" ? theme.modules.qreeper.errorColor : theme.modules.qreeper.secondaryTextColor

    tooltipTitle: "Qreeper"
    tooltipContent: service.statusLabel + (service.currentRoom ? "\n" + service.locationLabel : "")
    tooltipStyle: service.displayState === "error" || service.displayState === "stale" ? "warning" : "normal"

    Item {
        width: 26
        height: 26

        Canvas {
            id: compass
            anchors.fill: parent
            onPaint: {
                const context = getContext("2d");
                context.reset();
                context.clearRect(0, 0, width, height);
                context.strokeStyle = rootQreeperButton.theme.modules.qreeper.primaryTextColor;
                context.fillStyle = rootQreeperButton.theme.modules.qreeper.primaryTextColor;
                context.lineWidth = 1.8;
                context.beginPath();
                context.arc(width / 2, height / 2, 8.5, 0, Math.PI * 2);
                context.stroke();
                context.beginPath();
                context.moveTo(width / 2 + 2, height / 2 - 7);
                context.lineTo(width / 2 - 1, height / 2 + 2);
                context.lineTo(width / 2 - 5, height / 2 + 5);
                context.closePath();
                context.fill();
            }
        }

        Rectangle {
            width: 7
            height: 7
            radius: 4
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: rootQreeperButton.stateColor
            border.width: 1
            border.color: rootQreeperButton.theme.modules.qreeper.panelColor
        }
    }
}

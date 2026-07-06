import QtQuick

Rectangle {
    id: rootAegisCard

    required property QtObject theme
    property bool entered: false
    property string from: "center"
    property real baseX: x
    property real baseY: y
    property alias contentItem: contentHost
    default property alias contentData: contentHost.data

    x: entered ? baseX : baseX + offsetX(from)
    y: entered ? baseY : baseY + offsetY(from)
    radius: theme.modules.aegis.cardRadius
    color: theme.modules.aegis.cardColor
    border.width: 1
    border.color: theme.modules.aegis.borderColor
    opacity: entered ? 1 : 0
    clip: true

    Item {
        id: contentHost

        anchors {
            fill: parent
            margins: rootAegisCard.theme.modules.aegis.cardPadding
        }
    }

    function offsetX(value) {
        switch (String(value || "center")) {
        case "left":
        case "top-left":
        case "bottom-left":
            return -theme.modules.aegis.enterOffset;
        case "right":
        case "top-right":
        case "bottom-right":
            return theme.modules.aegis.enterOffset;
        default:
            return 0;
        }
    }

    function offsetY(value) {
        switch (String(value || "center")) {
        case "top":
        case "top-left":
        case "top-right":
            return -theme.modules.aegis.enterOffset;
        case "bottom":
        case "bottom-left":
        case "bottom-right":
            return theme.modules.aegis.enterOffset;
        default:
            return 0;
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: rootAegisCard.theme.modules.aegis.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: rootAegisCard.theme.modules.aegis.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: rootAegisCard.theme.modules.aegis.animationDuration
            easing.type: Easing.OutCubic
        }
    }
}

import QtQuick

Rectangle {
    id: rootDashboardCard

    required property QtObject theme
    required property var block

    property bool entered: false
    readonly property real baseX: Number(block.x || 0)
    readonly property real baseY: Number(block.y || 0)
    readonly property real enterOffset: theme.dashboard.enterOffset

    x: entered ? baseX : baseX + offsetX(block.from)
    y: entered ? baseY : baseY + offsetY(block.from)
    width: Number(block.width || theme.dashboard.defaultCardWidth)
    height: Number(block.height || theme.dashboard.defaultCardHeight)
    radius: theme.dashboard.cardRadius
    opacity: entered ? 1 : 0
    color: block.showBackground === false ? "transparent" : theme.dashboard.backgroundColor
    border.width: block.showBorder === false ? 0 : theme.dashboard.cardBorderWidth
    border.color: theme.dashboard.borderColor

    function offsetX(from) {
        switch (String(from || "center")) {
        case "left":
        case "top-left":
        case "bottom-left":
            return -enterOffset;
        case "right":
        case "top-right":
        case "bottom-right":
            return enterOffset;
        default:
            return 0;
        }
    }

    function offsetY(from) {
        switch (String(from || "center")) {
        case "top":
        case "top-left":
        case "top-right":
            return -enterOffset;
        case "bottom":
        case "bottom-left":
        case "bottom-right":
            return enterOffset;
        default:
            return 0;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => mouse.accepted = true
    }

    Column {
        anchors {
            fill: parent
            margins: rootDashboardCard.theme.dashboard.cardPadding
        }
        spacing: rootDashboardCard.theme.dashboard.contentSpacing

        Text {
            visible: rootDashboardCard.block.showTitle !== false
            width: parent.width
            text: String(rootDashboardCard.block.title || rootDashboardCard.block.id || "Dashboard block")
            color: rootDashboardCard.theme.calendarHeaderText
            font.pixelSize: rootDashboardCard.theme.dashboard.titlePixelSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Rectangle {
            visible: rootDashboardCard.block.showTitle !== false
            width: parent.width
            height: rootDashboardCard.theme.dashboard.dividerWidth
            color: rootDashboardCard.theme.dashboard.borderColor
            opacity: 0.7
        }

        Text {
            width: parent.width
            text: String(rootDashboardCard.block.text || rootDashboardCard.block.type || "fake")
            color: rootDashboardCard.theme.calendarDayText
            font.pixelSize: rootDashboardCard.theme.dashboard.bodyPixelSize
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            text: "preset: " + String(rootDashboardCard.block.preset || "default") + " | from: " + String(rootDashboardCard.block.from || "center")
            color: rootDashboardCard.theme.secondaryText
            font.pixelSize: rootDashboardCard.theme.dashboard.metaPixelSize
            wrapMode: Text.Wrap
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: rootDashboardCard.theme.dashboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: rootDashboardCard.theme.dashboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: rootDashboardCard.theme.dashboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }
}

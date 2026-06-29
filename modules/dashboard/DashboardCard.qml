import QtQuick
import "./features/weather" as WeatherFeature
import "./features/clock" as ClockFeature

Rectangle {
    id: rootDashboardCard

    required property QtObject theme
    required property var block

    property bool entered: false
    readonly property real cardWidth: Number(block.width || theme.modules.dashboard.defaultCardWidth)
    readonly property real cardHeight: Number(block.height || theme.modules.dashboard.defaultCardHeight)
    readonly property real baseX: block.placementMode === "absolute" ? Number(block.x || 0) : anchorBaseX(block.anchorPoint) + Number(block.dx || 0)
    readonly property real baseY: block.placementMode === "absolute" ? Number(block.y || 0) : anchorBaseY(block.anchorPoint) + Number(block.dy || 0)
    readonly property real enterOffset: theme.modules.dashboard.enterOffset

    x: entered ? baseX : baseX + offsetX(block.from)
    y: entered ? baseY : baseY + offsetY(block.from)
    width: cardWidth
    height: cardHeight
    radius: theme.modules.dashboard.cardRadius
    opacity: entered ? 1 : 0
    color: block.showBackground === false ? "transparent" : theme.modules.dashboard.backgroundColor
    border.width: block.showBorder === false ? 0 : theme.modules.dashboard.cardBorderWidth
    border.color: theme.modules.dashboard.borderColor

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

    function anchorBaseX(anchorPoint) {
        switch (String(anchorPoint || "top-left")) {
        case "top-center":
        case "middle-center":
        case "bottom-center":
            return (parent.width - cardWidth) / 2;
        case "top-right":
        case "middle-right":
        case "bottom-right":
            return parent.width - cardWidth;
        default:
            return 0;
        }
    }

    function anchorBaseY(anchorPoint) {
        switch (String(anchorPoint || "top-left")) {
        case "middle-left":
        case "middle-center":
        case "middle-right":
            return (parent.height - cardHeight) / 2;
        case "bottom-left":
        case "bottom-center":
        case "bottom-right":
            return parent.height - cardHeight;
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
            margins: rootDashboardCard.theme.modules.dashboard.cardPadding
        }
        spacing: rootDashboardCard.theme.modules.dashboard.contentSpacing

        Text {
            visible: rootDashboardCard.block.showTitle !== false
            width: parent.width
            text: String(rootDashboardCard.block.title || rootDashboardCard.block.id || "Dashboard block")
            color: rootDashboardCard.theme.calendarHeaderText
            font.pixelSize: rootDashboardCard.theme.modules.dashboard.titlePixelSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Rectangle {
            visible: rootDashboardCard.block.showTitle !== false
            width: parent.width
            height: rootDashboardCard.theme.modules.dashboard.dividerWidth
            color: rootDashboardCard.theme.modules.dashboard.borderColor
            opacity: 0.7
        }

        Text {
            visible: rootDashboardCard.block.type !== "weather" && rootDashboardCard.block.type !== "clock"
            width: parent.width
            text: String(rootDashboardCard.block.text || rootDashboardCard.block.type || "fake")
            color: rootDashboardCard.theme.calendarDayText
            font.pixelSize: rootDashboardCard.theme.modules.dashboard.bodyPixelSize
            wrapMode: Text.Wrap
        }

        WeatherFeature.WeatherBlock {
            visible: rootDashboardCard.block.type === "weather"
            width: parent.width
            theme: rootDashboardCard.theme
            config: rootDashboardCard.block.config || ({})
        }

        ClockFeature.ClockBlock {
            visible: rootDashboardCard.block.type === "clock"
            width: parent.width
            height: Math.max(1, parent.height - y)
            theme: rootDashboardCard.theme
            config: rootDashboardCard.block.config || ({})
        }

        Text {
            visible: rootDashboardCard.block.type === "fake"
            width: parent.width
            text: "preset: " + String(rootDashboardCard.block.preset || "default") + " | anchor: " + String(rootDashboardCard.block.anchorPoint || "absolute") + " | from: " + String(rootDashboardCard.block.from || "center")
            color: rootDashboardCard.theme.secondaryText
            font.pixelSize: rootDashboardCard.theme.modules.dashboard.metaPixelSize
            wrapMode: Text.Wrap
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: rootDashboardCard.theme.modules.dashboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: rootDashboardCard.theme.modules.dashboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: rootDashboardCard.theme.modules.dashboard.animationDuration
            easing.type: Easing.OutCubic
        }
    }
}

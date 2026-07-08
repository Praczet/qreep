import QtQuick
import "./features/weather" as WeatherFeature
import "./features/clock" as ClockFeature
import "./features/image" as ImageFeature
import "./features/wotd" as WotdFeature
import "./features/aegis" as AegisFeature
import "./features/borg" as BorgFeature

Rectangle {
    id: rootDashboardCard

    required property QtObject theme
    required property var block
    property QtObject aegisService

    property bool entered: false
    readonly property real cardWidth: Number(block.width || theme.modules.dashboard.defaultCardWidth)
    readonly property real cardHeight: Number(block.height || theme.modules.dashboard.defaultCardHeight)
    readonly property real baseX: block.placementMode === "absolute" ? Number(block.x || 0) : anchorBaseX(block.anchorPoint) + Number(block.dx || 0)
    readonly property real baseY: block.placementMode === "absolute" ? Number(block.y || 0) : anchorBaseY(block.anchorPoint) + Number(block.dy || 0)
    readonly property real enterOffset: theme.modules.dashboard.enterOffset
    readonly property color cardTextColor: colorValue(block.color, theme.modules.dashboard.primaryTextColor)
    readonly property color cardBackgroundColor: colorValue(block.backgroundColor, theme.modules.dashboard.backgroundColor)
    readonly property color cardBorderColor: colorValue(block.borderColor, theme.modules.dashboard.borderColor)
    readonly property real cardRadius: Number.isFinite(Number(block.radius)) ? Number(block.radius) : theme.modules.dashboard.cardRadius
    readonly property real cardBorderWidth: Number.isFinite(Number(block.borderWidth)) ? Number(block.borderWidth) : theme.modules.dashboard.cardBorderWidth
    readonly property real cardPadding: Number.isFinite(Number(block.padding)) ? Number(block.padding) : theme.modules.dashboard.cardPadding

    x: entered ? baseX : baseX + offsetX(block.from)
    y: entered ? baseY : baseY + offsetY(block.from)
    width: cardWidth
    height: cardHeight
    radius: cardRadius
    opacity: entered ? 1 : 0
    color: block.showBackground === false ? "transparent" : cardBackgroundColor
    border.width: block.showBorder === false ? 0 : cardBorderWidth
    border.color: cardBorderColor

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

    function colorValue(value, fallback) {
        if (typeof value !== "string" || value.length === 0)
            return fallback;

        return value.indexOf("{{") === 0 ? theme.colorToken(value, fallback) : value;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => mouse.accepted = true
    }

    ImageFeature.ImageBlock {
        visible: rootDashboardCard.block.type === "image"
        anchors.fill: parent
        theme: rootDashboardCard.theme
        config: rootDashboardCard.block.config || ({})
    }

    Column {
        anchors {
            fill: parent
            margins: rootDashboardCard.cardPadding
        }
        spacing: rootDashboardCard.theme.modules.dashboard.contentSpacing

        Text {
            visible: rootDashboardCard.block.showTitle !== false
            width: parent.width
            text: String(rootDashboardCard.block.title || rootDashboardCard.block.id || "Dashboard block")
            color: rootDashboardCard.cardTextColor
            font.pixelSize: rootDashboardCard.theme.modules.dashboard.titlePixelSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Rectangle {
            visible: rootDashboardCard.block.showTitle !== false
            width: parent.width
            height: Math.max(1, Math.min(rootDashboardCard.cardBorderWidth, rootDashboardCard.theme.modules.dashboard.dividerWidth))
            color: rootDashboardCard.cardBorderColor
            opacity: 0.7
        }

        Text {
            visible: rootDashboardCard.block.type !== "weather" && rootDashboardCard.block.type !== "clock" && rootDashboardCard.block.type !== "digital-clock" && rootDashboardCard.block.type !== "image" && rootDashboardCard.block.type !== "word-of-the-day" && rootDashboardCard.block.type !== "borg" && !rootDashboardCard.isAegisBlock()
            width: parent.width
            text: String(rootDashboardCard.block.text || rootDashboardCard.block.type || "fake")
            color: rootDashboardCard.cardTextColor
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

        ClockFeature.DigitalClockBlock {
            visible: rootDashboardCard.block.type === "digital-clock"
            width: parent.width
            height: Math.max(1, parent.height - y)
            theme: rootDashboardCard.theme
            config: rootDashboardCard.block.config || ({})
        }

        WotdFeature.WordOfTheDayBlock {
            visible: rootDashboardCard.block.type === "word-of-the-day"
            width: parent.width
            height: Math.max(1, parent.height - y)
            theme: rootDashboardCard.theme
            config: rootDashboardCard.block.config || ({})
        }

        BorgFeature.BorgBlock {
            visible: rootDashboardCard.block.type === "borg"
            width: parent.width
            height: Math.max(1, parent.height - y)
            theme: rootDashboardCard.theme
            config: rootDashboardCard.block.config || ({})
        }

        AegisFeature.AegisBlock {
            visible: rootDashboardCard.isAegisBlock()
            width: parent.width
            height: Math.max(1, parent.height - y)
            theme: rootDashboardCard.theme
            service: rootDashboardCard.aegisService
            type: String(rootDashboardCard.block.type || "aegis")
            config: rootDashboardCard.block.config || ({})
        }
    }

    function isAegisBlock() {
        const value = String(block.type || "");
        return value === "aegis"
            || value === "aegis-summary"
            || value === "aegis-cpu-graph"
            || value === "aegis-memory-pie"
            || value === "aegis-disk-pie"
            || value === "aegis-copy-footer";
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

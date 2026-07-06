import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: rootDashboardService

    required property QtObject theme
    property var blocks: defaultBlocks()
    property string error: ""

    readonly property FileView configFile: FileView {
        path: Quickshell.shellDir + "/modules/dashboard/dashboard.json"
        preload: true
        watchChanges: true

        onLoaded: rootDashboardService.loadConfig()
        onTextChanged: rootDashboardService.loadConfig()
        onLoadFailed: error => {
            rootDashboardService.error = "Dashboard config load failed: " + FileViewError.toString(error);
            rootDashboardService.blocks = rootDashboardService.defaultBlocks();
        }
    }

    function reload() {
        configFile.reload();
    }

    function loadConfig() {
        const contents = configFile.text();

        if (contents.length === 0) {
            blocks = defaultBlocks();
            return;
        }

        try {
            const document = JSON.parse(contents);
            applyConfig(document);
        } catch (error) {
            rootDashboardService.error = "Dashboard config JSON error: " + error;
            rootDashboardService.blocks = rootDashboardService.defaultBlocks();
        }
    }

    function applyConfig(document) {
        const rawBlocks = document && Array.isArray(document.blocks) ? document.blocks : [];
        const rawWidgets = document && Array.isArray(document.widgets) ? document.widgets : [];
        const cardStyle = document && typeof document.cardStyle === "object" ? document.cardStyle : ({});
        const sourceBlocks = rawBlocks.length > 0 ? rawBlocks : rawWidgets.map((widget, index) => normalizeLegacyWidget(widget, index));

        if (sourceBlocks.length === 0) {
            blocks = defaultBlocks();
            error = "";
            return;
        }

        blocks = sourceBlocks.map((block, index) => normalizeBlock(block, index, cardStyle));
        error = "";
    }

    function normalizeLegacyWidget(widget, index) {
        const value = widget || ({});
        const col = Math.max(1, Math.floor(numberValue(value.col, 1)));
        const row = Math.max(1, Math.floor(numberValue(value.row, 1)));
        const colSpan = Math.max(1, Math.floor(numberValue(value.colSpan, 1)));
        const rowSpan = Math.max(1, Math.floor(numberValue(value.rowSpan, 1)));
        const cellWidth = 390;
        const cellHeight = 250;
        const gap = 22;
        const left = 72 + (col - 1) * (cellWidth + gap);
        const top = 96 + (row - 1) * (cellHeight + gap);
        const type = stringValue(value.type, "fake");
        const config = value.config || ({});

        return {
            id: stringValue(value.id, "legacy-widget-" + index),
            type,
            title: stringValue(config.title, type),
            text: "",
            preset: "legacy",
            x: left,
            y: top,
            width: colSpan * cellWidth + (colSpan - 1) * gap,
            height: rowSpan * cellHeight + (rowSpan - 1) * gap,
            from: stringValue(value.from, legacyFrom(col, row)),
            showTitle: boolValue(config.showTitle, type !== "clock"),
            showBackground: boolValue(value.showBackground, true),
            showBorder: boolValue(value.showBorder, true),
            expandX: boolValue(value.expandX, false),
            expandY: boolValue(value.expandY, false),
            config
        };
    }

    function legacyFrom(col, row) {
        if (row <= 1 && col <= 1)
            return "top-left";
        if (row <= 1 && col >= 3)
            return "top-right";
        if (col <= 1)
            return "left";
        if (col >= 3)
            return "right";
        return "top";
    }

    function normalizeBlock(block, index, cardStyle) {
        const value = block || ({});
        const style = cardStyle || ({});
        const usesAnchoredPlacement = typeof value.anchorPoint === "string" || value.dx !== undefined || value.dy !== undefined;

        return {
            id: stringValue(value.id, "block-" + index),
            type: stringValue(value.type, "fake"),
            title: stringValue(value.title, "Block " + (index + 1)),
            text: stringValue(value.text, ""),
            preset: stringValue(value.preset, "default"),
            placementMode: usesAnchoredPlacement ? "anchored" : "absolute",
            anchorPoint: stringValue(value.anchorPoint, "top-left"),
            dx: numberValue(value.dx, 0),
            dy: numberValue(value.dy, 0),
            x: numberValue(value.x, theme.modules.dashboard.placementMargin),
            y: numberValue(value.y, theme.modules.dashboard.placementMargin),
            width: numberValue(value.width, theme.modules.dashboard.defaultCardWidth),
            height: numberValue(value.height, theme.modules.dashboard.defaultCardHeight),
            from: stringValue(value.from, "center"),
            showTitle: boolValue(value.showTitle, true),
            showBackground: boolValue(value.showBackground, true),
            showBorder: boolValue(value.showBorder, true),
            color: stringValue(value.color, stringValue(style.color, "")),
            backgroundColor: stringValue(value.backgroundColor, stringValue(style.backgroundColor, "")),
            borderColor: stringValue(value.borderColor, stringValue(style.borderColor, "")),
            radius: numberValue(value.radius, numberValue(style.radius, theme.modules.dashboard.cardRadius)),
            borderWidth: numberValue(value.borderWidth, numberValue(style.borderWidth, theme.modules.dashboard.cardBorderWidth)),
            padding: numberValue(value.padding, numberValue(style.padding, theme.modules.dashboard.cardPadding)),
            config: value.config || ({})
        };
    }

    function defaultBlocks() {
        return [
            {
                id: "clock-large",
                type: "fake",
                title: "Clock",
                text: "Large clock block",
                preset: "large",
                placementMode: "anchored",
                anchorPoint: "top-left",
                dx: 80,
                dy: 110,
                width: 380,
                height: 145,
                from: "left",
                showTitle: false,
                showBackground: true,
                showBorder: true,
                config: ({})
            },
            {
                id: "weather",
                type: "weather",
                title: "Weather",
                text: "Weather preview will live here once it stops needing a weather department.",
                preset: "compact",
                placementMode: "anchored",
                anchorPoint: "top-left",
                dx: 80,
                dy: 285,
                width: 426,
                height: 322,
                from: "bottom-left",
                showTitle: false,
                showBackground: true,
                showBorder: true,
                config: ({
                    apiEnabled: true,
                    location: "Bergem, Luxembourg",
                    latitude: 49.5,
                    longitude: 6.1,
                    timezone: "Europe/Luxembourg",
                    refreshInterval: 1800000,
                    temperature: "37°C",
                    condition: "Overcast",
                    wind: "Wind 9 km/h",
                    icon: "weather-overcast-symbolic",
                    forecast: [
                        { day: "Sat, Jun 27", low: 20, high: 38, icon: "weather-overcast-symbolic" },
                        { day: "Sun, Jun 28", low: 24, high: 33, icon: "weather-clouds-symbolic" },
                        { day: "Mon, Jun 29", low: 19, high: 25, icon: "weather-few-clouds-symbolic" },
                        { day: "Tue, Jun 30", low: 16, high: 26, icon: "weather-showers-symbolic" },
                        { day: "Wed, Jul 01", low: 15, high: 25, icon: "weather-clear-symbolic" },
                        { day: "Thu, Jul 02", low: 16, high: 26, icon: "weather-clear-symbolic" },
                        { day: "Fri, Jul 03", low: 17, high: 24, icon: "weather-showers-symbolic" }
                    ]
                })
            },
            {
                id: "aegis-summary",
                type: "fake",
                title: "Aegis",
                text: "System overview preset placeholder",
                preset: "wide",
                placementMode: "anchored",
                anchorPoint: "top-center",
                dx: -164,
                dy: 110,
                width: 720,
                height: 420,
                from: "top",
                showTitle: true,
                showBackground: true,
                showBorder: true,
                config: ({})
            },
            {
                id: "potato-weight",
                type: "fake",
                title: "POTATO weight",
                text: "Image/chart block placeholder",
                preset: "chart",
                placementMode: "anchored",
                anchorPoint: "top-right",
                dx: -128,
                dy: 110,
                width: 660,
                height: 260,
                from: "right",
                showTitle: true,
                showBackground: true,
                showBorder: true,
                config: ({})
            },
            {
                id: "potato-steps",
                type: "fake",
                title: "POTATO steps",
                text: "Another deliberately placed chart block",
                preset: "chart",
                placementMode: "anchored",
                anchorPoint: "top-right",
                dx: -128,
                dy: 400,
                width: 660,
                height: 260,
                from: "right",
                showTitle: true,
                showBackground: true,
                showBorder: true,
                config: ({})
            }
        ];
    }

    function stringValue(value, fallback) {
        return typeof value === "string" ? value : fallback;
    }

    function numberValue(value, fallback) {
        return Number.isFinite(Number(value)) ? Number(value) : fallback;
    }

    function boolValue(value, fallback) {
        return typeof value === "boolean" ? value : fallback;
    }
}

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

        onLoaded: rootDashboardService.reload()
        onTextChanged: rootDashboardService.reload()
        onLoadFailed: error => {
            rootDashboardService.error = "Dashboard config load failed: " + FileViewError.toString(error);
            rootDashboardService.blocks = rootDashboardService.defaultBlocks();
        }
    }

    function reload() {
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

        if (rawBlocks.length === 0) {
            blocks = defaultBlocks();
            error = "";
            return;
        }

        blocks = rawBlocks.map((block, index) => normalizeBlock(block, index));
        error = "";
    }

    function normalizeBlock(block, index) {
        const value = block || ({});

        return {
            id: stringValue(value.id, "block-" + index),
            type: stringValue(value.type, "fake"),
            title: stringValue(value.title, "Block " + (index + 1)),
            text: stringValue(value.text, ""),
            preset: stringValue(value.preset, "default"),
            x: numberValue(value.x, theme.dashboard.placementMargin),
            y: numberValue(value.y, theme.dashboard.placementMargin),
            width: numberValue(value.width, theme.dashboard.defaultCardWidth),
            height: numberValue(value.height, theme.dashboard.defaultCardHeight),
            from: stringValue(value.from, "center"),
            showTitle: boolValue(value.showTitle, true),
            showBackground: boolValue(value.showBackground, true),
            showBorder: boolValue(value.showBorder, true),
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
                x: 80,
                y: 110,
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
                type: "fake",
                title: "Weather",
                text: "Weather preview will live here once it stops needing a weather department.",
                preset: "compact",
                x: 80,
                y: 300,
                width: 380,
                height: 230,
                from: "bottom-left",
                showTitle: true,
                showBackground: true,
                showBorder: true,
                config: ({})
            },
            {
                id: "aegis-summary",
                type: "fake",
                title: "Aegis",
                text: "System overview preset placeholder",
                preset: "wide",
                x: 500,
                y: 110,
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
                x: 1260,
                y: 110,
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
                x: 1260,
                y: 400,
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

import QtQuick

Item {
    id: rootAegisPie

    required property QtObject theme
    property string title: ""
    property string usedLabel: "Used"
    property string freeLabel: "Free"
    property string totalLabel: "Total"
    property real usedBytes: 0
    property real freeBytes: 0
    property real totalBytes: 0
    property var config: ({})
    readonly property real requestedSize: Number.isFinite(Number(config.size)) ? Math.max(80, Number(config.size)) : theme.modules.aegis.pieSize
    readonly property string legendPosition: String(config.legendPosition || "left")
    readonly property bool vertical: legendPosition === "top" || legendPosition === "bottom"
    readonly property real itemSpacing: Number.isFinite(Number(config.spacing)) ? Math.max(4, Number(config.spacing)) : 16
    readonly property real horizontalLegendTarget: Math.min(170, Math.max(112, width * 0.42))
    readonly property real horizontalPieSize: Math.max(72, Math.min(requestedSize, Math.max(72, width - horizontalLegendTarget - itemSpacing), height))
    readonly property real horizontalLegendWidth: Math.max(1, width - horizontalPieSize - itemSpacing)
    readonly property real verticalPieSize: Math.max(72, Math.min(requestedSize, width, Math.max(72, height - legend.implicitHeight - itemSpacing)))

    implicitWidth: vertical ? Math.max(requestedSize, legend.implicitWidth) : requestedSize + legend.implicitWidth + itemSpacing
    implicitHeight: vertical ? requestedSize + legend.implicitHeight + itemSpacing : Math.max(requestedSize, legend.implicitHeight)

    Row {
        visible: !rootAegisPie.vertical
        anchors.fill: parent
        spacing: rootAegisPie.itemSpacing
        layoutDirection: rootAegisPie.legendPosition === "right" ? Qt.RightToLeft : Qt.LeftToRight

        Legend {
            id: rowLegend
            width: rootAegisPie.horizontalLegendWidth
            anchors.verticalCenter: parent.verticalCenter
            theme: rootAegisPie.theme
            usedLabel: rootAegisPie.usedLabel
            freeLabel: rootAegisPie.freeLabel
            totalLabel: rootAegisPie.totalLabel
            usedBytes: rootAegisPie.usedBytes
            freeBytes: rootAegisPie.freeBytes
            totalBytes: rootAegisPie.totalBytes
        }

        PieCanvas {
            width: rootAegisPie.horizontalPieSize
            height: rootAegisPie.horizontalPieSize
            anchors.verticalCenter: parent.verticalCenter
            theme: rootAegisPie.theme
            fraction: usedFraction()
        }
    }

    Column {
        visible: rootAegisPie.vertical
        anchors.fill: parent
        spacing: rootAegisPie.itemSpacing

        PieCanvas {
            visible: rootAegisPie.legendPosition === "bottom"
            width: rootAegisPie.verticalPieSize
            height: rootAegisPie.verticalPieSize
            anchors.horizontalCenter: parent.horizontalCenter
            theme: rootAegisPie.theme
            fraction: usedFraction()
        }

        Legend {
            id: legend
            width: parent.width
            theme: rootAegisPie.theme
            usedLabel: rootAegisPie.usedLabel
            freeLabel: rootAegisPie.freeLabel
            totalLabel: rootAegisPie.totalLabel
            usedBytes: rootAegisPie.usedBytes
            freeBytes: rootAegisPie.freeBytes
            totalBytes: rootAegisPie.totalBytes
        }

        PieCanvas {
            visible: rootAegisPie.legendPosition !== "bottom"
            width: rootAegisPie.verticalPieSize
            height: rootAegisPie.verticalPieSize
            anchors.horizontalCenter: parent.horizontalCenter
            theme: rootAegisPie.theme
            fraction: usedFraction()
        }
    }

    function usedFraction() {
        return totalBytes > 0 ? Math.max(0, Math.min(1, usedBytes / totalBytes)) : 0;
    }

    function formatBytes(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Number(bytes);
        let index = 0;
        if (!Number.isFinite(value) || value <= 0)
            return "--";
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024;
            index += 1;
        }
        return value.toFixed(value >= 10 || index === 0 ? 0 : 1) + " " + units[index];
    }

    component PieCanvas: Canvas {
        required property QtObject theme
        property real fraction: 0

        onFractionChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            const cx = width / 2;
            const cy = height / 2;
            const radius = Math.max(1, Math.min(width, height) / 2 - 6);
            ctx.reset();
            ctx.beginPath();
            ctx.fillStyle = theme.modules.aegis.successColor;
            ctx.globalAlpha = 0.62;
            ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
            ctx.fill();

            if (fraction > 0) {
                ctx.beginPath();
                ctx.moveTo(cx, cy);
                ctx.fillStyle = theme.modules.aegis.errorColor;
                ctx.globalAlpha = 0.9;
                ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * fraction, false);
                ctx.closePath();
                ctx.fill();
            }

            ctx.globalAlpha = 0.55;
            ctx.strokeStyle = theme.modules.aegis.borderColor;
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
            ctx.stroke();
            ctx.globalAlpha = 1;
        }
    }

    component Legend: Column {
        required property QtObject theme
        property string usedLabel: ""
        property string freeLabel: ""
        property string totalLabel: ""
        property real usedBytes: 0
        property real freeBytes: 0
        property real totalBytes: 0

        spacing: 7

        LegendRow {
            width: parent.width
            theme: parent.theme
            colorValue: parent.theme.modules.aegis.errorColor
            label: parent.usedLabel
            value: rootAegisPie.formatBytes(parent.usedBytes)
        }

        LegendRow {
            width: parent.width
            theme: parent.theme
            colorValue: parent.theme.modules.aegis.successColor
            label: parent.freeLabel
            value: rootAegisPie.formatBytes(parent.freeBytes)
        }

        LegendRow {
            width: parent.width
            theme: parent.theme
            colorValue: parent.theme.modules.aegis.secondaryTextColor
            label: parent.totalLabel
            value: rootAegisPie.formatBytes(parent.totalBytes)
        }
    }

    component LegendRow: Row {
        required property QtObject theme
        property color colorValue: "transparent"
        property string label: ""
        property string value: ""

        spacing: 8
        height: Math.max(labelText.implicitHeight, 12)

        Rectangle {
            width: 10
            height: 10
            radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: parent.colorValue
        }

        Text {
            id: labelText

            width: Math.max(1, parent.width - valueText.width - parent.spacing * 2 - 10)
            text: parent.label
            color: parent.theme.modules.aegis.secondaryTextColor
            font.pixelSize: parent.theme.modules.aegis.bodyPixelSize
            elide: Text.ElideRight
        }

        Text {
            id: valueText

            text: parent.value
            color: parent.theme.modules.aegis.primaryTextColor
            font.pixelSize: parent.theme.modules.aegis.bodyPixelSize
            font.family: "monospace"
        }
    }
}

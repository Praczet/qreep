import QtQuick

Item {
    id: rootAegisCpuGraph

    required property QtObject theme
    property QtObject service
    property var config: ({})
    readonly property var cpu: service ? service.data.cpu || ({}) : ({})
    readonly property var cores: Array.isArray(cpu.cores) ? cpu.cores : []
    readonly property real totalUsage: Number.isFinite(Number(cpu.usage)) ? Number(cpu.usage) : 0
    readonly property real coreOpacity: Number.isFinite(Number(config.opacity)) ? Math.max(0, Math.min(1, Number(config.opacity))) : 0.7

    implicitHeight: layout.implicitHeight

    Column {
        id: layout

        width: parent.width
        spacing: 10

        Row {
            width: parent.width
            spacing: 10

            Text {
                width: Math.max(1, parent.width - metaText.width - parent.spacing)
                text: service ? String(service.data.hardware.cpu || "CPU") : "CPU"
                color: rootAegisCpuGraph.theme.modules.aegis.primaryTextColor
                font.pixelSize: rootAegisCpuGraph.theme.modules.aegis.bodyPixelSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                id: metaText

                text: formatCpuMeta()
                color: rootAegisCpuGraph.theme.modules.aegis.secondaryTextColor
                font.pixelSize: rootAegisCpuGraph.theme.modules.aegis.metaPixelSize
                font.family: "monospace"
            }
        }

        UsageBar {
            width: parent.width
            label: "CPU"
            value: rootAegisCpuGraph.totalUsage
            theme: rootAegisCpuGraph.theme
        }

        Grid {
            width: parent.width
            columns: parent.width > 420 ? 2 : 1
            columnSpacing: 12
            rowSpacing: 7

            Repeater {
                model: rootAegisCpuGraph.cores

                UsageBar {
                    required property int index
                    required property real modelData

                    width: (parent.width - parent.columnSpacing * (parent.columns - 1)) / parent.columns
                    opacity: rootAegisCpuGraph.coreOpacity
                    label: "C" + index
                    value: Number(modelData || 0)
                    theme: rootAegisCpuGraph.theme
                }
            }
        }
    }

    function formatCpuMeta() {
        const speed = Number(cpu.speedGhz || 0);
        const temp = Number(cpu.tempC || 0);
        const parts = [];
        if (speed > 0)
            parts.push(speed.toFixed(2) + " GHz");
        if (temp > 0)
            parts.push(Math.round(temp) + " C");
        return parts.length > 0 ? parts.join(" - ") : "--";
    }

    component UsageBar: Item {
        required property QtObject theme
        property string label: ""
        property real value: 0

        implicitHeight: Math.max(labelText.implicitHeight, theme.modules.aegis.graphBarHeight + 4)

        Row {
            anchors.fill: parent
            spacing: 8

            Text {
                id: labelText

                width: 34
                text: parent.parent.label
                color: parent.parent.theme.modules.aegis.secondaryTextColor
                font.pixelSize: parent.parent.theme.modules.aegis.metaPixelSize
                font.family: "monospace"
            }

            Rectangle {
                width: Math.max(1, parent.width - labelText.width - valueText.width - parent.spacing * 2)
                height: parent.parent.theme.modules.aegis.graphBarHeight
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(parent.parent.theme.modules.aegis.accentColor.r, parent.parent.theme.modules.aegis.accentColor.g, parent.parent.theme.modules.aegis.accentColor.b, 0.16)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(100, parent.parent.parent.value)) / 100
                    height: parent.height
                    radius: parent.radius
                    color: parent.parent.parent.theme.modules.aegis.accentColor

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Text {
                id: valueText

                width: 42
                text: Math.round(parent.parent.value) + "%"
                color: parent.parent.theme.modules.aegis.primaryTextColor
                font.pixelSize: parent.parent.theme.modules.aegis.metaPixelSize
                font.family: "monospace"
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}

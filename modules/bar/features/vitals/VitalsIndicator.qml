import QtQuick
import "../../../../components" as Components

// One vitals indicator. `item` comes from Vitals.indicatorItem():
// gauge / pie carry value + color + icon, clusters carry values + colors.
Item {
    id: rootVitalsIndicator

    required property QtObject theme
    required property var item

    readonly property QtObject vitalsTheme: theme.modules.bar.vitals
    readonly property bool cluster: item.kind === "gauge-cluster" || item.kind === "pie-cluster"
    readonly property int clusterCount: cluster ? item.values.length : 0
    // Two rows keep eight thread pies inside the pill height.
    readonly property int clusterColumns: Math.max(1, Math.ceil(clusterCount / 2))

    implicitWidth: cluster ? clusterGrid.implicitWidth : vitalsTheme.indicatorSize
    implicitHeight: cluster ? clusterGrid.implicitHeight : vitalsTheme.indicatorSize

    Components.QreepGauge {
        visible: rootVitalsIndicator.item.kind === "gauge"
        anchors.fill: parent
        value: visible ? rootVitalsIndicator.item.value : 0
        color: rootVitalsIndicator.item.color || rootVitalsIndicator.vitalsTheme.normalColor
        trackColor: rootVitalsIndicator.vitalsTheme.trackColor
        lineWidth: rootVitalsIndicator.vitalsTheme.gaugeLineWidth

        Text {
            anchors.centerIn: parent
            text: rootVitalsIndicator.item.icon || ""
            color: rootVitalsIndicator.vitalsTheme.iconColor
            font.family: rootVitalsIndicator.theme.iconFontFamily
            font.pixelSize: rootVitalsIndicator.vitalsTheme.iconPixelSize
        }
    }

    Components.QreepPie {
        visible: rootVitalsIndicator.item.kind === "pie"
        anchors.fill: parent
        value: visible ? rootVitalsIndicator.item.value : 0
        color: rootVitalsIndicator.item.color || rootVitalsIndicator.vitalsTheme.normalColor
        trackColor: rootVitalsIndicator.vitalsTheme.trackColor

        Text {
            anchors.centerIn: parent
            text: rootVitalsIndicator.item.icon || ""
            color: rootVitalsIndicator.vitalsTheme.iconColor
            style: Text.Outline
            styleColor: rootVitalsIndicator.vitalsTheme.trackColor
            font.family: rootVitalsIndicator.theme.iconFontFamily
            font.pixelSize: rootVitalsIndicator.vitalsTheme.iconPixelSize
        }
    }

    Grid {
        id: clusterGrid

        visible: rootVitalsIndicator.cluster
        anchors.centerIn: parent
        columns: rootVitalsIndicator.clusterColumns
        spacing: rootVitalsIndicator.vitalsTheme.clusterSpacing

        Repeater {
            model: rootVitalsIndicator.clusterCount

            Item {
                id: clusterCell

                required property int index

                width: rootVitalsIndicator.vitalsTheme.clusterItemSize
                height: rootVitalsIndicator.vitalsTheme.clusterItemSize

                Components.QreepGauge {
                    visible: rootVitalsIndicator.item.kind === "gauge-cluster"
                    anchors.fill: parent
                    value: rootVitalsIndicator.item.values[clusterCell.index] || 0
                    color: rootVitalsIndicator.item.colors[clusterCell.index] || rootVitalsIndicator.vitalsTheme.normalColor
                    trackColor: rootVitalsIndicator.vitalsTheme.trackColor
                    lineWidth: rootVitalsIndicator.vitalsTheme.clusterGaugeLineWidth
                }

                Components.QreepPie {
                    visible: rootVitalsIndicator.item.kind === "pie-cluster"
                    anchors.fill: parent
                    value: rootVitalsIndicator.item.values[clusterCell.index] || 0
                    color: rootVitalsIndicator.item.colors[clusterCell.index] || rootVitalsIndicator.vitalsTheme.normalColor
                    trackColor: rootVitalsIndicator.vitalsTheme.trackColor
                }
            }
        }
    }
}

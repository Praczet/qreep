import QtQuick
import Quickshell

PopupWindow {
    id: rootBorgTooltip

    required property QtObject theme

    property Item anchorItem
    property var tooltip: ({ rows: [] })
    property string className: "normal"
    readonly property var rows: rowList(tooltip)
    readonly property bool hasHero: rows.length >= 3 && rows[0].text && rows[1].text && rows[2].text
    readonly property var heroIconRow: hasHero ? rows[0] : ({ text: "", size: 36, color: "{{primary}}" })
    readonly property var heroTitleRow: hasHero ? rows[1] : ({ text: "WE ARE THE BORG", bold: true, color: "{{on_surface}}" })
    readonly property var heroStatusRow: hasHero ? rows[2] : ({ text: "", color: "{{on_surface_variant}}" })
    readonly property var detailRows: hasHero ? rows.slice(3) : rows

    anchor {
        item: rootBorgTooltip.anchorItem
        rect.x: rootBorgTooltip.anchorItem ? rootBorgTooltip.anchorItem.width / 2 - rootBorgTooltip.width / 2 : 0
        rect.y: rootBorgTooltip.anchorItem ? rootBorgTooltip.anchorItem.height + rootBorgTooltip.theme.modules.bar.tooltip.offsetY : 0
    }

    implicitWidth: rootBorgTooltip.theme.borg.tooltipWidth
    implicitHeight: tooltipLayout.implicitHeight + rootBorgTooltip.theme.modules.bar.tooltip.verticalPadding * 2
    color: "transparent"
    grabFocus: false

    function showFor(anchorItem, tooltip, className) {
        hideTimer.stop();
        hideAnimation.stop();

        rootBorgTooltip.anchorItem = anchorItem;
        rootBorgTooltip.tooltip = tooltip || ({ rows: [] });
        rootBorgTooltip.className = className || "normal";

        if (visible) {
            tooltipBody.scale = 1;
            return;
        }

        showTimer.restart();
    }

    function hideLater() {
        showTimer.stop();

        if (visible)
            hideTimer.restart();
    }

    function rowAlign(align) {
        switch (align) {
        case "center":
            return Text.AlignHCenter;
        case "right":
            return Text.AlignRight;
        default:
            return Text.AlignLeft;
        }
    }

    function rowSize(row) {
        return Number(row.size || rootBorgTooltip.tooltip.default_size || rootBorgTooltip.theme.modules.bar.tooltip.contentPixelSize);
    }

    function rowList(tooltip) {
        const source = tooltip && tooltip.rows;
        const result = [];

        if (!source || source.length === undefined)
            return result;

        for (let index = 0; index < source.length; index++)
            result.push(source[index]);

        return result;
    }

    function hasColumns(row) {
        return Boolean(row.columns && row.columns.length >= 2);
    }

    function column(row, index) {
        return hasColumns(row) ? row.columns[index] || ({}) : ({});
    }

    Rectangle {
        id: tooltipBody

        anchors.fill: parent
        transformOrigin: Item.Center
        scale: 0
        radius: rootBorgTooltip.theme.modules.bar.tooltip.radius
        color: rootBorgTooltip.theme.calendarBackground
        border.width: rootBorgTooltip.theme.modules.bar.tooltip.borderWidth
        border.color: rootBorgTooltip.theme.borgClassColor(rootBorgTooltip.className)

        Column {
            id: tooltipLayout

            anchors {
                fill: parent
                margins: rootBorgTooltip.theme.modules.bar.tooltip.padding
            }
            spacing: rootBorgTooltip.theme.borg.tooltipRowSpacing

            Row {
                id: heroLayout

                width: parent.width
                spacing: rootBorgTooltip.theme.borg.tooltipHeroSpacing

                Text {
                    id: heroIcon

                    width: rootBorgTooltip.theme.borg.tooltipHeroIconWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(rootBorgTooltip.heroIconRow.text || "")
                    color: rootBorgTooltip.theme.borgTokenColor(rootBorgTooltip.heroIconRow.color)
                    font.family: rootBorgTooltip.theme.iconFontFamily
                    font.pixelSize: rootBorgTooltip.rowSize(rootBorgTooltip.heroIconRow)
                    font.weight: rootBorgTooltip.heroIconRow.bold ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Column {
                    width: parent.width - heroIcon.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: rootBorgTooltip.theme.borg.tooltipHeroTextSpacing

                    Text {
                        width: parent.width
                        text: String(rootBorgTooltip.heroTitleRow.text || "")
                        color: rootBorgTooltip.theme.borgTokenColor(rootBorgTooltip.heroTitleRow.color)
                        font.pixelSize: rootBorgTooltip.rowSize(rootBorgTooltip.heroTitleRow)
                        font.weight: rootBorgTooltip.heroTitleRow.bold ? Font.DemiBold : Font.Normal
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: String(rootBorgTooltip.heroStatusRow.text || "")
                        color: rootBorgTooltip.theme.borgTokenColor(rootBorgTooltip.heroStatusRow.color)
                        font.pixelSize: rootBorgTooltip.rowSize(rootBorgTooltip.heroStatusRow)
                        font.weight: rootBorgTooltip.heroStatusRow.bold ? Font.DemiBold : Font.Normal
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }

            Repeater {
                model: rootBorgTooltip.detailRows

                delegate: Item {
                    required property var modelData
                    readonly property bool isBlank: Boolean(modelData.blank)
                    readonly property bool rowHasColumns: rootBorgTooltip.hasColumns(modelData)
                    readonly property var firstColumn: rootBorgTooltip.column(modelData, 0)
                    readonly property var secondColumn: rootBorgTooltip.column(modelData, 1)

                    width: tooltipLayout.width
                    height: isBlank
                        ? rootBorgTooltip.theme.borg.tooltipBlankHeight
                        : rowHasColumns ? columnsRow.implicitHeight : textRow.implicitHeight

                    Text {
                        id: textRow

                        width: parent.width
                        visible: !parent.isBlank && !parent.rowHasColumns
                        text: String(parent.modelData.text || "")
                        color: rootBorgTooltip.theme.borgTokenColor(parent.modelData.color)
                        font.family: parent.modelData.size >= rootBorgTooltip.theme.borg.tooltipIconThreshold ? rootBorgTooltip.theme.iconFontFamily : ""
                        font.pixelSize: rootBorgTooltip.rowSize(parent.modelData)
                        font.weight: parent.modelData.bold ? Font.DemiBold : Font.Normal
                        horizontalAlignment: rootBorgTooltip.rowAlign(parent.modelData.align)
                        wrapMode: Text.Wrap
                    }

                    Row {
                        id: columnsRow

                        width: parent.width
                        visible: !parent.isBlank && parent.rowHasColumns
                        spacing: rootBorgTooltip.theme.borg.tooltipColumnGap

                        Text {
                            width: rootBorgTooltip.theme.borg.tooltipLabelWidth
                            text: String(parent.parent.firstColumn.text || "")
                            color: rootBorgTooltip.theme.borgTokenColor(parent.parent.firstColumn.color)
                            font.pixelSize: rootBorgTooltip.rowSize(parent.parent.firstColumn)
                            font.weight: parent.parent.firstColumn.bold ? Font.DemiBold : Font.Normal
                            horizontalAlignment: Text.AlignRight
                        }

                        Text {
                            width: parent.width - rootBorgTooltip.theme.borg.tooltipLabelWidth - parent.spacing
                            text: String(parent.parent.secondColumn.text || "")
                            color: rootBorgTooltip.theme.borgTokenColor(parent.parent.secondColumn.color)
                            font.pixelSize: rootBorgTooltip.rowSize(parent.parent.secondColumn)
                            font.weight: parent.parent.secondColumn.bold ? Font.DemiBold : Font.Normal
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: showTimer

        interval: rootBorgTooltip.theme.modules.bar.tooltip.showDelay
        repeat: false
        onTriggered: {
            rootBorgTooltip.visible = true;
            showAnimation.restart();
        }
    }

    Timer {
        id: hideTimer

        interval: rootBorgTooltip.theme.modules.bar.tooltip.hideDelay
        repeat: false
        onTriggered: hideAnimation.restart()
    }

    SequentialAnimation {
        id: showAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 0
            to: rootBorgTooltip.theme.modules.bar.tooltip.popScale
            duration: rootBorgTooltip.theme.modules.bar.tooltip.showOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootBorgTooltip.theme.modules.bar.tooltip.popScale
            to: 1
            duration: rootBorgTooltip.theme.modules.bar.tooltip.showSettleDuration
            easing.type: Easing.InOutCubic
        }
    }

    SequentialAnimation {
        id: hideAnimation

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: 1
            to: rootBorgTooltip.theme.modules.bar.tooltip.popScale
            duration: rootBorgTooltip.theme.modules.bar.tooltip.hideOutDuration
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: tooltipBody
            property: "scale"
            from: rootBorgTooltip.theme.modules.bar.tooltip.popScale
            to: 0
            duration: rootBorgTooltip.theme.modules.bar.tooltip.hideInDuration
            easing.type: Easing.InCubic
        }

        ScriptAction {
            script: rootBorgTooltip.visible = false
        }
    }
}

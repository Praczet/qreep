import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootBloomPanel

    required property QtObject theme
    required property QtObject service
    property bool panelOpen: false

    implicitWidth: screen.width
    implicitHeight: theme.modules.bloom.panelHeight
    visible: panelOpen
    color: "transparent"
    exclusiveZone: 0

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "qreep-bloom"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        id: card

        width: Math.min(rootBloomPanel.theme.modules.bloom.cardWidth, rootBloomPanel.width - 48)
        height: rootBloomPanel.theme.modules.bloom.cardHeight
        x: (rootBloomPanel.width - width) / 2
        y: rootBloomPanel.theme.modules.bloom.topMargin
        radius: rootBloomPanel.theme.modules.bloom.cardRadius
        color: rootBloomPanel.theme.modules.bloom.backgroundColor
        border.width: rootBloomPanel.theme.modules.bloom.cardBorderWidth
        border.color: rootBloomPanel.theme.modules.bloom.borderColor
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Image {
                visible: rootBloomPanel.service.wallpaper.length > 0
                Layout.preferredWidth: rootBloomPanel.theme.modules.bloom.wallpaperWidth
                Layout.fillHeight: true
                source: rootBloomPanel.service.wallpaper.length > 0 ? "file://" + rootBloomPanel.service.wallpaper : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: rootBloomPanel.theme.modules.bloom.contentPadding
                spacing: rootBloomPanel.theme.modules.bloom.contentSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "◉"
                        color: rootBloomPanel.theme.modules.bloom.secondaryTextColor
                        font.pixelSize: rootBloomPanel.theme.modules.bloom.bodyPixelSize
                    }

                    Text {
                        text: "unclaimed-bloom"
                        color: rootBloomPanel.theme.modules.bloom.primaryTextColor
                        font.pixelSize: rootBloomPanel.theme.modules.bloom.titlePixelSize
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "•"
                        color: rootBloomPanel.theme.modules.bloom.secondaryTextColor
                        font.pixelSize: rootBloomPanel.theme.modules.bloom.bodyPixelSize
                    }

                    Text {
                        Layout.fillWidth: true
                        text: rootBloomPanel.service.profile.length > 0 ? rootBloomPanel.service.profile : "bloom"
                        color: rootBloomPanel.theme.modules.bloom.accentColor
                        font.pixelSize: rootBloomPanel.theme.modules.bloom.titlePixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: rootBloomPanel.theme.modules.bloom.rowSpacing

                    Repeater {
                        model: ["sow", "grow", "plant"]

                        ColumnLayout {
                            required property string modelData

                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                opacity: stageRecord().status === "pending" ? 0.38 : 1

                                Text {
                                    Layout.preferredWidth: 22
                                    text: stageIcon(stageRecord().status)
                                    color: stageColor(stageRecord().status)
                                    font.pixelSize: rootBloomPanel.theme.modules.bloom.bodyPixelSize
                                    font.family: "monospace"
                                }

                                Text {
                                    Layout.preferredWidth: 54
                                    text: parent.parent.modelData
                                    color: rootBloomPanel.theme.modules.bloom.primaryTextColor
                                    font.pixelSize: rootBloomPanel.theme.modules.bloom.bodyPixelSize
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.preferredWidth: 60
                                    text: elapsedText(stageRecord())
                                    color: rootBloomPanel.theme.modules.bloom.secondaryTextColor
                                    font.pixelSize: rootBloomPanel.theme.modules.bloom.metaPixelSize
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    Layout.preferredWidth: 96
                                    text: targetCountText(stageRecord())
                                    color: rootBloomPanel.theme.modules.bloom.secondaryTextColor
                                    font.pixelSize: rootBloomPanel.theme.modules.bloom.metaPixelSize
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: stageRecord().currentTarget.length > 0 ? "(" + stageRecord().currentTarget + ")" : ""
                                    color: rootBloomPanel.theme.modules.bloom.secondaryTextColor
                                    font.pixelSize: rootBloomPanel.theme.modules.bloom.metaPixelSize
                                    font.italic: true
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                visible: stageRecord().worker !== null
                                Layout.leftMargin: 30
                                Layout.fillWidth: true
                                height: rootBloomPanel.theme.modules.bloom.progressHeight
                                radius: height / 2
                                color: Qt.rgba(rootBloomPanel.theme.modules.bloom.accentColor.r, rootBloomPanel.theme.modules.bloom.accentColor.g, rootBloomPanel.theme.modules.bloom.accentColor.b, 0.18)

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, stageRecord().worker ? Number(stageRecord().worker.pct || 0) : 0))
                                    height: parent.height
                                    radius: parent.radius
                                    color: rootBloomPanel.theme.modules.bloom.accentColor
                                }
                            }

                            Text {
                                visible: stageRecord().worker !== null && String(stageRecord().worker.msg || "").length > 0
                                Layout.leftMargin: 30
                                Layout.fillWidth: true
                                text: stageRecord().worker ? String(stageRecord().worker.msg || "") : ""
                                color: rootBloomPanel.theme.modules.bloom.secondaryTextColor
                                font.pixelSize: rootBloomPanel.theme.modules.bloom.metaPixelSize
                                font.family: "monospace"
                                elide: Text.ElideRight
                            }

                            function stageRecord() {
                                return rootBloomPanel.service.stages[modelData] || rootBloomPanel.service.stages.sow;
                            }
                        }
                    }
                }

                Text {
                    visible: rootBloomPanel.service.terminal
                    Layout.fillWidth: true
                    text: rootBloomPanel.service.overallStatus === "error" ? "✗ Error occurred" : "✓ Done  —  ~/.cache/unclaimed-bloom/reports/"
                    color: rootBloomPanel.service.overallStatus === "error" ? rootBloomPanel.theme.modules.bloom.errorColor : rootBloomPanel.theme.modules.bloom.secondaryTextColor
                    font.pixelSize: rootBloomPanel.theme.modules.bloom.metaPixelSize
                    elide: Text.ElideRight
                }
            }
        }
    }

    function stageIcon(status) {
        switch (String(status || "pending")) {
        case "running":
            return "⟳";
        case "done":
            return "✓";
        case "error":
            return "✗";
        default:
            return "⋯";
        }
    }

    function stageColor(status) {
        if (status === "error")
            return rootBloomPanel.theme.modules.bloom.errorColor;

        if (status === "running" || status === "done")
            return rootBloomPanel.theme.modules.bloom.accentColor;

        return rootBloomPanel.theme.modules.bloom.secondaryTextColor;
    }

    function elapsedText(stage) {
        if (!stage || stage.status === "pending" || stage.startedAt.length === 0)
            return "";

        const start = new Date(stage.startedAt).getTime();
        const end = stage.status === "running" ? Date.now() : new Date(stage.updatedAt).getTime();
        const ms = Math.max(0, end - start);

        return ms < 10000 ? (ms / 1000).toFixed(1) + "s" : Math.round(ms / 1000) + "s";
    }

    function targetCountText(stage) {
        if (!stage || stage.status === "pending" || stage.targetCount <= 0)
            return "";

        if (stage.status === "done" || stage.status === "error")
            return "(" + stage.targetCount + " targets)";

        return stage.doneCount + "/" + stage.targetCount;
    }
}

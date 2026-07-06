import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootAegisPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false

    signal closeRequested

    implicitWidth: screen.width
    implicitHeight: screen.height
    color: rootAegisPanel.theme.modules.aegis.overlayColor
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-aegis"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        background.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            background.forceActiveFocus();
            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootAegisPanel.closeRequested()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootAegisPanel.presented = true
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }
    }

    Item {
        id: board

        width: Math.min(rootAegisPanel.theme.modules.aegis.panelWidth, parent.width - 96)
        height: Math.min(rootAegisPanel.theme.modules.aegis.panelHeight, parent.height - 96)
        anchors.centerIn: parent
        readonly property real gap: rootAegisPanel.theme.modules.aegis.cardGap
        readonly property real topY: 126
        readonly property real topHeight: 300
        readonly property real bottomY: topY + topHeight + gap
        readonly property real footerHeight: 30
        readonly property real bottomHeight: height - bottomY - footerHeight
        readonly property real halfWidth: (width - gap) / 2
        readonly property real thirdWidth: (width - gap * 2) / 3

        AegisCard {
            theme: rootAegisPanel.theme
            entered: rootAegisPanel.presented
            from: "top"
            baseX: 0
            baseY: 0
            width: board.width
            height: 108

            AegisHero {
                anchors {
                    left: parent.left
                    right: updatedText.left
                    verticalCenter: parent.verticalCenter
                    rightMargin: 18
                }
                theme: rootAegisPanel.theme
                service: rootAegisPanel.service
            }

            Text {
                id: updatedText

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                text: "updated " + rootAegisPanel.service.refreshTime
                color: rootAegisPanel.theme.modules.aegis.secondaryTextColor
                font.pixelSize: rootAegisPanel.theme.modules.aegis.metaPixelSize
            }
        }

        AegisCard {
            theme: rootAegisPanel.theme
            entered: rootAegisPanel.presented
            from: "top-left"
            baseX: 0
            baseY: board.topY
            width: board.halfWidth
            height: board.topHeight

            Column {
                anchors.fill: parent
                spacing: rootAegisPanel.theme.modules.aegis.cardGap

                AegisSection {
                    width: parent.width
                    theme: rootAegisPanel.theme
                    section: firstSection("system")
                }

                AegisSection {
                    width: parent.width
                    theme: rootAegisPanel.theme
                    section: firstSection("status")
                }
            }
        }

        AegisCard {
            theme: rootAegisPanel.theme
            entered: rootAegisPanel.presented
            from: "top-right"
            baseX: board.halfWidth + board.gap
            baseY: board.topY
            width: board.halfWidth
            height: board.topHeight

            Row {
                anchors.fill: parent
                spacing: rootAegisPanel.theme.modules.aegis.cardGap

                Column {
                    width: parent.width - memoryPieColumn.width - parent.spacing
                    height: parent.height
                    spacing: rootAegisPanel.theme.modules.aegis.cardGap

                    AegisSection {
                        width: parent.width
                        theme: rootAegisPanel.theme
                        section: firstSection("hardware")
                    }

                    AegisSection {
                        width: parent.width
                        theme: rootAegisPanel.theme
                        section: firstSection("memory")
                    }
                }

                Column {
                    id: memoryPieColumn

                    width: 220
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Text {
                        width: parent.width
                        text: "Memory"
                        color: rootAegisPanel.theme.modules.aegis.primaryTextColor
                        font.pixelSize: rootAegisPanel.theme.modules.aegis.sectionTitlePixelSize
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                    }

                    AegisPie {
                        width: parent.width
                        height: 190
                        theme: rootAegisPanel.theme
                        config: ({ size: 130, legendPosition: "top" })
                        usedLabel: "Used"
                        freeLabel: "Free"
                        totalLabel: "Total"
                        usedBytes: Number(rootAegisPanel.service.data.memory.usedBytes || 0)
                        freeBytes: Number(rootAegisPanel.service.data.memory.availableBytes || 0)
                        totalBytes: Number(rootAegisPanel.service.data.memory.totalBytes || 0)
                    }
                }
            }
        }

        AegisCard {
            theme: rootAegisPanel.theme
            entered: rootAegisPanel.presented
            from: "left"
            baseX: 0
            baseY: board.bottomY
            width: board.thirdWidth
            height: board.bottomHeight

            AegisCpuGraph {
                anchors.fill: parent
                theme: rootAegisPanel.theme
                service: rootAegisPanel.service
                config: ({})
            }
        }

        AegisCard {
            theme: rootAegisPanel.theme
            entered: rootAegisPanel.presented
            from: "bottom"
            baseX: board.thirdWidth + board.gap
            baseY: board.bottomY
            width: board.thirdWidth
            height: board.bottomHeight

            Column {
                anchors.fill: parent
                spacing: rootAegisPanel.theme.modules.aegis.cardGap

                AegisSection {
                    width: parent.width
                    theme: rootAegisPanel.theme
                    section: firstSection("storage")
                }

                Item {
                    width: parent.width
                    height: Math.max(150, parent.height - y)

                    AegisPie {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        theme: rootAegisPanel.theme
                        config: ({ size: 150, legendPosition: "left" })
                        usedLabel: "Used"
                        freeLabel: "Free"
                        totalLabel: "Total"
                        usedBytes: diskValue("usedBytes")
                        freeBytes: diskValue("freeBytes")
                        totalBytes: diskValue("sizeBytes")
                    }
                }
            }
        }

        AegisCard {
            theme: rootAegisPanel.theme
            entered: rootAegisPanel.presented
            from: "right"
            baseX: (board.thirdWidth + board.gap) * 2
            baseY: board.bottomY
            width: board.thirdWidth
            height: board.bottomHeight

            Column {
                anchors.fill: parent
                spacing: rootAegisPanel.theme.modules.aegis.cardGap

                AegisSection {
                    width: parent.width
                    theme: rootAegisPanel.theme
                    section: firstSection("network-info")
                }

                AegisSection {
                    width: parent.width
                    theme: rootAegisPanel.theme
                    section: firstSection("power")
                }

                AegisSection {
                    width: parent.width
                    theme: rootAegisPanel.theme
                    section: firstSection("hyprland")
                }
            }
        }

        Row {
            anchors {
                bottom: board.bottom
                horizontalCenter: board.horizontalCenter
                bottomMargin: 5
            }
            spacing: 8

            Text {
                text: "Copy all info:"
                color: rootAegisPanel.theme.modules.aegis.secondaryTextColor
                font.pixelSize: rootAegisPanel.theme.modules.aegis.metaPixelSize
            }

            Text {
                text: "text"
                color: rootAegisPanel.theme.modules.aegis.accentColor
                font.pixelSize: rootAegisPanel.theme.modules.aegis.metaPixelSize

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootAegisPanel.service.copyInfo("text")
                }
            }

            Text {
                text: "|"
                color: rootAegisPanel.theme.modules.aegis.secondaryTextColor
                font.pixelSize: rootAegisPanel.theme.modules.aegis.metaPixelSize
            }

            Text {
                text: "json"
                color: rootAegisPanel.theme.modules.aegis.accentColor
                font.pixelSize: rootAegisPanel.theme.modules.aegis.metaPixelSize

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootAegisPanel.service.copyInfo("json")
                }
            }
        }
    }

    Rectangle {
        visible: rootAegisPanel.service.error.length > 0
        anchors {
            left: parent.left
            bottom: parent.bottom
            margins: 48
        }
        width: Math.min(620, parent.width - 96)
        height: errorText.implicitHeight + rootAegisPanel.theme.modules.aegis.cardPadding * 2
        radius: rootAegisPanel.theme.modules.aegis.cardRadius
        color: Qt.rgba(rootAegisPanel.theme.modules.aegis.errorColor.r, rootAegisPanel.theme.modules.aegis.errorColor.g, rootAegisPanel.theme.modules.aegis.errorColor.b, 0.16)
        border.width: 1
        border.color: rootAegisPanel.theme.modules.aegis.errorColor

        Text {
            id: errorText

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: rootAegisPanel.theme.modules.aegis.cardPadding
            }
            text: rootAegisPanel.service.error
            color: rootAegisPanel.theme.modules.aegis.primaryTextColor
            font.pixelSize: rootAegisPanel.theme.modules.aegis.bodyPixelSize
            wrapMode: Text.Wrap
        }
    }

    function firstSection(id) {
        const sections = rootAegisPanel.service.sections("full", [id]);
        return sections.length > 0 ? sections[0] : ({ title: id, rows: [] });
    }

    function diskValue(key) {
        const disks = rootAegisPanel.service && Array.isArray(rootAegisPanel.service.data.physicalDisks) ? rootAegisPanel.service.data.physicalDisks : [];
        const disk = disks.length > 0 ? disks[0] : null;
        return disk ? Number(disk[key] || 0) : 0;
    }
}

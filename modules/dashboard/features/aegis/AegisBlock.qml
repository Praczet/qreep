import QtQuick

Item {
    id: rootAegisBlock

    required property QtObject theme
    property QtObject service
    property string type: "aegis"
    property var config: ({})
    readonly property bool hasService: rootAegisBlock.service !== null
    readonly property string mode: String(config.mode || (type === "aegis" ? "summary" : "minimal"))
    readonly property var sections: Array.isArray(config.sections) ? config.sections : []

    clip: true

    Text {
        visible: !rootAegisBlock.hasService
        anchors.centerIn: parent
        text: "Aegis service unavailable"
        color: rootAegisBlock.theme.modules.aegis.secondaryTextColor
        font.pixelSize: rootAegisBlock.theme.modules.aegis.bodyPixelSize
    }

    Loader {
        anchors.fill: parent
        active: rootAegisBlock.hasService
        sourceComponent: blockComponent()
    }

    function blockComponent() {
        switch (rootAegisBlock.type) {
        case "aegis-cpu-graph":
            return cpuComponent;
        case "aegis-memory-pie":
            return memoryPieComponent;
        case "aegis-disk-pie":
            return diskPieComponent;
        case "aegis-copy-footer":
            return copyFooterComponent;
        case "aegis-summary":
        case "aegis":
        default:
            return sectionsComponent;
        }
    }

    Component {
        id: sectionsComponent

        Flickable {
            contentWidth: width
            contentHeight: sectionLayout.implicitHeight
            clip: true

            Column {
                id: sectionLayout

                width: parent.width
                spacing: rootAegisBlock.theme.modules.aegis.cardGap

                AegisHero {
                    visible: rootAegisBlock.type === "aegis" && rootAegisBlock.mode !== "minimal"
                    width: parent.width
                    theme: rootAegisBlock.theme
                    service: rootAegisBlock.service
                }

                Repeater {
                    model: rootAegisBlock.service ? rootAegisBlock.service.sections(rootAegisBlock.mode, rootAegisBlock.sections) : []

                    AegisSection {
                        required property var modelData

                        width: sectionLayout.width
                        theme: rootAegisBlock.theme
                        service: rootAegisBlock.service
                        section: modelData
                    }
                }
            }
        }
    }

    Component {
        id: copyFooterComponent

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "Copy all info:"
                color: rootAegisBlock.theme.modules.aegis.secondaryTextColor
                font.pixelSize: rootAegisBlock.theme.modules.aegis.metaPixelSize
            }

            Text {
                text: "text"
                color: rootAegisBlock.theme.modules.aegis.accentColor
                font.pixelSize: rootAegisBlock.theme.modules.aegis.metaPixelSize

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootAegisBlock.service.copyInfo("text")
                }
            }

            Text {
                text: "|"
                color: rootAegisBlock.theme.modules.aegis.secondaryTextColor
                font.pixelSize: rootAegisBlock.theme.modules.aegis.metaPixelSize
            }

            Text {
                text: "json"
                color: rootAegisBlock.theme.modules.aegis.accentColor
                font.pixelSize: rootAegisBlock.theme.modules.aegis.metaPixelSize

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootAegisBlock.service.copyInfo("json")
                }
            }
        }
    }

    Component {
        id: cpuComponent

        AegisCpuGraph {
            anchors.fill: parent
            theme: rootAegisBlock.theme
            service: rootAegisBlock.service
            config: rootAegisBlock.config
        }
    }

    Component {
        id: memoryPieComponent

        AegisPie {
            anchors.centerIn: parent
            theme: rootAegisBlock.theme
            config: rootAegisBlock.config
            usedLabel: "Used"
            freeLabel: "Free"
            totalLabel: "Total"
            usedBytes: rootAegisBlock.service ? Number(rootAegisBlock.service.data.memory.usedBytes || 0) : 0
            freeBytes: rootAegisBlock.service ? Number(rootAegisBlock.service.data.memory.availableBytes || 0) : 0
            totalBytes: rootAegisBlock.service ? Number(rootAegisBlock.service.data.memory.totalBytes || 0) : 0
        }
    }

    Component {
        id: diskPieComponent

        AegisPie {
            anchors.centerIn: parent
            theme: rootAegisBlock.theme
            config: rootAegisBlock.config
            usedLabel: "Used"
            freeLabel: "Free"
            totalLabel: "Total"
            usedBytes: diskValue("usedBytes")
            freeBytes: diskValue("freeBytes")
            totalBytes: diskValue("sizeBytes")

            function diskValue(key) {
                const disks = rootAegisBlock.service && Array.isArray(rootAegisBlock.service.data.physicalDisks) ? rootAegisBlock.service.data.physicalDisks : [];
                const requested = String(rootAegisBlock.config.disk || "");
                let disk = disks.length > 0 ? disks[0] : null;
                for (let index = 0; index < disks.length; index++) {
                    if (String(disks[index].name || "") === requested)
                        disk = disks[index];
                }
                return disk ? Number(disk[key] || 0) : 0;
            }
        }
    }
}

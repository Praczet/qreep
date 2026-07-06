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
    readonly property bool wideLayout: type === "aegis" && mode === "full" && String(config.layout || "") === "wide"

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
            return rootAegisBlock.wideLayout ? wideSectionsComponent : sectionsComponent;
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
        id: wideSectionsComponent

        Flickable {
            contentWidth: width
            contentHeight: wideLayoutColumn.implicitHeight
            clip: true

            Column {
                id: wideLayoutColumn

                width: parent.width
                spacing: rootAegisBlock.theme.modules.aegis.cardGap

                AegisHero {
                    width: parent.width
                    theme: rootAegisBlock.theme
                    service: rootAegisBlock.service
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: rootAegisBlock.theme.modules.aegis.borderColor
                }

                Row {
                    width: parent.width
                    spacing: rootAegisBlock.theme.modules.aegis.cardGap * 2

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        spacing: rootAegisBlock.theme.modules.aegis.cardGap

                        Repeater {
                            model: rootAegisBlock.sectionList(["system", "hyprland", "status", "network-info"])

                            AegisSection {
                                required property var modelData

                                width: parent.width
                                theme: rootAegisBlock.theme
                                service: rootAegisBlock.service
                                section: modelData
                            }
                        }
                    }

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        spacing: rootAegisBlock.theme.modules.aegis.cardGap

                        Repeater {
                            model: rootAegisBlock.sectionList(["hardware", "memory", "storage", "power"])

                            AegisSection {
                                required property var modelData

                                width: parent.width
                                theme: rootAegisBlock.theme
                                service: rootAegisBlock.service
                                section: modelData
                            }
                        }
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

    function sectionList(ids) {
        const source = rootAegisBlock.service ? rootAegisBlock.service.sections(rootAegisBlock.mode, ids) : [];
        const result = [];

        for (let idIndex = 0; idIndex < ids.length; idIndex++) {
            const id = ids[idIndex];
            for (let sectionIndex = 0; sectionIndex < source.length; sectionIndex++) {
                const section = source[sectionIndex];
                if (String(section.id || "") === id) {
                    result.push(section);
                    break;
                }
            }
        }

        return result;
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

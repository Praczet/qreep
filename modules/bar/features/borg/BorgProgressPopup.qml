import QtQuick
import Quickshell

PopupWindow {
    id: rootBorgProgressPopup

    required property QtObject theme
    required property QtObject service
    property Item anchorItem

    readonly property string stateClass: service.backupState === "success" ? "ok" : service.backupState === "error" || service.backupState === "failed" ? "error" : "warning"

    visible: rootBorgProgressPopup.service.backupPanelOpen && rootBorgProgressPopup.anchorItem !== null && rootBorgProgressPopup.anchorItem.visible
    color: "transparent"
    grabFocus: false
    implicitWidth: rootBorgProgressPopup.theme.modules.bar.borg.progressWidth
    implicitHeight: progressLayout.implicitHeight + rootBorgProgressPopup.theme.modules.bar.tooltip.verticalPadding * 2

    anchor {
        item: rootBorgProgressPopup.anchorItem
        rect.x: rootBorgProgressPopup.anchorItem ? rootBorgProgressPopup.anchorItem.width / 2 - rootBorgProgressPopup.width / 2 : 0
        rect.y: rootBorgProgressPopup.anchorItem ? rootBorgProgressPopup.anchorItem.height + rootBorgProgressPopup.theme.modules.bar.tooltip.offsetY : 0
    }

    Rectangle {
        id: progressBody

        anchors.fill: parent
        radius: rootBorgProgressPopup.theme.modules.bar.tooltip.radius
        color: rootBorgProgressPopup.theme.modules.bar.tooltip.backgroundColor
        border.width: rootBorgProgressPopup.theme.modules.bar.tooltip.borderWidth
        border.color: rootBorgProgressPopup.theme.modules.bar.borg.classColor(rootBorgProgressPopup.stateClass)

        Column {
            id: progressLayout

            anchors {
                fill: parent
                margins: rootBorgProgressPopup.theme.modules.bar.tooltip.padding
            }
            spacing: rootBorgProgressPopup.theme.modules.bar.borg.progressRowSpacing

            Row {
                width: parent.width
                spacing: rootBorgProgressPopup.theme.modules.bar.borg.tooltipHeroSpacing

                Text {
                    id: progressIcon

                    width: rootBorgProgressPopup.theme.modules.bar.borg.tooltipHeroIconWidth
                    height: rootBorgProgressPopup.theme.modules.bar.borg.tooltipHeroIconWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: iconForState(rootBorgProgressPopup.service.backupState)
                    color: rootBorgProgressPopup.theme.modules.bar.borg.classColor(rootBorgProgressPopup.stateClass)
                    font.family: rootBorgProgressPopup.theme.iconFontFamily
                    font.pixelSize: rootBorgProgressPopup.theme.modules.bar.borg.progressIconPixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    transformOrigin: Item.Center

                    SequentialAnimation {
                        running: rootBorgProgressPopup.service.backupState === "running" && rootBorgProgressPopup.visible
                        loops: Animation.Infinite
                        onRunningChanged: {
                            if (!running) {
                                progressIcon.scale = 1;
                                progressIcon.y = 0;
                            }
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: progressIcon
                                property: "scale"
                                from: 1
                                to: 1.13
                                duration: 520
                                easing.type: Easing.InOutCubic
                            }

                            NumberAnimation {
                                target: progressIcon
                                property: "y"
                                from: 0
                                to: -2
                                duration: 520
                                easing.type: Easing.InOutCubic
                            }
                        }

                        ParallelAnimation {
                            NumberAnimation {
                                target: progressIcon
                                property: "scale"
                                from: 1.13
                                to: 1
                                duration: 520
                                easing.type: Easing.InOutCubic
                            }

                            NumberAnimation {
                                target: progressIcon
                                property: "y"
                                from: -2
                                to: 0
                                duration: 520
                                easing.type: Easing.InOutCubic
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - rootBorgProgressPopup.theme.modules.bar.borg.tooltipHeroIconWidth - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: titleText()
                        color: rootBorgProgressPopup.theme.modules.bar.borg.tokenColor("{{on_surface}}")
                        font.pixelSize: rootBorgProgressPopup.theme.modules.bar.borg.progressTitlePixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: statusText()
                        color: rootBorgProgressPopup.theme.modules.bar.borg.tokenColor("{{on_surface_variant}}")
                        font.pixelSize: rootBorgProgressPopup.theme.modules.bar.borg.progressMetaPixelSize
                        elide: Text.ElideRight
                    }
                }
            }

            Repeater {
                model: progressRows()

                delegate: Row {
                    required property var modelData

                    width: progressLayout.width
                    spacing: rootBorgProgressPopup.theme.modules.bar.borg.progressColumnGap
                    visible: String(modelData.value || "").length > 0

                    Text {
                        width: rootBorgProgressPopup.theme.modules.bar.borg.progressLabelWidth
                        text: String(parent.modelData.label || "")
                        color: rootBorgProgressPopup.theme.modules.bar.borg.tokenColor("{{on_surface_variant}}")
                        font.pixelSize: rootBorgProgressPopup.theme.modules.bar.borg.progressBodyPixelSize
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        width: parent.width - rootBorgProgressPopup.theme.modules.bar.borg.progressLabelWidth - parent.spacing
                        text: String(parent.modelData.value || "")
                        color: rootBorgProgressPopup.theme.modules.bar.borg.tokenColor(parent.modelData.color || "{{on_surface}}")
                        font.pixelSize: rootBorgProgressPopup.theme.modules.bar.borg.progressBodyPixelSize
                        elide: Text.ElideMiddle
                    }
                }
            }
        }
    }

    function titleText() {
        switch (rootBorgProgressPopup.service.backupState) {
        case "success":
            return "Borg backup complete";
        case "error":
        case "failed":
            return "Borg backup failed";
        case "running":
            return "Borg backup running";
        default:
            return "Borg backup";
        }
    }

    function statusText() {
        const profile = rootBorgProgressPopup.service.backupProfile.length > 0 ? rootBorgProgressPopup.service.backupProfile : "unknown";
        const archive = rootBorgProgressPopup.service.backupArchive.length > 0 ? rootBorgProgressPopup.service.backupArchive : "no archive yet";

        return profile + " - " + archive;
    }

    function progressRows() {
        return [
            { label: "State", value: rootBorgProgressPopup.service.backupState },
            { label: "Message", value: rootBorgProgressPopup.service.backupMessage },
            { label: "Files", value: rootBorgProgressPopup.service.backupFiles > 0 ? String(rootBorgProgressPopup.service.backupFiles) : "" },
            { label: "Current", value: shortPath(rootBorgProgressPopup.service.backupCurrentPath) },
            { label: "Last", value: shortPath(rootBorgProgressPopup.service.backupLastFilePath) },
            { label: "Original", value: formatBytes(rootBorgProgressPopup.service.backupOriginalSize) },
            { label: "Deduped", value: formatBytes(rootBorgProgressPopup.service.backupDeduplicatedSize) },
            { label: "Exit", value: rootBorgProgressPopup.service.backupRc >= 0 ? String(rootBorgProgressPopup.service.backupRc) : "", color: rootBorgProgressPopup.stateClass === "error" ? "{{error}}" : "{{success}}" }
        ];
    }

    function iconForState(state) {
        switch (state) {
        case "success":
            return "󰄬";
        case "error":
        case "failed":
            return "󰅚";
        case "running":
            return "";
        default:
            return "";
        }
    }

    function shortPath(path) {
        const value = String(path || "");
        const limit = rootBorgProgressPopup.theme.modules.bar.borg.progressMaxPathLength;

        if (value.length <= limit)
            return value;

        return "..." + value.slice(value.length - limit);
    }

    function formatBytes(value) {
        const bytes = Number(value || 0);

        if (!Number.isFinite(bytes) || bytes <= 0)
            return "";

        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let size = bytes;
        let unitIndex = 0;

        while (size >= 1024 && unitIndex < units.length - 1) {
            size = size / 1024;
            unitIndex++;
        }

        return size.toFixed(unitIndex === 0 ? 0 : 1) + " " + units[unitIndex];
    }
}

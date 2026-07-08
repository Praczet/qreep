import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../bloom" as BloomModule

Item {
    id: rootBloomBlock

    required property QtObject theme
    property var config: ({})
    property string basePalette: ""
    property string bloomGeneratedAt: ""
    property string bloomProfile: ""
    property var paletteSwatches: []
    property string error: ""

    readonly property string cacheDir: resolvePath(stringValue(config.cacheDir, "~/.cache/unclaimed-bloom"))
    readonly property string dataDir: resolvePath(stringValue(config.dataDir, "~/.config/unclaimed-bloom"))
    readonly property string activeProfile: bloomStatus.profile.length > 0 ? bloomStatus.profile : stringValue(config.profile, "")
    readonly property string resolvedBloomProfile: bloomProfile.length > 0 ? bloomProfile : activeProfile
    readonly property string bloomPath: resolvedBloomProfile.length > 0 ? cacheDir + "/blooms/" + resolvedBloomProfile + ".json" : ""
    readonly property string profilePath: activeProfile.length > 0 ? dataDir + "/profiles/" + activeProfile + ".json" : ""
    readonly property string bloomProfilePath: resolvedBloomProfile.length > 0 && resolvedBloomProfile !== activeProfile ? dataDir + "/profiles/" + resolvedBloomProfile + ".json" : ""
    readonly property string plantedAt: bloomStatus.stages.plant.updatedAt || bloomStatus.updatedAt || bloomGeneratedAt
    readonly property string plantedText: formatDateTime(plantedAt)
    readonly property int swatchCount: numberValue(config.swatchCount, 8)

    implicitHeight: content.implicitHeight

    BloomModule.BloomStatusService {
        id: bloomStatus

        cacheDir: rootBloomBlock.cacheDir
    }

    FileView {
        id: bloomFile

        path: rootBloomBlock.bloomPath
        preload: rootBloomBlock.bloomPath.length > 0
        watchChanges: true

        onLoaded: rootBloomBlock.loadBloom()
        onTextChanged: rootBloomBlock.loadBloom()
        onLoadFailed: error => {
            rootBloomBlock.paletteSwatches = [];
            rootBloomBlock.error = "Bloom load failed: " + FileViewError.toString(error);
        }
    }

    FileView {
        id: profileFile

        path: rootBloomBlock.profilePath
        preload: rootBloomBlock.profilePath.length > 0
        watchChanges: true

        onLoaded: rootBloomBlock.loadProfile()
        onTextChanged: rootBloomBlock.loadProfile()
    }

    FileView {
        id: bloomProfileFile

        path: rootBloomBlock.bloomProfilePath
        preload: rootBloomBlock.bloomProfilePath.length > 0
        watchChanges: true

        onLoaded: rootBloomBlock.loadBloomProfile()
        onTextChanged: rootBloomBlock.loadBloomProfile()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 112
                Layout.preferredHeight: 76
                radius: 10
                color: rootBloomBlock.theme.modules.dashboard.containerColor
                clip: true

                Image {
                    anchors.fill: parent
                    source: bloomStatus.wallpaper
                    visible: bloomStatus.wallpaper.length > 0
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }

                Text {
                    anchors.centerIn: parent
                    visible: bloomStatus.wallpaper.length === 0
                    text: "no wallpaper"
                    color: rootBloomBlock.theme.modules.dashboard.secondaryTextColor
                    font.pixelSize: rootBloomBlock.theme.modules.dashboard.metaPixelSize
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: "Bloom"
                    color: rootBloomBlock.theme.modules.dashboard.primaryTextColor
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: rootBloomBlock.plantedText
                    color: rootBloomBlock.theme.modules.dashboard.primaryTextColor
                    font.pixelSize: rootBloomBlock.theme.modules.dashboard.bodyPixelSize
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: bloomStatus.wallpaper.length > 0 ? fileName(bloomStatus.wallpaper) : "Wallpaper unknown"
                    color: rootBloomBlock.theme.modules.dashboard.secondaryTextColor
                    font.pixelSize: rootBloomBlock.theme.modules.dashboard.metaPixelSize
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideMiddle
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 14
            rowSpacing: 7

            Text {
                text: "Profile"
                color: rootBloomBlock.theme.modules.dashboard.secondaryTextColor
                font.pixelSize: rootBloomBlock.theme.modules.dashboard.metaPixelSize
                Layout.preferredWidth: 78
            }

            Text {
                Layout.fillWidth: true
                text: rootBloomBlock.activeProfile.length > 0 ? rootBloomBlock.activeProfile : "Unknown"
                color: rootBloomBlock.theme.modules.dashboard.primaryTextColor
                font.pixelSize: rootBloomBlock.theme.modules.dashboard.bodyPixelSize
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            Text {
                text: "Base"
                color: rootBloomBlock.theme.modules.dashboard.secondaryTextColor
                font.pixelSize: rootBloomBlock.theme.modules.dashboard.metaPixelSize
                Layout.preferredWidth: 78
            }

            Text {
                Layout.fillWidth: true
                text: rootBloomBlock.basePalette.length > 0 ? rootBloomBlock.basePalette : "Unknown"
                color: rootBloomBlock.theme.modules.dashboard.primaryTextColor
                font.pixelSize: rootBloomBlock.theme.modules.dashboard.bodyPixelSize
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: rootBloomBlock.paletteSwatches

                Rectangle {
                    required property string modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    radius: 6
                    color: modelData
                    border.width: 1
                    border.color: Qt.rgba(rootBloomBlock.theme.modules.dashboard.borderColor.r, rootBloomBlock.theme.modules.dashboard.borderColor.g, rootBloomBlock.theme.modules.dashboard.borderColor.b, 0.55)
                }
            }
        }

        Text {
            visible: rootBloomBlock.error.length > 0
            Layout.fillWidth: true
            text: rootBloomBlock.error
            color: rootBloomBlock.theme.modules.dashboard.errorColor
            font.pixelSize: rootBloomBlock.theme.modules.dashboard.metaPixelSize
            elide: Text.ElideRight
        }
    }

    function loadBloom() {
        const contents = bloomFile.text().trim();

        if (contents.length === 0)
            return;

        try {
            const payload = JSON.parse(contents);
            bloomGeneratedAt = stringValue(payload.generatedAt, "");
            paletteSwatches = pickSwatches(payload.colors || ({}), swatchCount);
            error = "";
        } catch (loadError) {
            paletteSwatches = [];
            error = "Bloom JSON error: " + loadError;
        }
    }

    function loadProfile() {
        const contents = profileFile.text().trim();

        if (contents.length === 0)
            return;

        try {
            const payload = JSON.parse(contents);

            if (payload.type === "composition") {
                bloomProfile = stringValue(payload.currentProfile, firstCompositionProfile(payload));
                return;
            }

            bloomProfile = activeProfile;
            basePalette = stringValue(payload.basePalette, "");
        } catch (loadError) {
            basePalette = "";
        }
    }

    function loadBloomProfile() {
        const contents = bloomProfileFile.text().trim();

        if (contents.length === 0)
            return;

        try {
            const payload = JSON.parse(contents);
            basePalette = stringValue(payload.basePalette, "");
        } catch (loadError) {
            basePalette = "";
        }
    }

    function firstCompositionProfile(payload) {
        if (!payload || !Array.isArray(payload.runs) || payload.runs.length === 0)
            return "";

        for (const run of payload.runs) {
            const profile = stringValue(run && run.profile, "");

            if (profile.length > 0 && profile !== "daily-gtk")
                return profile;
        }

        return stringValue(payload.runs[0] && payload.runs[0].profile, "");
    }

    function pickSwatches(groups, count) {
        const values = [];

        for (const group of Object.values(groups)) {
            if (typeof group === "string" && isHexColor(group)) {
                values.push(group);
                continue;
            }

            if (!group || typeof group !== "object")
                continue;

            for (const value of Object.values(group)) {
                if (typeof value === "string" && isHexColor(value))
                    values.push(value);
            }
        }

        if (values.length <= count)
            return values;

        const step = Math.max(1, Math.floor(values.length / count));
        const picked = [];

        for (let index = 0; index < values.length && picked.length < count; index += step)
            picked.push(values[index]);

        return picked;
    }

    function isHexColor(value) {
        return /^#[0-9a-fA-F]{6}$/.test(String(value || ""));
    }

    function formatDateTime(value) {
        const text = String(value || "");

        if (text.length === 0)
            return "Never planted";

        const date = new Date(text);

        if (Number.isNaN(date.getTime()))
            return text;

        return Qt.formatDateTime(date, "ddd, dd MMM yyyy HH:mm");
    }

    function fileName(path) {
        const text = String(path || "");
        const index = text.lastIndexOf("/");

        return index >= 0 ? text.slice(index + 1) : text;
    }

    function resolvePath(path) {
        const text = String(path || "");

        if (text === "~")
            return Quickshell.env("HOME") || text;

        if (text.indexOf("~/") === 0)
            return (Quickshell.env("HOME") || "") + text.slice(1);

        return text;
    }

    function stringValue(value, fallback) {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    function numberValue(value, fallback) {
        const numeric = Number(value);
        return Number.isFinite(numeric) ? numeric : fallback;
    }
}

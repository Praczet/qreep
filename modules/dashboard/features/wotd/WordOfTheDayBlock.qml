import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: rootWordOfTheDayBlock

    required property QtObject theme
    property var config: ({})

    property var card: null
    property string error: ""

    readonly property string cardPath: resolvePath(stringValue(config.cardPath, stringValue(config.path, "~/.cache/mdj/card.json")))
    readonly property string variant: stringValue(config.variant, "card")
    readonly property int maxMeanings: numberValue(config.maxMeanings, variant === "compact" ? 1 : 3)
    readonly property int maxTranslations: numberValue(config.maxTranslations, variant === "compact" ? 1 : 3)
    readonly property int maxWidth: numberValue(config.maxWidth, Math.max(100, width))
    readonly property int minHeight: numberValue(config.minHeight, 0)
    readonly property int contentPadding: numberValue(config.padding, 0)
    readonly property int contentSpacing: numberValue(config.spacing, variant === "compact" ? 8 : 12)
    readonly property int contentWidth: Math.max(1, Math.min(width, maxWidth) - contentPadding * 2)

    readonly property bool showTitle: boolValue(config.showTitle, variant !== "compact")
    readonly property bool showDate: boolValue(config.showDate, false)
    readonly property bool showLang: boolValue(config.showLang, variant === "card")
    readonly property bool showWord: boolValue(config.showWord, true)
    readonly property bool showPronunciation: boolValue(config.showPronunciation, true)
    readonly property bool showPartOfSpeech: boolValue(config.showPartOfSpeech, true)
    readonly property bool showDefinition: boolValue(config.showDefinition, true)
    readonly property bool showMeanings: boolValue(config.showMeanings, variant !== "definition-only")
    readonly property bool showTranslations: boolValue(config.showTranslations, true)
    readonly property bool showTranslation: boolValue(config.showTranslation, true)

    readonly property string titleText: stringValue(config.title, stringValue(config.titleOverride, card ? card.title || "" : ""))
    readonly property string langText: card ? formatLang(card.lang, card.trans_lang) : ""
    readonly property string partOfSpeechText: card && card.part_of_speech ? String(card.part_of_speech).toUpperCase() : ""
    readonly property var meanings: card && Array.isArray(card.meanings) ? card.meanings.slice(0, maxMeanings) : []
    readonly property var translations: card && Array.isArray(card.translations) ? card.translations.slice(0, maxTranslations) : []

    implicitWidth: numberValue(config.width, 450)
    implicitHeight: numberValue(config.height, Math.max(minHeight, content.implicitHeight))
    clip: true

    readonly property FileView cardFile: FileView {
        path: rootWordOfTheDayBlock.cardPath
        preload: true
        watchChanges: true

        onLoaded: rootWordOfTheDayBlock.loadCard()
        onTextChanged: rootWordOfTheDayBlock.loadCard()
        onLoadFailed: error => {
            rootWordOfTheDayBlock.card = null;
            rootWordOfTheDayBlock.error = "WOTD load failed: " + FileViewError.toString(error);
        }
    }

    ColumnLayout {
        id: content

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            margins: rootWordOfTheDayBlock.contentPadding
        }
        width: rootWordOfTheDayBlock.contentWidth
        spacing: rootWordOfTheDayBlock.contentSpacing

        Text {
            visible: rootWordOfTheDayBlock.card === null
            Layout.fillWidth: true
            text: rootWordOfTheDayBlock.error || "No word of the day."
            color: rootWordOfTheDayBlock.theme.secondaryText
            font.pixelSize: rootWordOfTheDayBlock.theme.modules.dashboard.bodyPixelSize
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            visible: rootWordOfTheDayBlock.card !== null && (rootWordOfTheDayBlock.showTitle || rootWordOfTheDayBlock.showDate || rootWordOfTheDayBlock.showLang)
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    visible: rootWordOfTheDayBlock.showTitle && rootWordOfTheDayBlock.titleText.length > 0
                    Layout.fillWidth: true
                    text: rootWordOfTheDayBlock.titleText
                    color: rootWordOfTheDayBlock.theme.secondaryText
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    visible: rootWordOfTheDayBlock.showDate && rootWordOfTheDayBlock.card && rootWordOfTheDayBlock.card.date
                    Layout.fillWidth: true
                    text: rootWordOfTheDayBlock.card ? String(rootWordOfTheDayBlock.card.date || "") : ""
                    color: rootWordOfTheDayBlock.theme.secondaryText
                    opacity: 0.6
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: rootWordOfTheDayBlock.showLang && rootWordOfTheDayBlock.langText.length > 0
                text: rootWordOfTheDayBlock.langText
                color: rootWordOfTheDayBlock.theme.secondaryText
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
            }
        }

        Text {
            visible: rootWordOfTheDayBlock.card !== null && rootWordOfTheDayBlock.showWord
            Layout.fillWidth: true
            text: rootWordOfTheDayBlock.card ? String(rootWordOfTheDayBlock.card.word || "") : ""
            color: rootWordOfTheDayBlock.theme.primaryText
            font.pixelSize: numberValue(rootWordOfTheDayBlock.config.wordPixelSize, rootWordOfTheDayBlock.variant === "compact" ? 36 : 38)
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            visible: rootWordOfTheDayBlock.card !== null && rootWordOfTheDayBlock.showPronunciation && rootWordOfTheDayBlock.card && rootWordOfTheDayBlock.card.pronunciation
            Layout.fillWidth: true
            text: rootWordOfTheDayBlock.card ? String(rootWordOfTheDayBlock.card.pronunciation || "") : ""
            color: rootWordOfTheDayBlock.theme.secondaryText
            opacity: 0.7
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Text {
            visible: rootWordOfTheDayBlock.card !== null && rootWordOfTheDayBlock.showPartOfSpeech && rootWordOfTheDayBlock.partOfSpeechText.length > 0
            Layout.fillWidth: true
            text: rootWordOfTheDayBlock.variant === "card" ? "[" + rootWordOfTheDayBlock.partOfSpeechText + "]" : rootWordOfTheDayBlock.partOfSpeechText
            color: rootWordOfTheDayBlock.theme.secondaryText
            opacity: 0.45
            font.pixelSize: 13
            font.italic: true
            horizontalAlignment: rootWordOfTheDayBlock.variant === "compact" ? Text.AlignLeft : Text.AlignHCenter
        }

        Text {
            visible: rootWordOfTheDayBlock.card !== null && rootWordOfTheDayBlock.showDefinition && rootWordOfTheDayBlock.card && rootWordOfTheDayBlock.card.definition
            Layout.fillWidth: true
            text: rootWordOfTheDayBlock.card ? String(rootWordOfTheDayBlock.card.definition || "") : ""
            color: rootWordOfTheDayBlock.theme.primaryText
            font.pixelSize: 14
            wrapMode: Text.Wrap
        }

        ColumnLayout {
            visible: rootWordOfTheDayBlock.card !== null && rootWordOfTheDayBlock.showMeanings && rootWordOfTheDayBlock.meanings.length > 0
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: rootWordOfTheDayBlock.meanings

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 8
                    opacity: 0.55

                    Text {
                        text: String(parent.modelData.index || "") + "."
                        color: rootWordOfTheDayBlock.theme.secondaryText
                        font.pixelSize: 14
                        Layout.preferredWidth: 36
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: String(parent.modelData.text || "")
                        color: rootWordOfTheDayBlock.theme.secondaryText
                        font.pixelSize: 14
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        ColumnLayout {
            visible: rootWordOfTheDayBlock.card !== null && rootWordOfTheDayBlock.showTranslations && rootWordOfTheDayBlock.translations.length > 0 && rootWordOfTheDayBlock.variant !== "definition-only"
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: rootWordOfTheDayBlock.translations

                Text {
                    required property string modelData

                    Layout.fillWidth: true
                    text: "-> " + modelData
                    color: rootWordOfTheDayBlock.theme.secondaryText
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                }
            }
        }

        Text {
            visible: rootWordOfTheDayBlock.card !== null && rootWordOfTheDayBlock.variant === "definition-only" && rootWordOfTheDayBlock.showTranslation && rootWordOfTheDayBlock.translations.length > 0
            Layout.fillWidth: true
            text: rootWordOfTheDayBlock.translations.length > 0 ? "-> " + rootWordOfTheDayBlock.translations[0] : ""
            color: rootWordOfTheDayBlock.theme.secondaryText
            font.pixelSize: 13
            wrapMode: Text.Wrap
        }
    }

    function loadCard() {
        const contents = cardFile.text();

        if (contents.length === 0) {
            card = null;
            error = "No word of the day.";
            return;
        }

        try {
            const document = JSON.parse(contents);

            if (!document || document.kind !== "wotd-card")
                throw new Error("Invalid WOTD card");

            card = document;
            error = "";
        } catch (loadError) {
            card = null;
            error = "WOTD JSON error: " + loadError;
        }
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
        const parsed = Number(value);
        return Number.isFinite(parsed) ? Math.max(0, Math.floor(parsed)) : fallback;
    }

    function boolValue(value, fallback) {
        return typeof value === "boolean" ? value : fallback;
    }

    function formatLang(lang, transLang) {
        const left = String(lang || "");
        const right = String(transLang || "");

        if (left.length > 0 && right.length > 0)
            return left.toUpperCase() + " -> " + right.toUpperCase();

        return left.toUpperCase();
    }
}

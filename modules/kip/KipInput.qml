import QtQuick

// The input box: command icon, flag chips, the command-token highlight, the
// text field and the Enter hint. The panel owns geometry and the morph
// (x/y/size/radius/opacity); contentReveal fades the contents in late.
// The text field has focus from frame one, so typing during the opening
// animation is kept.
Rectangle {
    id: rootKipInput

    required property QtObject kipTheme
    property string iconFontFamily: ""
    property var parsed: ({
            mode: "idle",
            command: null,
            token: "",
            argument: "",
            flagRanges: []
        })
    property string enterLabel: ""
    property real contentReveal: 1
    readonly property alias field: promptInput

    signal edited
    signal keyPressed(var event)

    color: kipTheme.inputColor
    border.width: 1
    border.color: promptInput.activeFocus ? kipTheme.focusBorderColor : kipTheme.borderColor
    clip: true

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: promptInput.forceActiveFocus()
    }

    Text {
        id: inputIcon

        anchors.verticalCenter: parent.verticalCenter
        x: rootKipInput.kipTheme.inputPadding
        width: rootKipInput.kipTheme.inputIconWidth
        opacity: rootKipInput.contentReveal
        text: rootKipInput.parsed.mode === "ready" && rootKipInput.parsed.command ? rootKipInput.parsed.command.icon : (rootKipInput.parsed.mode === "plain" ? "󰀻" : rootKipInput.kipTheme.kipIcon)
        color: rootKipInput.kipTheme.accentColor
        font.family: rootKipInput.iconFontFamily
        font.pixelSize: rootKipInput.kipTheme.iconPixelSize
    }

    // Flag chips, e.g. "--f=/". Red outline for flags the command does not know.
    Repeater {
        model: rootKipInput.parsed.flagRanges

        Rectangle {
            required property var modelData

            readonly property real startX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(modelData.start).x : 0
            readonly property real endX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(Math.min(promptInput.text.length, modelData.end)).x : 0

            anchors.verticalCenter: parent.verticalCenter
            x: promptInput.x + startX - 3
            width: endX - startX + 6
            height: promptInput.height + 4
            radius: rootKipInput.kipTheme.chipRadius
            color: modelData.known ? rootKipInput.kipTheme.commandHighlightColor : "transparent"
            border.width: 1
            border.color: modelData.known ? rootKipInput.kipTheme.focusBorderColor : rootKipInput.kipTheme.errorColor
            opacity: rootKipInput.contentReveal
        }
    }

    // Highlight behind the recognized command token, e.g. "/ask".
    Rectangle {
        readonly property bool active: rootKipInput.parsed.mode === "ready" || (rootKipInput.parsed.mode === "candidate" && rootKipInput.parsed.command !== null)
        readonly property real startX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(0).x : 0
        readonly property real endX: promptInput.text.length >= 0 ? promptInput.positionToRectangle(Math.min(promptInput.text.length, rootKipInput.parsed.token.length + 1)).x : 0

        anchors.verticalCenter: parent.verticalCenter
        x: promptInput.x + startX - 5
        width: endX - startX + 10
        height: promptInput.height + 6
        radius: rootKipInput.kipTheme.chipRadius
        color: rootKipInput.kipTheme.commandHighlightColor
        border.width: 1
        border.color: rootKipInput.parsed.mode === "ready" ? rootKipInput.kipTheme.focusBorderColor : "transparent"
        opacity: active ? rootKipInput.contentReveal : 0
        visible: opacity > 0.01

        Behavior on opacity {
            enabled: !rootKipInput.kipTheme.reducedMotion

            NumberAnimation {
                duration: rootKipInput.kipTheme.contentFadeDuration
            }
        }
    }

    TextInput {
        id: promptInput

        anchors.verticalCenter: parent.verticalCenter
        x: inputIcon.x + inputIcon.width + 6
        width: parent.width - x - enterHint.width - rootKipInput.kipTheme.inputPadding * 2
        // Focused from frame one; only its opacity waits for the morph.
        opacity: rootKipInput.contentReveal
        color: rootKipInput.kipTheme.primaryTextColor
        selectionColor: rootKipInput.kipTheme.selectedRowColor
        selectedTextColor: rootKipInput.kipTheme.primaryTextColor
        font.pixelSize: rootKipInput.kipTheme.inputPixelSize
        clip: true
        focus: true

        onTextChanged: rootKipInput.edited()

        Keys.onPressed: event => rootKipInput.keyPressed(event)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: promptInput.text.length === 0 || (rootKipInput.parsed.mode === "ready" && rootKipInput.parsed.argument.length === 0 && rootKipInput.parsed.command && rootKipInput.parsed.command.takesArgument)
            x: promptInput.text.length === 0 ? 0 : promptInput.contentWidth + 2
            text: promptInput.text.length === 0 ? "Launch an app, or type / for commands" : (rootKipInput.parsed.command ? (promptInput.text.endsWith(" ") ? "" : " ") + rootKipInput.parsed.command.placeholder : "")
            color: rootKipInput.kipTheme.secondaryTextColor
            font: promptInput.font
        }
    }

    Rectangle {
        id: enterHint

        readonly property string label: rootKipInput.enterLabel

        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - rootKipInput.kipTheme.inputPadding
        width: label.length > 0 ? enterText.implicitWidth + 14 : 0
        height: enterText.implicitHeight + 6
        radius: rootKipInput.kipTheme.chipRadius
        color: rootKipInput.kipTheme.chipColor
        opacity: label.length > 0 ? rootKipInput.contentReveal : 0
        visible: opacity > 0.01

        Text {
            id: enterText

            anchors.centerIn: parent
            text: "↵ " + enterHint.label
            color: rootKipInput.kipTheme.accentColor
            font.pixelSize: rootKipInput.kipTheme.metaPixelSize + 1
        }
    }
}

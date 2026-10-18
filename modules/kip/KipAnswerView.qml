import QtQuick

// One growing answer, never a pile of bubbles. A single read-only TextEdit so
// a selection can span the whole answer. It follows the stream only while the
// reader is at the bottom. Also shows static Markdown (/help, /tldr, /run
// preview, ...) when showsDoc is set.
Flickable {
    id: rootKipAnswerView

    required property QtObject kipTheme
    required property QtObject service
    property bool showsDoc: false
    property string docMarkdown: ""
    property real maxHeight: 400

    property bool follow: true
    property bool autoScrolling: false
    // Rich text, rebuilt at most every answerRenderInterval while streaming so
    // the document is not re-parsed per token.
    property var rendered: ({
            html: "",
            codeBlocks: []
        })
    readonly property string selectedText: answerText.selectedText
    readonly property bool atEnd: contentHeight <= height || contentY >= contentHeight - height - 8

    // A code block's Copy link was clicked.
    signal copyCodeRequested(string code)
    // Esc/Tab: back to the prompt without closing.
    signal focusReturned
    // Enter: what Enter in the prompt would do.
    signal submitRequested
    // Typing while the answer has focus belongs in the prompt.
    signal typed(string text)

    height: Math.min(answerText.implicitHeight, maxHeight)
    contentHeight: answerText.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    // Only the reader scrolling decides whether to follow; layout and
    // re-renders moving contentY must not switch it off.
    onContentYChanged: {
        if (!autoScrolling && (moving || dragging))
            follow = atEnd;
    }
    onMovementEnded: follow = atEnd
    onContentHeightChanged: scrollToEndIfFollowing()
    onHeightChanged: scrollToEndIfFollowing()

    KipMarkdown {
        id: markdown

        kipTheme: rootKipAnswerView.kipTheme
    }

    Timer {
        id: renderTimer

        interval: rootKipAnswerView.kipTheme.answerRenderInterval
        repeat: false
        onTriggered: rootKipAnswerView.render()
    }

    Connections {
        target: rootKipAnswerView.service

        function onAnswerChanged() {
            // Throttle, not debounce: a steady stream still repaints.
            if (rootKipAnswerView.service.answer.length === 0)
                rootKipAnswerView.render();
            else if (!renderTimer.running)
                renderTimer.start();
        }

        function onStatusChanged() {
            if (!rootKipAnswerView.service.busy)
                rootKipAnswerView.render();
        }
    }

    function render() {
        renderTimer.stop();
        const source = showsDoc ? docMarkdown : service.citedAnswer(service.answer);

        rendered = source.length > 0 ? markdown.toRich(source) : {
            html: "",
            codeBlocks: []
        };
    }

    function toPlain(text) {
        return markdown.toPlain(text);
    }

    function scrollToEndIfFollowing() {
        if (!follow || contentHeight <= height)
            return;
        autoScrolling = true;
        contentY = contentHeight - height;
        autoScrolling = false;
    }

    function jumpToEnd() {
        follow = true;
        scrollToEndIfFollowing();
    }

    function openLink(link) {
        const copy = /^kip-copy:(\d+)$/.exec(link);

        if (copy) {
            const code = rendered.codeBlocks[Number(copy[1])];

            if (code !== undefined)
                copyCodeRequested(code);
            return;
        }

        // Only web links leave KIP; anything else in model output is ignored.
        if (/^https?:\/\//.test(link))
            Qt.openUrlExternally(link);
    }

    // Keys while the answer has focus (after a mouse selection). Copy and
    // select-all stay native; typing goes back to the prompt.
    function handleKey(event) {
        const modifiers = event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);

        if (modifiers !== 0)
            return;

        switch (event.key) {
        case Qt.Key_Escape:
        case Qt.Key_Tab:
            event.accepted = true;
            answerText.deselect();
            focusReturned();
            return;
        case Qt.Key_Up:
        case Qt.Key_Down:
        case Qt.Key_PageUp:
        case Qt.Key_PageDown:
            {
                event.accepted = true;
                const step = (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) ? height * 0.9 : 40;
                const direction = (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) ? -1 : 1;

                contentY = Math.max(0, Math.min(contentHeight - height, contentY + step * direction));
                follow = atEnd;
                return;
            }
        case Qt.Key_Return:
        case Qt.Key_Enter:
            event.accepted = true;
            submitRequested();
            return;
        }

        if (event.text.length > 0 && event.text.charCodeAt(0) >= 32) {
            event.accepted = true;
            typed(event.text);
        }
    }

    // "There is more below": shown whenever the end is out of view.
    Rectangle {
        parent: rootKipAnswerView
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
        width: moreLabel.implicitWidth + 14
        height: moreLabel.implicitHeight + 6
        radius: rootKipAnswerView.kipTheme.chipRadius
        color: rootKipAnswerView.kipTheme.chipColor
        border.width: 1
        border.color: rootKipAnswerView.service.busy ? rootKipAnswerView.kipTheme.focusBorderColor : rootKipAnswerView.kipTheme.borderColor
        visible: !rootKipAnswerView.atEnd
        z: 2

        Text {
            id: moreLabel

            anchors.centerIn: parent
            text: rootKipAnswerView.service.busy && !rootKipAnswerView.showsDoc ? "↓ more arriving" : "↓ more"
            color: rootKipAnswerView.kipTheme.accentColor
            font.pixelSize: rootKipAnswerView.kipTheme.metaPixelSize + 1
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: rootKipAnswerView.jumpToEnd()
        }
    }

    TextEdit {
        id: answerText

        width: rootKipAnswerView.width
        text: rootKipAnswerView.rendered.html
        textFormat: TextEdit.RichText
        readOnly: true
        selectByMouse: true
        persistentSelection: true
        wrapMode: TextEdit.Wrap
        color: rootKipAnswerView.kipTheme.primaryTextColor
        selectionColor: rootKipAnswerView.kipTheme.selectedRowColor
        selectedTextColor: rootKipAnswerView.kipTheme.primaryTextColor
        font.pixelSize: rootKipAnswerView.kipTheme.answerPixelSize

        onLinkActivated: link => rootKipAnswerView.openLink(link)
        Keys.onPressed: event => rootKipAnswerView.handleKey(event)

        HoverHandler {
            cursorShape: answerText.hoveredLink.length > 0 ? Qt.PointingHandCursor : Qt.IBeamCursor
        }
    }
}

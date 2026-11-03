import QtQuick

// Reads one note. Plain text only, so a note cannot pull in an image or a link.
Item {
    id: rootFastPasswordNoteView

    required property QtObject theme
    required property QtObject service

    readonly property QtObject ft: theme.modules.fastPassword

    // Walked away with a secret on screen.
    signal idleTimeout

    onVisibleChanged: {
        if (visible) {
            noteText.forceActiveFocus();
            idleTimer.restart();
        } else {
            idleTimer.stop();
        }
    }

    Timer {
        id: idleTimer

        interval: rootFastPasswordNoteView.ft.noteIdleMilliseconds
        repeat: false
        onTriggered: rootFastPasswordNoteView.idleTimeout()
    }

    HoverHandler {
        onPointChanged: idleTimer.restart()
    }

    Rectangle {
        anchors.fill: parent
        radius: rootFastPasswordNoteView.ft.controlRadius
        color: rootFastPasswordNoteView.ft.controlColor
        border.width: 1
        border.color: rootFastPasswordNoteView.ft.borderColor
    }

    Flickable {
        id: view

        anchors.fill: parent
        anchors.margins: rootFastPasswordNoteView.ft.searchPadding
        contentWidth: width
        contentHeight: noteText.contentHeight
        // Dragging selects text here, so only the wheel scrolls.
        interactive: false
        clip: true

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                idleTimer.restart();
                view.contentY = Math.max(0, Math.min(view.contentHeight - view.height, view.contentY - event.angleDelta.y));
            }
        }

        TextEdit {
            id: noteText

            width: view.width
            text: rootFastPasswordNoteView.service.noteText
            textFormat: TextEdit.PlainText
            readOnly: true
            selectByMouse: true
            selectByKeyboard: true
            cursorVisible: activeFocus
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            color: rootFastPasswordNoteView.ft.primaryTextColor
            selectionColor: rootFastPasswordNoteView.ft.accentColor
            selectedTextColor: rootFastPasswordNoteView.ft.panelColor
            font.family: rootFastPasswordNoteView.ft.noteFontFamily
            font.pixelSize: rootFastPasswordNoteView.ft.bodyPixelSize

            onCursorRectangleChanged: {
                if (cursorRectangle.y < view.contentY)
                    view.contentY = cursorRectangle.y;
                else if (cursorRectangle.y + cursorRectangle.height > view.contentY + view.height)
                    view.contentY = cursorRectangle.y + cursorRectangle.height - view.height;
            }

            Keys.onPressed: event => {
                idleTimer.restart();
                // Not Qt's own copy: that one has no sensitive hint, and clipvault would keep it.
                if (event.matches(StandardKey.Copy)) {
                    rootFastPasswordNoteView.service.copyNoteSelection(selectedText);
                    event.accepted = true;
                } else if (event.matches(StandardKey.SelectAll)) {
                    selectAll();
                    event.accepted = true;
                }
            }
        }
    }
}

import QtQuick

// Ranked note hits / answer sources. Folder and basename are styled apart so
// the eye finds the file first and the path second.
ListView {
    id: rootKipResultList

    required property QtObject kipTheme
    required property var results
    property bool compact: false

    signal activated(int index)

    model: results
    clip: true
    spacing: kipTheme.rowGap
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    implicitHeight: contentHeight

    onCurrentIndexChanged: {
        if (currentIndex >= 0)
            positionViewAtIndex(currentIndex, ListView.Contain);
    }

    delegate: Rectangle {
        id: resultRow

        required property var modelData
        required property int index

        readonly property bool selected: index === rootKipResultList.currentIndex

        width: ListView.view.width
        height: rootKipResultList.compact ? rootKipResultList.kipTheme.commandRowHeight : rootKipResultList.kipTheme.rowHeight
        radius: rootKipResultList.kipTheme.rowRadius
        color: selected ? rootKipResultList.kipTheme.selectedRowColor : (rowMouse.containsMouse ? rootKipResultList.kipTheme.hoveredRowColor : "transparent")
        border.width: selected ? 1 : 0
        border.color: rootKipResultList.kipTheme.focusBorderColor
        opacity: resultRow.modelData.weak ? 0.6 : 1

        Behavior on color {
            ColorAnimation {
                duration: rootKipResultList.kipTheme.reducedMotion ? 0 : 90
            }
        }

        Column {
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 3

            Row {
                width: parent.width
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: originText.implicitWidth + 10
                    height: originText.implicitHeight + 4
                    radius: rootKipResultList.kipTheme.chipRadius
                    color: rootKipResultList.kipTheme.chipColor

                    Text {
                        id: originText

                        anchors.centerIn: parent
                        text: resultRow.modelData.origin
                        color: ({
                                logseq: rootKipResultList.kipTheme.secondaryAccentColor,
                                legacy: rootKipResultList.kipTheme.warningColor,
                                prod: rootKipResultList.kipTheme.errorColor,
                                dir: rootKipResultList.kipTheme.accentColor
                            })[resultRow.modelData.origin] || rootKipResultList.kipTheme.secondaryTextColor
                        font.pixelSize: rootKipResultList.kipTheme.metaPixelSize
                    }
                }

                Text {
                    id: pathText

                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - scoreText.implicitWidth - 8
                    textFormat: Text.StyledText
                    elide: Text.ElideMiddle
                    font.pixelSize: rootKipResultList.kipTheme.bodyPixelSize
                    text: "<font color='" + rootKipResultList.kipTheme.folderColor + "'>" + rootKipResultList.escapeHtml(resultRow.modelData.folder) + "</font>"
                        + "<font color='" + rootKipResultList.kipTheme.fileColor + "'><b>" + rootKipResultList.escapeHtml(resultRow.modelData.file) + "</b></font>"
                        + (resultRow.modelData.line !== undefined ? "<font color='" + rootKipResultList.kipTheme.lineNumberColor + "'>:" + rootKipResultList.rangesLabel(resultRow.modelData) + "</font>" : "")
                }

                Text {
                    id: scoreText

                    anchors.verticalCenter: parent.verticalCenter
                    // Similarity, not Jarvis's blended score: it is what "weak" is judged on.
                    readonly property var value: typeof resultRow.modelData.similarity === "number" ? resultRow.modelData.similarity : resultRow.modelData.score

                    text: typeof value === "number" ? (resultRow.modelData.weak ? "weak " : "") + value.toFixed(2) : ""
                    color: rootKipResultList.kipTheme.secondaryTextColor
                    font.pixelSize: rootKipResultList.kipTheme.metaPixelSize
                }
            }

            Text {
                width: parent.width
                visible: !rootKipResultList.compact
                text: resultRow.modelData.excerpt
                color: rootKipResultList.kipTheme.secondaryTextColor
                font.pixelSize: rootKipResultList.kipTheme.metaPixelSize + 1
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                rootKipResultList.currentIndex = resultRow.index;
                rootKipResultList.activated(resultRow.index);
            }
        }
    }

    // "12–31" for one chunk, "1, 2, 14–17" when a file matched several times.
    function rangesLabel(hit) {
        const ranges = hit.ranges && hit.ranges.length > 0 ? hit.ranges : [{
                start: hit.line,
                end: hit.endLine
            }];

        return ranges.map(range => range.end > range.start ? range.start + "–" + range.end : String(range.start)).join(", ");
    }

    function escapeHtml(value) {
        return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }
}

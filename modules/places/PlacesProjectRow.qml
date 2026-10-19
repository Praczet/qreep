import QtQuick

// One project in the left list: icon, name, branch and age, a changed-files
// dot, and a quest bar when the project keeps a questlog. Draws its own group
// header when it is the first of its group.
Item {
    id: rootPlacesProjectRow

    required property QtObject theme
    required property QtObject service
    required property var project
    required property bool selected
    required property bool firstOfGroup

    readonly property QtObject pt: theme.modules.places
    readonly property var summary: service.summaries[project.id] || null

    signal clicked
    signal doubleClicked

    height: (firstOfGroup ? groupHeader.height : 0) + row.height

    Text {
        id: groupHeader

        visible: rootPlacesProjectRow.firstOfGroup
        width: parent.width
        height: 30
        leftPadding: 8
        verticalAlignment: Text.AlignBottom
        bottomPadding: 6
        text: rootPlacesProjectRow.project.group
        color: rootPlacesProjectRow.pt.sectionColor
        font.pixelSize: rootPlacesProjectRow.pt.sectionPixelSize
        font.bold: true
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
    }

    Rectangle {
        id: row

        y: rootPlacesProjectRow.firstOfGroup ? groupHeader.height : 0
        width: parent.width
        height: rootPlacesProjectRow.pt.rowHeight
        radius: rootPlacesProjectRow.pt.rowRadius
        color: rootPlacesProjectRow.selected ? rootPlacesProjectRow.pt.selectedRowColor : (mouse.containsMouse ? rootPlacesProjectRow.pt.hoveredRowColor : "transparent")
        border.width: rootPlacesProjectRow.selected ? 1 : 0
        border.color: rootPlacesProjectRow.pt.selectedBorderColor

        Behavior on color {
            ColorAnimation {
                duration: 90
            }
        }

        PlacesIcon {
            id: icon

            anchors {
                left: parent.left
                leftMargin: 12
                verticalCenter: parent.verticalCenter
            }
            width: rootPlacesProjectRow.pt.listIconSize
            height: width
            source: rootPlacesProjectRow.service.iconSource(rootPlacesProjectRow.project)
            glyph: rootPlacesProjectRow.project.icon
            name: rootPlacesProjectRow.project.name
            color: rootPlacesProjectRow.selected ? rootPlacesProjectRow.pt.accentColor : rootPlacesProjectRow.pt.primaryTextColor
            fontFamily: rootPlacesProjectRow.theme.iconFontFamily
        }

        Column {
            anchors {
                left: icon.right
                leftMargin: 12
                right: badges.left
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            spacing: 3

            Text {
                width: parent.width
                text: rootPlacesProjectRow.project.name
                color: rootPlacesProjectRow.pt.primaryTextColor
                font.pixelSize: rootPlacesProjectRow.pt.bodyPixelSize + 1
                font.bold: rootPlacesProjectRow.selected
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: rootPlacesProjectRow.metaText()
                color: rootPlacesProjectRow.summary && rootPlacesProjectRow.summary.missing ? rootPlacesProjectRow.pt.errorColor : rootPlacesProjectRow.pt.secondaryTextColor
                font.family: rootPlacesProjectRow.pt.monoFontFamily
                font.pixelSize: rootPlacesProjectRow.pt.metaPixelSize
                elide: Text.ElideRight
            }
        }

        Column {
            id: badges

            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            spacing: 5

            // Every entry: its Ctrl+N, as a dimmed key cap.
            Rectangle {
                readonly property string key: rootPlacesProjectRow.service.entryKey(rootPlacesProjectRow.project.id)

                anchors.right: parent.right
                visible: key.length > 0
                width: placeKey.implicitWidth + 12
                height: placeKey.implicitHeight + 4
                radius: 5
                color: rootPlacesProjectRow.pt.withAlpha(rootPlacesProjectRow.pt.primaryTextColor, 0.06)
                border.width: 1
                border.color: rootPlacesProjectRow.pt.withAlpha(rootPlacesProjectRow.pt.primaryTextColor, 0.22)

                Text {
                    id: placeKey

                    anchors.centerIn: parent
                    text: parent.key
                    color: rootPlacesProjectRow.pt.primaryTextColor
                    opacity: 0.68
                    font.family: rootPlacesProjectRow.pt.monoFontFamily
                    font.pixelSize: rootPlacesProjectRow.pt.metaPixelSize
                }
            }

            // Changed files: a dot and a count, warning-colored.
            Row {
                anchors.right: parent.right
                spacing: 4
                visible: rootPlacesProjectRow.summary !== null && rootPlacesProjectRow.summary.changed > 0

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 7
                    height: 7
                    radius: 4
                    color: rootPlacesProjectRow.pt.warningColor
                }

                Text {
                    text: rootPlacesProjectRow.summary ? rootPlacesProjectRow.summary.changed : ""
                    color: rootPlacesProjectRow.pt.warningColor
                    font.family: rootPlacesProjectRow.pt.monoFontFamily
                    font.pixelSize: rootPlacesProjectRow.pt.metaPixelSize
                }
            }

            // Quests: done share as a thin bar, red tick when steps are blocked.
            Item {
                anchors.right: parent.right
                visible: rootPlacesProjectRow.summary !== null && rootPlacesProjectRow.summary.quests !== null
                width: 46
                height: 4

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: rootPlacesProjectRow.pt.trackColor
                }

                Rectangle {
                    readonly property var quests: rootPlacesProjectRow.summary && rootPlacesProjectRow.summary.quests

                    width: quests && quests.total > 0 ? parent.width * quests.done / quests.total : 0
                    height: parent.height
                    radius: 2
                    color: quests && quests.blockedSteps > 0 ? rootPlacesProjectRow.pt.errorColor : rootPlacesProjectRow.pt.successColor
                }
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: rootPlacesProjectRow.clicked()
            onDoubleClicked: rootPlacesProjectRow.doubleClicked()
        }
    }

    function metaText() {
        const summary = rootPlacesProjectRow.summary;
        const project = rootPlacesProjectRow.project;

        // Places: their folder (if any) and what is on the page.
        if (project.kind === "place")
            return (project.displayPath ? project.displayPath + " · " : "") + project.blocks.length + (project.blocks.length === 1 ? " block" : " blocks");

        if (!summary)
            return rootPlacesProjectRow.project.displayPath;
        if (summary.missing)
            return "missing: " + rootPlacesProjectRow.project.displayPath;
        if (!summary.git)
            return rootPlacesProjectRow.project.displayPath;

        const age = service.ago(summary.lastCommitTime);
        return "⎇ " + summary.branch + (age ? " · " + age + " ago" : "");
    }
}

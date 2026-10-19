import QtQuick

// Questlog card: open quests first, each with step dots, its note, and any
// blocked step spelled out with who it waits on. Done quests are only counted.
PlacesSection {
    id: rootPlacesQuests

    required property QtObject service
    property int questLimit: 5

    readonly property var questlog: service.questlog
    readonly property var quests: questlog ? questlog.quests : []
    readonly property var openQuests: quests.filter(quest => quest.status !== "done")
    readonly property int doneCount: quests.length - openQuests.length

    title: "Quests"
    subtitle: questlog ? countText() : service.questlogError

    Repeater {
        model: rootPlacesQuests.openQuests.slice(0, rootPlacesQuests.questLimit)

        Column {
            id: questItem

            required property var modelData
            // Nested arrays arrive as Qt lists, not JS arrays: copy by length.
            readonly property var steps: modelData.steps && modelData.steps.length !== undefined ? Array.prototype.slice.call(modelData.steps) : []
            readonly property var blocked: steps.filter(step => step.status === "blocked")

            width: parent.width
            spacing: 3

            Item {
                width: parent.width
                height: 20

                Rectangle {
                    id: statusDot

                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: rootPlacesQuests.pt.statusColor(questItem.modelData.status)
                }

                Text {
                    anchors {
                        left: statusDot.right
                        leftMargin: 8
                        right: stepRow.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: questItem.modelData.title || questItem.modelData.id
                    color: rootPlacesQuests.pt.primaryTextColor
                    font.pixelSize: rootPlacesQuests.pt.bodyPixelSize
                    font.bold: questItem.modelData.status === "active"
                    elide: Text.ElideRight
                }

                // One dot per step, colored by status.
                Row {
                    id: stepRow

                    anchors {
                        right: statusText.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 3

                    Repeater {
                        model: questItem.steps.slice(0, 16)

                        Rectangle {
                            required property var modelData

                            width: 6
                            height: 6
                            radius: 3
                            color: modelData.status === "todo" ? "transparent" : rootPlacesQuests.pt.statusColor(modelData.status)
                            border.width: 1
                            border.color: modelData.status === "todo" ? rootPlacesQuests.pt.secondaryTextColor : color
                        }
                    }
                }

                Text {
                    id: statusText

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    text: questItem.modelData.status + (questItem.modelData.actor ? " · " + questItem.modelData.actor : "")
                    color: rootPlacesQuests.pt.statusColor(questItem.modelData.status)
                    font.family: rootPlacesQuests.pt.monoFontFamily
                    font.pixelSize: rootPlacesQuests.pt.metaPixelSize
                }
            }

            Text {
                visible: text.length > 0
                width: parent.width
                leftPadding: 16
                text: questItem.modelData.note || ""
                color: rootPlacesQuests.pt.secondaryTextColor
                font.pixelSize: rootPlacesQuests.pt.metaPixelSize + 1
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Repeater {
                model: questItem.blocked

                Text {
                    required property var modelData

                    width: questItem.width
                    leftPadding: 16
                    text: "✗ blocked" + (modelData.actor ? " on " + modelData.actor : "") + ": " + modelData.title
                    color: rootPlacesQuests.pt.errorColor
                    font.pixelSize: rootPlacesQuests.pt.metaPixelSize + 1
                    elide: Text.ElideRight
                }
            }
        }
    }

    Text {
        visible: rootPlacesQuests.openQuests.length > rootPlacesQuests.questLimit
        text: "+ " + (rootPlacesQuests.openQuests.length - rootPlacesQuests.questLimit) + " more open"
        color: rootPlacesQuests.pt.secondaryTextColor
        font.pixelSize: rootPlacesQuests.pt.metaPixelSize
    }

    Text {
        visible: rootPlacesQuests.questlog !== null && rootPlacesQuests.openQuests.length === 0
        text: "Nothing open. Suspicious, but fine."
        color: rootPlacesQuests.pt.secondaryTextColor
        font.pixelSize: rootPlacesQuests.pt.bodyPixelSize
    }

    function countText() {
        const active = openQuests.filter(quest => quest.status === "active").length;
        const paused = openQuests.filter(quest => quest.status === "paused").length;
        const parts = [active + " active"];

        if (paused > 0)
            parts.push(paused + " paused");
        parts.push(doneCount + " done");
        if (questlog.updatedAt)
            parts.push("updated " + service.ago(Date.parse(questlog.updatedAt) / 1000) + " ago" + (questlog.updatedBy ? " by " + questlog.updatedBy : ""));
        return parts.join(" · ");
    }
}

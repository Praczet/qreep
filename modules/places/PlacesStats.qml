import QtQuick

// Stats card: headline numbers, top languages from tokei as bars, and
// weekly commit activity as a small column chart.
PlacesSection {
    id: rootPlacesStats

    required property QtObject service
    required property var detail
    property var stats: null
    property bool hasGit: false

    readonly property int maxActivity: Math.max(1, ...(detail.activity.length > 0 ? detail.activity : [0]))
    readonly property int maxLanguage: stats && stats.rows.length > 0 ? stats.rows[0].c : 1

    title: "Stats"
    subtitle: stats ? "" : "counting lines…"

    Row {
        spacing: 28

        Repeater {
            model: rootPlacesStats.headline()

            Column {
                required property var modelData

                spacing: 2

                Text {
                    text: modelData.value
                    color: rootPlacesStats.pt.primaryTextColor
                    font.pixelSize: 20
                    font.bold: true
                }

                Text {
                    text: modelData.label
                    color: rootPlacesStats.pt.secondaryTextColor
                    font.pixelSize: rootPlacesStats.pt.metaPixelSize
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: 24
        topPadding: 6

        // Languages: name, bar scaled to the biggest, line count.
        Column {
            width: (parent.width - parent.spacing) * 0.55
            spacing: 5
            visible: rootPlacesStats.stats !== null && rootPlacesStats.stats.rows.length > 0

            Repeater {
                model: rootPlacesStats.stats ? rootPlacesStats.stats.rows : []

                Item {
                    required property var modelData

                    width: parent.width
                    height: 16

                    Text {
                        id: languageName

                        anchors.verticalCenter: parent.verticalCenter
                        width: 96
                        text: modelData.n
                        color: rootPlacesStats.pt.primaryTextColor
                        font.pixelSize: rootPlacesStats.pt.metaPixelSize + 1
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: track

                        anchors {
                            left: languageName.right
                            right: languageCount.left
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        height: 6
                        radius: 3
                        color: rootPlacesStats.pt.trackColor

                        Rectangle {
                            width: parent.width * modelData.c / rootPlacesStats.maxLanguage
                            height: parent.height
                            radius: 3
                            color: rootPlacesStats.pt.accentColor
                        }
                    }

                    Text {
                        id: languageCount

                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        width: 52
                        horizontalAlignment: Text.AlignRight
                        text: rootPlacesStats.service.formatCount(modelData.c)
                        color: rootPlacesStats.pt.secondaryTextColor
                        font.family: rootPlacesStats.pt.monoFontFamily
                        font.pixelSize: rootPlacesStats.pt.metaPixelSize
                    }
                }
            }
        }

        // Commit activity: one column per week, newest on the right.
        Column {
            visible: rootPlacesStats.hasGit && rootPlacesStats.detail.activity.length > 0
            spacing: 4

            Row {
                height: 54
                spacing: 4

                Repeater {
                    model: rootPlacesStats.detail.activity

                    Item {
                        required property int modelData

                        width: 12
                        height: 54

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, parent.height * modelData / rootPlacesStats.maxActivity)
                            radius: 3
                            color: modelData > 0 ? rootPlacesStats.pt.accentColor : rootPlacesStats.pt.trackColor
                            opacity: modelData > 0 ? 0.45 + 0.55 * modelData / rootPlacesStats.maxActivity : 1
                        }
                    }
                }
            }

            Text {
                text: "commits / week · last " + rootPlacesStats.detail.activity.length + " weeks"
                color: rootPlacesStats.pt.secondaryTextColor
                font.pixelSize: rootPlacesStats.pt.metaPixelSize
            }
        }
    }

    function headline() {
        const items = [];

        if (detail.fileCount > 0)
            items.push({
                value: service.formatCount(detail.fileCount),
                label: "files"
            });
        if (stats && stats.total > 0)
            items.push({
                value: service.formatCount(stats.total),
                label: "lines of code"
            });
        if (detail.commitCount > 0)
            items.push({
                value: service.formatCount(detail.commitCount),
                label: "commits"
            });
        if (detail.activityTimes.length > 0)
            items.push({
                value: String(detail.activityTimes.length),
                label: "commits, " + detail.activity.length + " weeks"
            });
        return items;
    }
}

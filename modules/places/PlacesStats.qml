import QtQuick

// Stats card: headline numbers, then the top languages from tokei as bars in
// two columns. Commit activity lives in PlacesActivity.
PlacesSection {
    id: rootPlacesStats

    required property QtObject service
    required property var detail
    property var stats: null

    readonly property int maxLanguage: stats && stats.rows.length > 0 ? stats.rows[0].c : 1
    readonly property int columnWidth: (width - 2 * pt.cardPadding - 32) / 2

    title: "Stats"
    subtitle: stats ? "" : "counting lines…"

    Row {
        spacing: 36

        Repeater {
            model: rootPlacesStats.headline()

            Column {
                required property var modelData

                spacing: 2

                Text {
                    text: modelData.value
                    color: rootPlacesStats.pt.primaryTextColor
                    font.pixelSize: 22
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

    // Languages, filled column by column: name, bar scaled to the biggest, lines.
    Grid {
        visible: rootPlacesStats.stats !== null && rootPlacesStats.stats.rows.length > 0
        topPadding: 8
        columns: 2
        flow: Grid.TopToBottom
        rows: Math.ceil((rootPlacesStats.stats ? rootPlacesStats.stats.rows.length : 0) / 2)
        columnSpacing: 32
        rowSpacing: 6

        Repeater {
            model: rootPlacesStats.stats ? rootPlacesStats.stats.rows : []

            Item {
                required property var modelData

                width: rootPlacesStats.columnWidth
                height: 16

                Text {
                    id: languageName

                    anchors.verticalCenter: parent.verticalCenter
                    width: 104
                    text: modelData.n
                    color: rootPlacesStats.pt.primaryTextColor
                    font.pixelSize: rootPlacesStats.pt.metaPixelSize + 1
                    elide: Text.ElideRight
                }

                Rectangle {
                    anchors {
                        left: languageName.right
                        right: languageCount.left
                        rightMargin: 10
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
                    width: 56
                    horizontalAlignment: Text.AlignRight
                    text: rootPlacesStats.service.formatCount(modelData.c)
                    color: rootPlacesStats.pt.secondaryTextColor
                    font.family: rootPlacesStats.pt.monoFontFamily
                    font.pixelSize: rootPlacesStats.pt.metaPixelSize
                }
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
        if (stats && stats.rows.length > 0)
            items.push({
                value: String(stats.rows.length) + (stats.rows.length >= pt.languageLimit ? "+" : ""),
                label: stats.rows.length === 1 ? "language" : "languages"
            });
        if (detail.commitCount > 0)
            items.push({
                value: service.formatCount(detail.commitCount),
                label: "commits in total"
            });
        if (detail.docs.length > 0)
            items.push({
                value: String(detail.docs.length) + (detail.docs.length >= pt.docLimit ? "+" : ""),
                label: "docs"
            });
        return items;
    }
}

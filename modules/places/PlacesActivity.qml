import QtQuick

// A year of commits, GitHub style: one column per week (newest on the right),
// one row per weekday, darker = more commits that day. Cells after today
// stay empty. Sized to the card's width, capped at activityMaxCell.
PlacesSection {
    id: rootPlacesActivity

    required property QtObject service
    required property var times

    readonly property int weeks: pt.activityWeeks
    readonly property int gap: pt.activityCellGap
    readonly property int labelWidth: 30
    readonly property real cell: Math.max(6, Math.min(pt.activityMaxCell, (width - 2 * pt.cardPadding - labelWidth - gap * (weeks - 1)) / weeks))
    readonly property var grid: buildGrid(times)

    title: "Activity"
    subtitle: summaryText()

    // Month labels over the first column of each month.
    Item {
        width: parent.width
        height: 14

        Repeater {
            model: rootPlacesActivity.grid.months

            Text {
                required property var modelData

                x: rootPlacesActivity.labelWidth + modelData.column * (rootPlacesActivity.cell + rootPlacesActivity.gap)
                text: modelData.label
                color: rootPlacesActivity.pt.secondaryTextColor
                font.pixelSize: rootPlacesActivity.pt.metaPixelSize
            }
        }
    }

    Row {
        spacing: 0

        Column {
            width: rootPlacesActivity.labelWidth
            spacing: rootPlacesActivity.gap

            Repeater {
                model: ["Mon", "", "Wed", "", "Fri", "", ""]

                // Width set explicitly: positioners skip zero-width items, and
                // the empty labels would collapse Wed/Fri onto rows 1 and 2.
                Text {
                    required property string modelData

                    width: rootPlacesActivity.labelWidth
                    height: rootPlacesActivity.cell
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: rootPlacesActivity.pt.secondaryTextColor
                    font.pixelSize: rootPlacesActivity.pt.metaPixelSize - 1
                }
            }
        }

        Grid {
            rows: 7
            flow: Grid.TopToBottom
            spacing: rootPlacesActivity.gap

            Repeater {
                model: rootPlacesActivity.grid.cells

                Rectangle {
                    required property var modelData

                    width: rootPlacesActivity.cell
                    height: rootPlacesActivity.cell
                    radius: Math.max(2, rootPlacesActivity.cell / 4)
                    visible: !modelData.future
                    color: modelData.level === 0 ? rootPlacesActivity.pt.trackColor : rootPlacesActivity.pt.accentColor
                    opacity: modelData.level === 0 ? 0.55 : [0, 0.35, 0.55, 0.78, 1][modelData.level]
                }
            }
        }
    }

    // Day buckets for `weeks` weeks ending with the current (partial) week.
    // Rows start on Monday. level: 0 none, 1-4 by share of the busiest day.
    function buildGrid(stamps) {
        const day = 24 * 3600 * 1000;
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const mondayOffset = (today.getDay() + 6) % 7;
        const start = new Date(today.getTime() - (mondayOffset + (weeks - 1) * 7) * day);
        const counts = new Array(weeks * 7).fill(0);

        for (const stamp of stamps) {
            const date = new Date(stamp * 1000);
            date.setHours(0, 0, 0, 0);
            const index = Math.round((date.getTime() - start.getTime()) / day);
            if (index >= 0 && index < counts.length)
                counts[index]++;
        }

        const max = Math.max(1, ...counts);
        const todayIndex = Math.round((today.getTime() - start.getTime()) / day);
        const cells = counts.map((count, index) => ({
                    count: count,
                    future: index > todayIndex,
                    level: count === 0 ? 0 : Math.min(4, Math.ceil(4 * count / max))
                }));

        const months = [];
        let lastMonth = -1;

        for (let column = 0; column < weeks; column++) {
            const date = new Date(start.getTime() + column * 7 * day);

            if (date.getMonth() === lastMonth)
                continue;
            lastMonth = date.getMonth();

            // A month starting late in the first column gets no label, and a
            // label never lands within three columns of the previous one.
            const previous = months.length > 0 ? months[months.length - 1].column : -10;
            if ((column > 0 || date.getDate() <= 14) && column - previous >= 3)
                months.push({
                    column: column,
                    label: Qt.formatDate(date, "MMM")
                });
        }

        let busiest = 0;
        for (let index = 1; index < counts.length; index++) {
            if (counts[index] > counts[busiest])
                busiest = index;
        }

        return {
            cells: cells,
            months: months,
            total: counts.reduce((sum, count) => sum + count, 0),
            activeDays: counts.filter(count => count > 0).length,
            busiestCount: counts[busiest],
            busiestDate: new Date(start.getTime() + busiest * day)
        };
    }

    function summaryText() {
        if (grid.total === 0)
            return "no commits in the last year";

        return grid.total + (grid.total === 1 ? " commit" : " commits") + " in the last year · "
            + grid.activeDays + (grid.activeDays === 1 ? " active day" : " active days")
            + " · busiest " + Qt.formatDate(grid.busiestDate, "ddd d MMM") + " (" + grid.busiestCount + ")";
    }
}

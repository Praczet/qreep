import QtQuick

// A small toggle in the search bar: view (Grid / List) or tile size.
Rectangle {
    id: rootWallpaperChip

    required property QtObject wt
    property string iconFont: ""
    property string label: ""
    property bool active: false
    // Sizes while the list is showing: still clickable (they switch to the grid).
    property bool dimmed: false

    signal clicked

    width: labelText.implicitWidth + 18
    height: wt.chipHeight
    radius: height / 2
    color: active ? wt.activeChipColor : (chipMouse.containsMouse ? wt.hoveredColor : wt.chipColor)
    border.width: active ? 1 : 0
    border.color: wt.selectedBorderColor
    opacity: dimmed ? 0.55 : 1

    Text {
        id: labelText

        anchors.centerIn: parent
        text: rootWallpaperChip.label
        color: rootWallpaperChip.active ? rootWallpaperChip.wt.primaryTextColor : rootWallpaperChip.wt.secondaryTextColor
        font.family: rootWallpaperChip.iconFont
        font.pixelSize: rootWallpaperChip.wt.metaPixelSize + 1
        font.bold: rootWallpaperChip.active
    }

    MouseArea {
        id: chipMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: rootWallpaperChip.clicked()
    }
}

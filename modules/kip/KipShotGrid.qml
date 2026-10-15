import QtQuick

// /last thumbnails: one shot gets a large preview, more get a grid.
GridView {
    id: rootKipShotGrid

    required property QtObject kipTheme
    required property QtObject shots
    required property int columns
    property int selectedIndex: 0
    property real maxHeight: 400

    signal activated(int index)

    height: Math.min(Math.ceil(rootKipShotGrid.shots.shots.length / rootKipShotGrid.columns) * cellHeight, rootKipShotGrid.maxHeight)
    model: rootKipShotGrid.shots.shots
    cellWidth: width / rootKipShotGrid.columns
    cellHeight: (rootKipShotGrid.shots.shots.length === 1 ? rootKipShotGrid.kipTheme.screenshotSinglePreviewHeight : Math.round(cellWidth * 0.5625)) + 38
    currentIndex: rootKipShotGrid.selectedIndex
    interactive: contentHeight > height
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    onCurrentIndexChanged: {
        if (currentIndex >= 0)
            positionViewAtIndex(currentIndex, GridView.Contain);
    }

    delegate: Item {
        id: shotCell

        required property var modelData
        required property int index

        readonly property bool selected: index === rootKipShotGrid.selectedIndex

        width: GridView.view.cellWidth
        height: GridView.view.cellHeight

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: rootKipShotGrid.kipTheme.rowRadius
            color: shotCell.selected ? rootKipShotGrid.kipTheme.selectedRowColor : (shotMouse.containsMouse ? rootKipShotGrid.kipTheme.hoveredRowColor : rootKipShotGrid.kipTheme.inputColor)
            border.width: shotCell.selected ? 1 : 0
            border.color: rootKipShotGrid.kipTheme.focusBorderColor

            Image {
                id: shotImage

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 6
                }
                height: parent.height - 44
                source: "file://" + shotCell.modelData.absolutePath.split("/").map(encodeURIComponent).join("/")
                sourceSize.width: Math.round(width * 1.5)
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
            }

            Text {
                anchors.centerIn: shotImage
                visible: shotImage.status === Image.Error
                text: "preview failed"
                color: rootKipShotGrid.kipTheme.secondaryTextColor
                font.pixelSize: rootKipShotGrid.kipTheme.metaPixelSize
            }

            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 6
                }

                Text {
                    width: parent.width
                    text: shotCell.modelData.file
                    color: rootKipShotGrid.kipTheme.fileColor
                    font.pixelSize: rootKipShotGrid.kipTheme.metaPixelSize + 1
                    elide: Text.ElideMiddle
                }

                Text {
                    width: parent.width
                    text: rootKipShotGrid.shots.age(shotCell.modelData.modified)
                    color: rootKipShotGrid.kipTheme.secondaryTextColor
                    font.pixelSize: rootKipShotGrid.kipTheme.metaPixelSize
                }
            }
        }

        MouseArea {
            id: shotMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                rootKipShotGrid.activated(shotCell.index);
            }
        }
    }
}

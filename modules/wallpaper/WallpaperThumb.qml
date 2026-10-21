import QtQuick

// One wallpaper thumbnail: letterboxed (the whole image, never cropped), a
// placeholder until the thumbnail exists, and a "current" badge.
Rectangle {
    id: rootWallpaperThumb

    required property QtObject wt
    required property QtObject service
    required property var item
    // 400 or 800: which cached thumbnail to load.
    required property int thumbSize
    property string iconFont: ""
    property bool showCurrentBadge: true
    // A thin strip of the dominant colours along the bottom edge.
    property bool showPalette: true

    radius: 6
    color: wt.imageBackgroundColor
    clip: true

    Image {
        id: image

        anchors.fill: parent
        source: rootWallpaperThumb.service.thumbUrl(rootWallpaperThumb.item, rootWallpaperThumb.thumbSize)
        sourceSize.width: Math.min(rootWallpaperThumb.thumbSize, Math.ceil(width))
        sourceSize.height: Math.min(Math.round(rootWallpaperThumb.thumbSize * 0.75), Math.ceil(height))
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
    }

    Text {
        anchors.centerIn: parent
        visible: image.status !== Image.Ready
        text: "󰸉"
        color: rootWallpaperThumb.wt.secondaryTextColor
        opacity: 0.5
        font.family: rootWallpaperThumb.iconFont
        font.pixelSize: Math.max(14, Math.min(48, rootWallpaperThumb.height / 4))
    }

    WallpaperPalette {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 4
        visible: rootWallpaperThumb.showPalette && image.status === Image.Ready && rootWallpaperThumb.item !== null && rootWallpaperThumb.item !== undefined && (rootWallpaperThumb.item.colors || []).length > 0
        colors: rootWallpaperThumb.item ? (rootWallpaperThumb.item.colors || []) : []
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            margins: 6
        }
        visible: rootWallpaperThumb.showCurrentBadge && rootWallpaperThumb.service.isCurrent(rootWallpaperThumb.item)
        width: badgeText.implicitWidth + 12
        height: badgeText.implicitHeight + 4
        radius: height / 2
        color: rootWallpaperThumb.wt.chipColor

        Text {
            id: badgeText

            anchors.centerIn: parent
            text: "● current"
            color: rootWallpaperThumb.wt.currentColor
            font.pixelSize: rootWallpaperThumb.wt.metaPixelSize
        }
    }
}

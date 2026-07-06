import QtQuick

Item {
    id: rootAegisHero

    required property QtObject theme
    property QtObject service

    implicitHeight: layout.implicitHeight

    Row {
        id: layout

        width: parent.width
        spacing: 18

        HeroBlock {
            width: (parent.width - divider.width - parent.spacing * 2) / 2
            theme: rootAegisHero.theme
            iconSource: rootAegisHero.service ? rootAegisHero.service.osIconSource() : ""
            title: rootAegisHero.service ? String(rootAegisHero.service.data.os.prettyName || "Unknown OS") : "Unknown OS"
            subtitle: rootAegisHero.service ? String(rootAegisHero.service.data.kernel.release || "") : ""
        }

        Rectangle {
            id: divider

            width: 1
            height: parent.height
            color: rootAegisHero.theme.modules.aegis.borderColor
            opacity: 0.45
        }

        HeroBlock {
            width: (parent.width - divider.width - parent.spacing * 2) / 2
            theme: rootAegisHero.theme
            iconSource: rootAegisHero.service ? rootAegisHero.service.hyprlandIconSource() : ""
            title: "Hyprland"
            subtitle: rootAegisHero.service ? String(rootAegisHero.service.data.hyprland.version || "") : ""
        }
    }

    component HeroBlock: Row {
        required property QtObject theme
        property string iconSource: ""
        property string title: ""
        property string subtitle: ""

        spacing: 14
        height: Math.max(icon.height, textColumn.implicitHeight)

        Image {
            id: icon

            width: parent.theme.modules.aegis.heroIconSize
            height: width
            source: parent.iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Column {
            id: textColumn

            width: Math.max(1, parent.width - icon.width - parent.spacing)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: parent.parent.title
                color: parent.parent.theme.modules.aegis.primaryTextColor
                font.pixelSize: parent.parent.theme.modules.aegis.titlePixelSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: parent.parent.subtitle
                color: parent.parent.theme.modules.aegis.secondaryTextColor
                font.pixelSize: parent.parent.theme.modules.aegis.metaPixelSize
                elide: Text.ElideRight
            }
        }
    }
}

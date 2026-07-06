import QtQuick

Item {
    id: rootAegisSection

    required property QtObject theme
    property QtObject service
    required property var section

    implicitHeight: layout.implicitHeight

    Column {
        id: layout

        width: parent.width
        spacing: rootAegisSection.theme.modules.aegis.rowGap

        Text {
            width: parent.width
            text: String(rootAegisSection.section.title || "")
            color: rootAegisSection.theme.modules.aegis.primaryTextColor
            font.pixelSize: rootAegisSection.theme.modules.aegis.sectionTitlePixelSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Repeater {
            model: rootAegisSection.section.rows || []

            AegisInfoRow {
                required property var modelData

                width: layout.width
                theme: rootAegisSection.theme
                service: rootAegisSection.service
                label: String(modelData.label || "")
                value: String(modelData.value || "")
            }
        }
    }
}

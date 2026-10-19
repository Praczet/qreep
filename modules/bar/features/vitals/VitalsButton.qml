import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootVitalsButton

    required property QtObject controller

    tooltipTitle: "Vitals"
    tooltipContent: controller.tooltipContent

    Row {
        spacing: rootVitalsButton.theme.modules.bar.vitals.contentSpacing

        Repeater {
            // Keyed by indicator id so a new sample rebinds values instead of
            // recreating every delegate.
            model: rootVitalsButton.controller.enabledIndicators

            VitalsIndicator {
                required property string modelData

                anchors.verticalCenter: parent.verticalCenter
                theme: rootVitalsButton.theme
                item: rootVitalsButton.controller.indicatorItem(modelData)
            }
        }
    }
}

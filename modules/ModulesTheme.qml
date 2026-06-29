import QtQuick

import "bar" as BarModule
import "dashboard" as DashboardModule
import "osd" as OsdModule

QtObject {
    id: rootModulesTheme

    required property QtObject qreep

    readonly property QtObject bar: BarModule.BarTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject dashboard: DashboardModule.DashboardTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject osd: OsdModule.OsdTheme {
        qreep: rootModulesTheme.qreep
    }
}

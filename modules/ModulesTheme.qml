import QtQuick

import "bar" as BarModule
import "bloom" as BloomModule
import "clipboard" as ClipboardModule
import "dashboard" as DashboardModule
import "dashboard/features/aegis" as AegisFeature
import "expose" as ExposeModule
import "notification" as NotificationModule
import "osd" as OsdModule
import "polkit" as PolkitModule
import "timer" as TimerModule

QtObject {
    id: rootModulesTheme

    required property QtObject qreep

    readonly property QtObject aegis: AegisFeature.AegisTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject bar: BarModule.BarTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject bloom: BloomModule.BloomTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject clipboard: ClipboardModule.ClipboardTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject dashboard: DashboardModule.DashboardTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject expose: ExposeModule.ExposeTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject notification: NotificationModule.NotificationTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject osd: OsdModule.OsdTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject polkit: PolkitModule.PolkitTheme {
        qreep: rootModulesTheme.qreep
    }

    readonly property QtObject timer: TimerModule.TimerTheme {
        qreep: rootModulesTheme.qreep
    }
}

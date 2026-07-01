import QtQuick

import "./features/borg" as BorgFeature
import "./features/clock" as ClockFeature
import "./features/launcher" as LauncherFeature
import "./features/monitorprofile" as MonitorProfileFeature
import "./features/mpris" as MprisFeature
import "./features/network" as NetworkFeature
import "./features/power" as PowerFeature
import "./features/upchecker" as UpcheckerFeature
import "./features/volume" as VolumeFeature
import "./features/workspaces" as WorkspacesFeature
import "./features/battery/" as BatteryFeature

QtObject {
    id: rootBarTheme

    required property QtObject qreep

    readonly property int height: 48
    readonly property int collapsedHeight: 15
    readonly property int horizontalPadding: 8
    readonly property int topPadding: 15
    readonly property int backgroundRadius: 0
    readonly property int sideMargin: 4
    readonly property int itemSpacing: 4

    readonly property color backgroundColor: "transparent"
    readonly property color moduleBackgroundColor: qreep.background
    readonly property color moduleHoverBackgroundColor: qreep.surfaceContainerHigh
    readonly property color primaryTextColor: qreep.primary
    readonly property color secondaryTextColor: qreep.on_surface_variant
    readonly property color accentColor: qreep.primary

    readonly property QtObject pill: BarPillTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject tooltip: TooltipTheme {
        qreep: rootBarTheme.qreep
    }

    readonly property QtObject borg: BorgFeature.BorgTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject calendar: ClockFeature.CalendarTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject clock: ClockFeature.ClockTheme {}
    readonly property QtObject launcher: LauncherFeature.LauncherTheme {}
    readonly property QtObject monitorProfile: MonitorProfileFeature.MonitorProfileTheme {}
    readonly property QtObject mpris: MprisFeature.MprisTheme {}
    readonly property QtObject network: NetworkFeature.NetworkTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject power: PowerFeature.PowerTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject upchecker: UpcheckerFeature.UpcheckerTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject volume: VolumeFeature.VolumeTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject workspaces: WorkspacesFeature.WorkspacesTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject battery: BatteryFeature.BatteryTheme {
        qreep: rootBarTheme.qreep
    }
}

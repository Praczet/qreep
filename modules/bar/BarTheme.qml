import QtQuick

import "./features/borg" as BorgFeature
import "./features/clock" as ClockFeature
import "./features/launcher" as LauncherFeature
import "./features/monitorprofile" as MonitorProfileFeature
import "./features/mpris" as MprisFeature
import "./features/power" as PowerFeature
import "./features/upchecker" as UpcheckerFeature
import "./features/workspaces" as WorkspacesFeature

QtObject {
    id: rootBarTheme

    required property QtObject qreep

    readonly property int height: 48
    readonly property int horizontalPadding: 8
    readonly property int topPadding: 15
    readonly property int backgroundRadius: 0
    readonly property int sideMargin: 4
    readonly property int itemSpacing: 4

    readonly property QtObject pill: BarPillTheme {}
    readonly property QtObject tooltip: TooltipTheme {}

    readonly property QtObject borg: BorgFeature.BorgTheme {}
    readonly property QtObject calendar: ClockFeature.CalendarTheme {}
    readonly property QtObject clock: ClockFeature.ClockTheme {}
    readonly property QtObject launcher: LauncherFeature.LauncherTheme {}
    readonly property QtObject monitorProfile: MonitorProfileFeature.MonitorProfileTheme {}
    readonly property QtObject mpris: MprisFeature.MprisTheme {}
    readonly property QtObject power: PowerFeature.PowerTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject upchecker: UpcheckerFeature.UpcheckerTheme {
        qreep: rootBarTheme.qreep
    }
    readonly property QtObject workspaces: WorkspacesFeature.WorkspacesTheme {
        qreep: rootBarTheme.qreep
    }
}

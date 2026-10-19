import Quickshell
import "core" as Core
import "modules/aegis" as AegisModule
import "modules/notification" as NotificationModule
import "modules/clipboard" as ClipboardModule
import "modules/dashboard" as DashboardModule
import "modules/expose" as ExposeModule
import "modules/fastpassword" as FastPasswordModule
import "modules/kip" as KipModule
import "modules/osd" as OsdModule
import "modules/places" as PlacesModule
import "modules/polkit" as PolkitModule
import "modules/qreeper" as QreeperModule
import "modules/screenshot" as ScreenshotModule
import "modules/timer" as TimerModule
import "modules/triage" as TriageModule
import "modules/bloom" as BloomModule
import "modules/bar" as BarModule
import "theme" as Theme

ShellRoot {
    id: rootShell

    Theme.QreepTheme {
        id: qreepTheme
    }

    // Shared by the bar vitals pill now; Aegis can read it later.
    Core.SystemSensorsService {
        id: systemSensors
    }

    NotificationModule.Notification {
        id: notification

        theme: qreepTheme
    }

    TimerModule.Timer {
        id: timer

        theme: qreepTheme
        osd: osd
    }

    BarModule.Bar {
        id: bar

        theme: qreepTheme
        timerController: timer
        timerService: timer.service
        triageController: triage
        qreeperController: qreeper
        aegisController: aegis
        sensorsService: systemSensors
        shellFullscreenSurfaceOpen: dashboard.open || expose.open || qreeper.atlasOpen

        onVolumeFeedbackRequested: (percent, muted, icon) => {
            osd.showMessage(percent + "%", qreepTheme.modules.osd.defaultDuration, qreepTheme.modules.osd.defaultPosition, muted ? "Volume (Muted)" : "Volume", icon, qreepTheme.modules.osd.progressIconSize, percent / 100);
        }
    }

    QreeperModule.Qreeper {
        id: qreeper

        theme: qreepTheme
    }

    AegisModule.Aegis {
        id: aegis

        theme: qreepTheme
    }

    DashboardModule.Dashboard {
        id: dashboard

        theme: qreepTheme
    }

    ClipboardModule.Clipboard {
        id: clipboard

        theme: qreepTheme
    }

    ExposeModule.Expose {
        id: expose

        theme: qreepTheme
    }

    FastPasswordModule.FastPassword {
        id: fastPassword

        theme: qreepTheme
    }

    KipModule.Kip {
        id: kip

        theme: qreepTheme
        timerService: timer.service
        exposeService: expose.service
        placesController: places
    }

    PlacesModule.Places {
        id: places

        theme: qreepTheme
        kipController: kip
    }

    BloomModule.Bloom {
        id: bloom

        theme: qreepTheme
    }

    TriageModule.Triage {
        id: triage

        theme: qreepTheme
        updaterService: bar.upcheckerService
    }

    PolkitModule.Polkit {
        id: polkit

        theme: qreepTheme
    }

    ScreenshotModule.Screenshot {
        id: screenshot

        theme: qreepTheme
    }

    OsdModule.Osd {
        id: osd

        theme: qreepTheme
    }
}

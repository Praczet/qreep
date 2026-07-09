import Quickshell
import "modules/aegis" as AegisModule
import "modules/notification" as NotificationModule
import "modules/clipboard" as ClipboardModule
import "modules/dashboard" as DashboardModule
import "modules/expose" as ExposeModule
import "modules/osd" as OsdModule
import "modules/bloom" as BloomModule
import "modules/bar" as BarModule
import "theme" as Theme

ShellRoot {
    id: rootShell

    Theme.QreepTheme {
        id: qreepTheme
    }

    NotificationModule.Notification {
        id: notification

        theme: qreepTheme
    }

    BarModule.Bar {
        id: bar

        theme: qreepTheme
        shellFullscreenSurfaceOpen: dashboard.open || expose.open

        onVolumeFeedbackRequested: (percent, muted, icon) => {
            osd.showMessage(percent + "%", qreepTheme.modules.osd.defaultDuration, qreepTheme.modules.osd.defaultPosition, muted ? "Volume (Muted)" : "Volume", icon, qreepTheme.modules.osd.progressIconSize, percent / 100);
        }
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

    BloomModule.Bloom {
        id: bloom

        theme: qreepTheme
    }

    OsdModule.Osd {
        id: osd

        theme: qreepTheme
    }
}

import Quickshell
import "modules/clipboard" as ClipboardModule
import "modules/dashboard" as DashboardModule
import "modules/expose" as ExposeModule
import "modules/osd" as OsdModule
import "modules/bar" as BarModule
import "theme" as Theme

ShellRoot {
    id: rootShell

    Theme.QreepTheme {
        id: qreepTheme
    }

    BarModule.Bar {
        theme: qreepTheme

        onVolumeFeedbackRequested: (percent, muted, icon) => {
            osd.showMessage(percent + "%", qreepTheme.modules.osd.defaultDuration, qreepTheme.modules.osd.defaultPosition, muted ? "Volume (Muted)" : "Volume", icon, qreepTheme.modules.osd.progressIconSize, percent / 100);
        }
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

    OsdModule.Osd {
        id: osd

        theme: qreepTheme
    }
}

import Quickshell
import "features/osd" as OsdFeature
import "panels" as Panels
import "theme" as Theme

ShellRoot {
    id: rootShell

    Theme.QreepTheme {
        id: qreepTheme
    }

    Panels.Bar {
        theme: qreepTheme

        onOsdTestRequested: (message, durationMs) => osd.showMessage(message, durationMs)
    }

    OsdFeature.Osd {
        id: osd

        theme: qreepTheme
    }
}

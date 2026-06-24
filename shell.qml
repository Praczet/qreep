import Quickshell
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

    Panels.Osd {
        id: osd

        theme: qreepTheme
    }
}

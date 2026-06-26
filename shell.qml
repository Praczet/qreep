import Quickshell
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
    }

    OsdModule.Osd {
        id: osd

        theme: qreepTheme
    }
}

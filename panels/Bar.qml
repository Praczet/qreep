import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core" as Core
import "../features/borg" as BorgFeature
import "../features/clock" as ClockFeature
import "../features/osd" as OsdFeature
import "../features/power" as PowerFeature
import "../features/upchecker" as UpcheckerFeature
import "../features/monitorprofile" as MonitorProfileFeature
import "../features/mpris" as MprisFeature

PanelWindow {
    id: rootBar

    required property QtObject theme

    property alias leftSlotItems: leftSlot.data
    property alias centerSlotItems: centerSlot.data
    property alias rightSlotItems: rightSlot.data
    property alias overlayItems: overlayLayer.data

    signal osdTestRequested(string message, int durationMs)

    ClockFeature.EventStore {
        id: eventStore
        log: qreepLog
    }

    Core.Log {
        id: qreepLog

        notificationBackend: rootBar.theme.logNotificationBackend
        notifyWarnings: rootBar.theme.logNotifyWarnings
        notifyErrors: rootBar.theme.logNotifyErrors
        notificationDuration: rootBar.theme.logNotificationDuration
        warningColor: rootBar.theme.logWarningColor
        errorColor: rootBar.theme.logErrorColor
    }

    PowerFeature.PowerService {
        id: powerService
        log: qreepLog
    }

    MonitorProfileFeature.MonitorProfileService {
        id: monitorProfileService
        log: qreepLog
    }

    MprisFeature.MprisService {
        id: mprisService
    }

    BorgFeature.BorgService {
        id: borgService
        log: qreepLog
        refreshInterval: rootBar.theme.borg.refreshInterval
        backupCommand: [rootBar.theme.borg.backupCommand]
        backupStatusBackend: rootBar.theme.borg.backupStatusBackend
    }

    UpcheckerFeature.UpcheckerService {
        id: upcheckerService
        log: qreepLog
        updateTerminalCommand: rootBar.theme.upchecker.updateTerminalCommand
        updateCommand: rootBar.theme.upchecker.updateCommand
        restartCheckCommand: rootBar.theme.upchecker.restartCheckCommand
        restartCheckTimezone: rootBar.theme.upchecker.restartCheckTimezone
        restartSessionPackages: rootBar.theme.upchecker.restartSessionPackages
        restartRebootPackages: rootBar.theme.upchecker.restartRebootPackages
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: rootBar.theme.bar.height + rootBar.theme.bar.topPadding
    color: "transparent"

    WlrLayershell.namespace: "qreep-bar"

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: rootBar.theme.bar.horizontalPadding
            rightMargin: rootBar.theme.bar.horizontalPadding
        }
        height: rootBar.theme.bar.height
        radius: rootBar.theme.bar.backgroundRadius
        color: rootBar.theme.barBackground

        Row {
            id: leftSlot
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: rootBar.theme.bar.sideMargin
            }
            spacing: rootBar.theme.bar.itemSpacing

            OsdFeature.OsdTestButton {
                id: osdTestButton

                theme: rootBar.theme

                onClicked: rootBar.osdTestRequested("Qreep OSD test", rootBar.theme.osd.defaultDuration)
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }
        }

        Row {
            id: centerSlot

            anchors.centerIn: parent
            spacing: rootBar.theme.bar.itemSpacing

            ClockFeature.Clock {
                id: clock

                theme: rootBar.theme
                events: eventStore

                onRightClicked: calendarPopup.visible = !calendarPopup.visible
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            MprisFeature.MprisButton {
                id: mprisButton

                theme: rootBar.theme
                service: mprisService

                onClicked: {
                    mprisService.togglePlaying();
                    sharedTooltip.hideLater();
                    mprisTooltip.hideLater();
                }
                onRightClicked: {
                    mprisPanel.visible = !mprisPanel.visible;
                    sharedTooltip.hideLater();
                    mprisTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => {
                    sharedTooltip.hideLater();
                    mprisTooltip.showFor(anchorItem);
                }
                onTooltipHideRequested: mprisTooltip.hideLater()
            }
        }

        Row {
            id: rightSlot

            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: rootBar.theme.bar.sideMargin
            }
            spacing: rootBar.theme.bar.itemSpacing

            UpcheckerFeature.UpcheckerButton {
                id: upcheckerButton

                theme: rootBar.theme
                service: upcheckerService

                onClicked: {
                    upcheckerPanel.visible = !upcheckerPanel.visible;
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            MonitorProfileFeature.MonitorProfileButton {
                id: monitorProfileButton

                theme: rootBar.theme
                service: monitorProfileService

                onClicked: {
                    // monitorProfileService.applyNextProfile();
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            BorgFeature.Borg {
                id: borg

                theme: rootBar.theme
                service: borgService

                onClicked: {
                    borgService.refreshWithPulse();
                    sharedTooltip.hideLater();
                    borgTooltip.hideLater();
                }
                onRightClicked: {
                    borgService.runBackup();
                    sharedTooltip.hideLater();
                    borgTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => {
                    sharedTooltip.hideLater();
                    borgTooltip.showFor(anchorItem, borgService.tooltip, borgService.className);
                }
                onTooltipHideRequested: borgTooltip.hideLater()
            }

            PowerFeature.PowerButton {
                id: powerButton

                theme: rootBar.theme

                onClicked: {
                    powerPanel.visible = !powerPanel.visible;
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }
        }

        Item {
            id: overlayLayer

            anchors.fill: parent
            z: 10
        }

        SharedTooltip {
            id: sharedTooltip

            theme: rootBar.theme
        }

        BorgFeature.BorgTooltip {
            id: borgTooltip

            theme: rootBar.theme
        }

        MprisFeature.MprisTooltip {
            id: mprisTooltip

            theme: rootBar.theme
            service: mprisService
        }

        ClockFeature.CalendarPopup {
            id: calendarPopup

            theme: rootBar.theme
            anchorItem: clock
            events: eventStore
        }

        PowerFeature.PowerPanel {
            id: powerPanel

            theme: rootBar.theme

            onActionRequested: action => powerService.request(action)
        }

        UpcheckerFeature.UpcheckerPanel {
            id: upcheckerPanel

            theme: rootBar.theme
            service: upcheckerService
        }

        MprisFeature.MprisPanel {
            id: mprisPanel

            theme: rootBar.theme
            service: mprisService
            anchorItem: mprisButton
        }

        Connections {
            target: upcheckerService

            function onToggleRequested() {
                upcheckerPanel.visible = !upcheckerPanel.visible;
                sharedTooltip.hideLater();
            }

            function onUpdateRequested() {
                upcheckerPanel.visible = false;
            }
        }
    }
}

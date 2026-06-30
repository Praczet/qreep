import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../core" as Core
import "./features/borg" as BorgFeature
import "./features/clock" as ClockFeature
import "./features/power" as PowerFeature
import "./features/upchecker" as UpcheckerFeature
import "./features/monitorprofile" as MonitorProfileFeature
import "./features/mpris" as MprisFeature
import "./features/network" as NetworkFeature
import "./features/workspaces" as WorkspacesFeature
import "./features/launcher" as LauncherFeature
import "./features/battery" as BatteryFeature
import "./features/volume" as VolumeFeature

PanelWindow {
    id: rootBar

    required property QtObject theme

    property alias leftSlotItems: leftSlot.data
    property alias centerSlotItems: centerSlot.data
    property alias rightSlotItems: rightSlot.data
    property alias overlayItems: overlayLayer.data
    readonly property bool collapsed: barModeService.collapsed
    readonly property bool reservedMode: barModeService.reserved
    readonly property int activeBarHeight: collapsed ? rootBar.theme.modules.bar.collapsedHeight : rootBar.theme.modules.bar.height
    readonly property int activeTopPadding: collapsed ? 0 : rootBar.theme.modules.bar.topPadding

    signal volumeFeedbackRequested(int percent, bool muted, string icon)
    signal audioMixerRequested

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

    BarModeService {
        id: barModeService
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
    LauncherFeature.LauncherService {
        id: launcherService
        log: qreepLog
    }

    BatteryFeature.BatteryService {
        id: batteryService
        log: qreepLog
    }

    NetworkFeature.NetworkService {
        id: networkService
    }

    readonly property Process audioMixerRunner: Process {}

    Core.SoundService {
        id: soundService
        log: qreepLog
    }

    function openAudioMixer() {
        qreepLog.info("Launching pavucontrol.");
        audioMixerRunner.running = false;
        audioMixerRunner.command = ["pavucontrol"];
        audioMixerRunner.startDetached();
    }

    WorkspacesFeature.WorkspaceService {
        id: workspaceService
        log: qreepLog
        showEmptyWorkspaces: rootBar.theme.modules.bar.workspaces.showEmptyWorkspaces
        showSpecialWorkspaces: rootBar.theme.modules.bar.workspaces.showSpecialWorkspaces
        normalWorkspaceStart: rootBar.theme.modules.bar.workspaces.normalWorkspaceStart
        normalWorkspaceEnd: rootBar.theme.modules.bar.workspaces.normalWorkspaceEnd
        useHyprlandEvents: rootBar.theme.modules.bar.workspaces.useHyprlandEvents
        refreshInterval: rootBar.theme.modules.bar.workspaces.refreshInterval
        eventRefreshDelay: rootBar.theme.modules.bar.workspaces.eventRefreshDelay
        refreshAfterDispatchDelay: rootBar.theme.modules.bar.workspaces.refreshAfterDispatchDelay
        tooltipMaxWindows: rootBar.theme.modules.bar.workspaces.tooltipMaxWindows
    }

    BorgFeature.BorgService {
        id: borgService
        log: qreepLog
        refreshInterval: rootBar.theme.modules.bar.borg.refreshInterval
        backupCommand: [rootBar.theme.modules.bar.borg.backupCommand]
        backupStatusBackend: rootBar.theme.modules.bar.borg.backupStatusBackend
    }

    UpcheckerFeature.UpcheckerService {
        id: upcheckerService
        log: qreepLog
        updateTerminalCommand: rootBar.theme.modules.bar.upchecker.updateTerminalCommand
        updateCommand: rootBar.theme.modules.bar.upchecker.updateCommand
        restartCheckCommand: rootBar.theme.modules.bar.upchecker.restartCheckCommand
        restartCheckTimezone: rootBar.theme.modules.bar.upchecker.restartCheckTimezone
        restartSessionPackages: rootBar.theme.modules.bar.upchecker.restartSessionPackages
        restartRebootPackages: rootBar.theme.modules.bar.upchecker.restartRebootPackages
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: rootBar.activeBarHeight + rootBar.activeTopPadding
    color: "transparent"

    WlrLayershell.namespace: "qreep-bar"
    WlrLayershell.exclusiveZone: rootBar.reservedMode ? rootBar.implicitHeight : 0

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: rootBar.theme.modules.bar.horizontalPadding
            rightMargin: rootBar.theme.modules.bar.horizontalPadding
        }
        height: rootBar.activeBarHeight
        radius: rootBar.collapsed ? 0 : rootBar.theme.modules.bar.backgroundRadius
        color: rootBar.theme.modules.bar.backgroundColor
        clip: rootBar.collapsed

        Behavior on height {
            NumberAnimation {
                duration: rootBar.theme.animationFastDuration
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: leftSlot
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: rootBar.theme.modules.bar.sideMargin
            }
            spacing: rootBar.theme.modules.bar.itemSpacing
            scale: rootBar.collapsed ? 0.01 : 1
            opacity: rootBar.collapsed ? 0 : 1

            LauncherFeature.LauncherButton {
                id: launcherButton

                theme: rootBar.theme

                onClicked: {
                    launcherService.launchLauncher();
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }
            WorkspacesFeature.Workspaces {
                id: workspaces

                theme: rootBar.theme
                service: workspaceService

                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
                onWorkspaceTooltipShowRequested: (anchorItem, workspace) => {
                    sharedTooltip.hideLater();
                    workspaceClients.showFor(anchorItem, workspace);
                }
            }
        }

        Row {
            id: centerSlot

            anchors.centerIn: parent
            spacing: rootBar.theme.modules.bar.itemSpacing
            scale: rootBar.collapsed ? 0.01 : 1
            opacity: rootBar.collapsed ? 0 : 1

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
                rightMargin: rootBar.theme.modules.bar.sideMargin
            }
            spacing: rootBar.theme.modules.bar.itemSpacing
            scale: rootBar.collapsed ? 0.01 : 1
            opacity: rootBar.collapsed ? 0 : 1

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

            BatteryFeature.BatteryButton {
                id: battery

                theme: rootBar.theme
                service: batteryService

                onClicked: {
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            NetworkFeature.NetworkButton {
                id: networkButton

                theme: rootBar.theme
                service: networkService

                onClicked: {
                    networkPanel.visible = !networkPanel.visible;
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            VolumeFeature.VolumeButton {
                id: volumeButton

                theme: rootBar.theme
                service: soundService

                onClicked: {
                    soundService.toggleMute();
                    sharedTooltip.hideLater();
                }
                onRightClicked: {
                    rootBar.openAudioMixer();
                    rootBar.audioMixerRequested();
                    sharedTooltip.hideLater();
                }
                onVolumeChangedByScroll: sharedTooltip.hideLater()
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
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

        WorkspacesFeature.WorkspaceClients {
            id: workspaceClients

            theme: rootBar.theme
            service: workspaceService
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

        NetworkFeature.NetworkPanel {
            id: networkPanel

            theme: rootBar.theme
            service: networkService
            anchorItem: networkButton
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

        Connections {
            target: soundService

            function onSinkFeedbackRequested(percent, muted) {
                rootBar.volumeFeedbackRequested(percent, muted, soundService.volumeIcon(percent, muted));
            }
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: rootBar.theme.animationFastDuration
            easing.type: Easing.OutCubic
        }
    }
}

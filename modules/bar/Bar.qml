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
    readonly property int activeBarHeight: rootBar.theme.modules.bar.height
    readonly property int activeTopPadding: collapsed ? 0 : rootBar.theme.modules.bar.topPadding
    readonly property bool leftSlotActive: rootBar.pillSlotActive("workspaces")
    readonly property bool centerSlotActive: !collapsed || rootBar.anyPillEnabled(["clock", "mpris"])
    readonly property bool rightSlotActive: !collapsed || rootBar.anyPillEnabled(["upchecker", "monitorprofile", "borg", "battery", "network", "volume"])

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

    BarPillStateService {
        id: barPillStateService

        knownPills: ["clock", "workspaces", "mpris", "upchecker", "monitorprofile", "borg", "battery", "network", "volume"]
    }

    PowerFeature.Power {
        id: power

        theme: rootBar.theme
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

    function pillEnabled(id) {
        return barPillStateService.isVisible(id);
    }

    function pillPinned(id) {
        return barPillStateService.isPinned(id);
    }

    function pillCollapsed(id) {
        return rootBar.collapsed && pillEnabled(id) && !pillPinned(id);
    }

    function pillSlotActive(id) {
        return !rootBar.collapsed || pillEnabled(id);
    }

    function anyPillEnabled(ids) {
        for (let index = 0; index < ids.length; index++) {
            if (pillEnabled(ids[index]))
                return true;
        }

        return false;
    }

    function slotY(slot) {
        return rootBar.collapsed ? 0 : Math.max(0, (slot.parent.height - slot.height) / 2);
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
        backupStatePath: rootBar.theme.modules.bar.borg.backupStatePath
        backupFinalPath: rootBar.theme.modules.bar.borg.backupFinalPath
        backupPanelHideDelay: rootBar.theme.modules.bar.borg.backupPanelHideDelay
        backupStatePollInterval: rootBar.theme.modules.bar.borg.backupStatePollInterval
    }

    UpcheckerFeature.Upchecker {
        id: upchecker

        theme: rootBar.theme
        log: qreepLog
    }

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: rootBar.activeBarHeight + rootBar.activeTopPadding
    color: "transparent"
    mask: Region {
        regions: [
            Region {
                item: leftSlotMask
            },
            Region {
                item: centerSlotMask
            },
            Region {
                item: rightSlotMask
            }
        ]
    }

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
        radius: rootBar.theme.modules.bar.backgroundRadius
        color: rootBar.theme.modules.bar.backgroundColor

        Row {
            id: leftSlot
            anchors {
                left: parent.left
                leftMargin: rootBar.theme.modules.bar.sideMargin
            }
            y: rootBar.slotY(leftSlot)
            spacing: rootBar.theme.modules.bar.itemSpacing
            scale: rootBar.leftSlotActive ? 1 : 0.01
            opacity: rootBar.leftSlotActive ? 1 : 0

            LauncherFeature.LauncherButton {
                id: launcherButton

                visible: !rootBar.collapsed
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

                visible: rootBar.pillEnabled("workspaces")
                collapsedPill: rootBar.pillCollapsed("workspaces")
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

            anchors.horizontalCenter: parent.horizontalCenter
            y: rootBar.slotY(centerSlot)
            spacing: rootBar.theme.modules.bar.itemSpacing
            scale: rootBar.centerSlotActive ? 1 : 0.01
            opacity: rootBar.centerSlotActive ? 1 : 0

            ClockFeature.Clock {
                id: clock

                visible: rootBar.pillEnabled("clock")
                collapsedPill: rootBar.pillCollapsed("clock")
                theme: rootBar.theme
                events: eventStore

                onRightClicked: calendarPopup.visible = !calendarPopup.visible
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            MprisFeature.MprisButton {
                id: mprisButton

                visible: rootBar.pillEnabled("mpris")
                collapsedPill: rootBar.pillCollapsed("mpris")
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
                rightMargin: rootBar.theme.modules.bar.sideMargin
            }
            y: rootBar.slotY(rightSlot)
            spacing: rootBar.theme.modules.bar.itemSpacing
            scale: rootBar.rightSlotActive ? 1 : 0.01
            opacity: rootBar.rightSlotActive ? 1 : 0

            UpcheckerFeature.UpcheckerButton {
                id: upcheckerButton

                visible: rootBar.pillEnabled("upchecker")
                collapsedPill: rootBar.pillCollapsed("upchecker")
                theme: rootBar.theme
                service: upchecker.service

                onClicked: {
                    upchecker.toggle();
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }

            MonitorProfileFeature.MonitorProfileButton {
                id: monitorProfileButton

                visible: rootBar.pillEnabled("monitorprofile")
                collapsedPill: rootBar.pillCollapsed("monitorprofile")
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

                visible: rootBar.pillEnabled("borg")
                collapsedPill: rootBar.pillCollapsed("borg")
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
                    if (borgService.backupPanelOpen)
                        return;

                    sharedTooltip.hideLater();
                    borgTooltip.showFor(anchorItem, borgService.tooltip, borgService.className);
                }
                onTooltipHideRequested: borgTooltip.hideLater()
            }

            BatteryFeature.BatteryButton {
                id: battery

                visible: rootBar.pillEnabled("battery")
                collapsedPill: rootBar.pillCollapsed("battery")
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

                visible: rootBar.pillEnabled("network")
                collapsedPill: rootBar.pillCollapsed("network")
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

                visible: rootBar.pillEnabled("volume")
                collapsedPill: rootBar.pillCollapsed("volume")
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

                visible: !rootBar.collapsed
                theme: rootBar.theme

                service: power.service

                onClicked: {
                    powerButton.service.isFullscreen = false;
                    power.toggle();
                    sharedTooltip.hideLater();
                }
                onTooltipShowRequested: (anchorItem, title, content, style) => sharedTooltip.showFor(anchorItem, title, content, style)
                onTooltipHideRequested: sharedTooltip.hideLater()
            }
        }

        Item {
            id: leftSlotMask

            x: leftSlot.x
            y: leftSlot.y
            width: rootBar.leftSlotActive ? leftSlot.width : 0
            height: rootBar.leftSlotActive ? leftSlot.height : 0
            visible: width > 0 && height > 0
        }

        Item {
            id: centerSlotMask

            x: centerSlot.x
            y: centerSlot.y
            width: rootBar.centerSlotActive ? centerSlot.width : 0
            height: rootBar.centerSlotActive ? centerSlot.height : 0
            visible: width > 0 && height > 0
        }

        Item {
            id: rightSlotMask

            x: rightSlot.x
            y: rightSlot.y
            width: rootBar.rightSlotActive ? rightSlot.width : 0
            height: rootBar.rightSlotActive ? rightSlot.height : 0
            visible: width > 0 && height > 0
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

        BorgFeature.BorgProgressPopup {
            id: borgProgressPopup

            theme: rootBar.theme
            service: borgService
            anchorItem: borg

            onVisibleChanged: {
                if (visible)
                    borgTooltip.hideLater();
            }
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
            target: upchecker.service

            function onToggleRequested() {
                sharedTooltip.hideLater();
            }
        }

        Connections {
            target: power.service

            function onToggleRequested() {
                sharedTooltip.hideLater();
            }
        }

        Connections {
            target: soundService

            function onSinkFeedbackRequested(percent, muted) {
                rootBar.volumeFeedbackRequested(percent, muted, soundService.volumeIcon(percent, muted));
            }
        }

        Connections {
            target: barPillStateService

            function onPillStateChanged(id) {
                if (id === "clock" && !barPillStateService.isVisible(id))
                    calendarPopup.visible = false;

                if (id === "workspaces" && !barPillStateService.isVisible(id))
                    workspaceClients.visible = false;

                if (id === "mpris" && !barPillStateService.isVisible(id)) {
                    mprisPanel.visible = false;
                    mprisTooltip.hideLater();
                }

                if (id === "upchecker" && !barPillStateService.isVisible(id))
                    upchecker.hide();

                if (id === "borg" && !barPillStateService.isVisible(id))
                    borgTooltip.hideLater();

                if (id === "network" && !barPillStateService.isVisible(id))
                    networkPanel.visible = false;

                sharedTooltip.hideLater();
            }
        }
    }
}

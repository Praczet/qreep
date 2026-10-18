import QtQuick

// /qreep curation. The live list still comes from `quickshell ipc show`;
// this only decides how a function is presented: label, group, icon, and
// whether a person typing in a launcher should see it at all.
//
// Precedence: actions > debug > hidden. Anything the shell registers that is
// not mentioned here lands in "Uncatalogued", visible, so new IPC nags until
// someone decides what it is instead of vanishing quietly.
//
// Exact "target function args" still calls hidden functions. The catalog
// tidies the list; it is not a permission system.
QtObject {
    id: rootKipQreepCatalog

    readonly property var groups: [
        { id: "surfaces", title: "Surfaces", icon: "󰕮" },
        { id: "system", title: "System", icon: "󰒓" },
        { id: "timer", title: "Timer", icon: "󰔛" },
        { id: "bar", title: "Bar", icon: "󱔓" },
        { id: "qreeper", title: "Qreeper", icon: "󰆋" },
        { id: "new", title: "Uncatalogued", icon: "󰘥" },
        { id: "debug", title: "Debug", icon: "󰨰" },
        { id: "hidden", title: "Hidden", icon: "󰅩" }
    ]

    // Fallback icon per target, for debug/hidden/uncatalogued rows.
    readonly property var targetIcons: ({
            "qreep-aegis": "󰞀",
            "qreep-bar": "󱔓",
            "qreep-bar-pill": "󰔡",
            "qreep-bloom": "󰉁",
            "qreep-borg": "󰀼",
            "qreep-calendar": "󰃭",
            "qreep-clipboard": "󱉫",
            "qreep-dashboard": "󰕮",
            "qreep-expose": "󰕰",
            "qreep-fast-password": "󰌋",
            "qreep-kip": "󰚩",
            "qreep-language": "󰗊",
            "qreep-monitor-profile": "󰍹",
            "qreep-mpris": "󰝚",
            "qreep-notification": "󰂚",
            "qreep-polkit": "󰯄",
            "qreep-potato-fast": "󰉁",
            "qreep-power": "󰐥",
            "qreep-qreeper": "󰆋",
            "qreep-screenshot": "󰹑",
            "qreep-timer": "󰔛",
            "qreep-triage": "󰏖",
            "qreep-upchecker": "󰏕",
            "osd": "󰍪"
        })

    readonly property var pillIds: ["clock", "workspaces", "mpris", "timer", "upchecker", "monitorprofile", "borg", "potato-fast", "battery", "network", "language", "volume", "qreeper", "tray"]

    // The curated list, in display order inside each group.
    readonly property var actions: [
        // Surfaces
        { key: "qreep-dashboard.toggle", group: "surfaces", label: "Dashboard", icon: "󰕮" },
        { key: "qreep-aegis.toggle", group: "surfaces", label: "Aegis", icon: "󰞀" },
        { key: "qreep-aegis.setMode", group: "surfaces", label: "Aegis mode", icon: "󰞀", choices: ["minimal", "summary", "full"] },
        { key: "qreep-expose.toggle", group: "surfaces", label: "Expose", icon: "󰕰" },
        { key: "qreep-clipboard.toggle", group: "surfaces", label: "Clipboard history", icon: "󱉫" },
        { key: "qreep-screenshot.toggle", group: "surfaces", label: "Screenshot", icon: "󰹑" },
        { key: "qreep-fast-password.toggle", group: "surfaces", label: "Fast Password", icon: "󰌋" },
        { key: "qreep-notification.toggleCenter", group: "surfaces", label: "Notification center", icon: "󰂚" },
        { key: "qreep-notification.dismissAll", group: "surfaces", label: "Dismiss all notifications", icon: "󰎟" },

        // System
        { key: "qreep-power.toggle", group: "system", label: "Power menu", icon: "󰐥" },
        { key: "qreep-power.toggleFullscreen", group: "system", label: "Power menu, full screen", icon: "󰊓" },
        { key: "qreep-upchecker.toggle", group: "system", label: "Updates panel", icon: "󰏕" },
        { key: "qreep-upchecker.refresh", group: "system", label: "Check for updates", icon: "󰑐" },
        { key: "qreep-upchecker.update", group: "system", label: "Run system update", icon: "󰚰" },
        { key: "qreep-triage.toggle", group: "system", label: "Package triage", icon: "󰏖" },
        { key: "qreep-triage.showUpdates", group: "system", label: "Triage pending updates", icon: "󰏔" },
        { key: "qreep-triage.showPackage", group: "system", label: "Explain a package", icon: "󱁴" },
        { key: "qreep-borg.toggleProgress", group: "system", label: "Backup progress", icon: "󰀼" },
        { key: "qreep-borg.refresh", group: "system", label: "Check backup status", icon: "󰁯" },
        { key: "qreep-language.next", group: "system", label: "Next keyboard layout", icon: "󰗊" },

        // Timer (starting one is /timer's job)
        { key: "qreep-timer.toggle", group: "timer", label: "Timer panel", icon: "󰔛" },
        { key: "qreep-timer.toggleRunning", group: "timer", label: "Pause / resume timer", icon: "󱫞" },
        { key: "qreep-timer.stop", group: "timer", label: "Stop timer", icon: "󱫪" },
        { key: "qreep-timer.setNotificationMode", group: "timer", label: "Timer alert style", icon: "󱨩", choices: ["osd", "notify"] },

        // Bar
        { key: "qreep-bar.setReserved", group: "bar", label: "Bar: reserved", icon: "󱔓" },
        { key: "qreep-bar.setOverlay", group: "bar", label: "Bar: overlay", icon: "󰧾" },
        { key: "qreep-bar.setCollapsed", group: "bar", label: "Bar: collapsed", icon: "󰞕" },
        { key: "qreep-bar-pill.togglePill", group: "bar", label: "Show / hide a pill", icon: "󰔡", choices: pillIds },
        { key: "qreep-bar-pill.togglePinned", group: "bar", label: "Pin / unpin a pill", icon: "󰤱", choices: pillIds },

        // Qreeper: asleep until a session starts
        { key: "qreep-qreeper.start", group: "qreeper", label: "Start Qreeper session", icon: "󰐊" },
        { key: "qreep-qreeper.stop", group: "qreeper", label: "Stop Qreeper session", icon: "󰓛" },
        { key: "qreep-qreeper.toggleMinimap", group: "qreeper", label: "Minimap", icon: "󰍍" },
        { key: "qreep-qreeper.toggleAtlas", group: "qreeper", label: "Atlas", icon: "󰨁" },
        { key: "qreep-qreeper.recenter", group: "qreeper", label: "Recenter minimap", icon: "󰆤" },
        { key: "qreep-qreeper.resetLayout", group: "qreeper", label: "Reset map layout", icon: "󰦛" },
        { key: "qreep-qreeper.fontBigger", group: "qreeper", label: "Map text bigger", icon: "󰧴" },
        { key: "qreep-qreeper.fontSmaller", group: "qreeper", label: "Map text smaller", icon: "󰧳" }
    ]

    // Useful when poking at the shell, noise when launching things.
    readonly property var debug: [
        "qreep-polkit.showLog", "qreep-polkit.demo", "qreep-polkit.registrationState", "qreep-polkit.logPath", "qreep-polkit.toggle",
        "qreep-aegis.copyText", "qreep-aegis.copyJson",
        "qreep-bar.getMode", "qreep-bar-pill.listPills", "qreep-bar-pill.state",
        "qreep-mpris.state", "qreep-language.state", "qreep-screenshot.state",
        "qreep-qreeper.state", "qreep-qreeper.fontScale", "qreep-qreeper.setFontScale", "qreep-qreeper.resetFontScale", "qreep-qreeper.rearrange"
    ]

    // "target.*" hides a whole target, "*.name" a function everywhere.
    // Hooks other programs call, duplicates of a curated action, and KIP itself.
    readonly property var hidden: [
        "qreep-kip.*", "osd.*", "qreep-bloom.*", "qreep-calendar.*", "qreep-monitor-profile.*",
        "qreep-fast-password.copy",
        "*.showMe", "*.hideMe", "*.refresh",
        "qreep-notification.toggle", "qreep-notification.showCenter", "qreep-notification.hideCenter",
        "qreep-notification.togglePopup", "qreep-notification.showPopup", "qreep-notification.hidePopup",
        "qreep-timer.pause", "qreep-timer.resume", "qreep-timer.startTimer", "qreep-timer.startCountdown", "qreep-timer.startCountdownUntil",
        "qreep-bar.toggleOverlay", "qreep-bar.toggleCollapsed", "qreep-bar.setMode",
        "qreep-bar-pill.enablePill", "qreep-bar-pill.disablePill", "qreep-bar-pill.expandPill", "qreep-bar-pill.collapsePill",
        "qreep-borg.showProgress", "qreep-borg.hideProgress",
        "qreep-triage.update",
        "qreep-qreeper.showMinimap", "qreep-qreeper.hideMinimap", "qreep-qreeper.showAtlas", "qreep-qreeper.hideAtlas"
    ]

    readonly property var actionIndex: {
        const index = {};

        for (let rank = 0; rank < actions.length; rank++)
            index[actions[rank].key] = Object.assign({ rank: rank }, actions[rank]);
        return index;
    }

    function groupRank(id) {
        const rank = groups.findIndex(group => group.id === id);

        return rank >= 0 ? rank : groups.length;
    }

    function group(id) {
        return groups.find(candidate => candidate.id === id) || groups[groups.length - 1];
    }

    function isHidden(target, name) {
        return hidden.some(pattern => pattern === target + "." + name || pattern === target + ".*" || pattern === "*." + name);
    }

    // { group, label, icon, choices, rank, visible }
    function describe(target, name) {
        const key = target + "." + name;
        const action = actionIndex[key];
        const icon = targetIcons[target] || "󰅩";

        if (action) {
            return {
                group: action.group,
                label: action.label,
                icon: action.icon || icon,
                choices: action.choices || [],
                rank: action.rank,
                visible: true
            };
        }

        const groupId = debug.indexOf(key) >= 0 ? "debug" : isHidden(target, name) ? "hidden" : "new";

        return {
            group: groupId,
            label: "",
            icon: icon,
            choices: [],
            rank: actions.length,
            visible: groupId === "new"
        };
    }
}

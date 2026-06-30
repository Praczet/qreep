import QtQuick
import Quickshell.Io

QtObject {
    id: rootBarPillStateService

    property var hiddenPills: ({})
    property var pinnedPills: ({})

    signal pillStateChanged(string id)

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-bar-pill"

        function showPill(id: string): string {
            return rootBarPillStateService.show(id);
        }

        function hidePill(id: string): string {
            return rootBarPillStateService.hide(id);
        }

        function togglePill(id: string): string {
            return rootBarPillStateService.toggle(id);
        }

        function pin(id: string): string {
            return rootBarPillStateService.pin(id);
        }

        function unpin(id: string): string {
            return rootBarPillStateService.unpin(id);
        }

        function togglePinned(id: string): string {
            return rootBarPillStateService.togglePinned(id);
        }

        function state(id: string): string {
            return rootBarPillStateService.state(id);
        }
    }

    function isVisible(id) {
        return !hiddenPills[normalizeId(id)];
    }

    function isPinned(id) {
        return !!pinnedPills[normalizeId(id)];
    }

    function show(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        setFlag("hidden", normalized, false);
        return state(normalized);
    }

    function hide(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        setFlag("hidden", normalized, true);
        return state(normalized);
    }

    function toggle(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        setFlag("hidden", normalized, !hiddenPills[normalized]);
        return state(normalized);
    }

    function pin(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        setFlag("pinned", normalized, true);
        return state(normalized);
    }

    function unpin(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        setFlag("pinned", normalized, false);
        return state(normalized);
    }

    function togglePinned(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        setFlag("pinned", normalized, !pinnedPills[normalized]);
        return state(normalized);
    }

    function state(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        return normalized + " visible=" + isVisible(normalized) + " pinned=" + isPinned(normalized);
    }

    function setFlag(kind, id, enabled) {
        const source = kind === "hidden" ? hiddenPills : pinnedPills;
        const updated = copyMap(source);

        if (enabled)
            updated[id] = true;
        else
            delete updated[id];

        if (kind === "hidden")
            hiddenPills = updated;
        else
            pinnedPills = updated;

        pillStateChanged(id);
    }

    function copyMap(source) {
        const updated = {};

        for (const key in source)
            updated[key] = source[key];

        return updated;
    }

    function normalizeId(id) {
        return String(id || "").trim().toLowerCase();
    }
}

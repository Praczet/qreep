import QtQuick
import Quickshell.Io

QtObject {
    id: rootBarPillStateService

    property var knownPills: []
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

        function listPills(): string {
            return rootBarPillStateService.listPills();
        }
    }

    function isVisible(id) {
        const normalized = normalizeId(id);
        return isKnownPill(normalized) && !hiddenPills[normalized];
    }

    function isPinned(id) {
        const normalized = normalizeId(id);
        return isKnownPill(normalized) && !!pinnedPills[normalized];
    }

    function show(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        if (!isKnownPill(normalized))
            return unknownPillMessage(normalized);

        setFlag("hidden", normalized, false);
        return state(normalized);
    }

    function hide(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        if (!isKnownPill(normalized))
            return unknownPillMessage(normalized);

        setFlag("hidden", normalized, true);
        return state(normalized);
    }

    function toggle(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        if (!isKnownPill(normalized))
            return unknownPillMessage(normalized);

        setFlag("hidden", normalized, !hiddenPills[normalized]);
        return state(normalized);
    }

    function pin(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        if (!isKnownPill(normalized))
            return unknownPillMessage(normalized);

        setFlag("pinned", normalized, true);
        return state(normalized);
    }

    function unpin(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        if (!isKnownPill(normalized))
            return unknownPillMessage(normalized);

        setFlag("pinned", normalized, false);
        return state(normalized);
    }

    function togglePinned(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        if (!isKnownPill(normalized))
            return unknownPillMessage(normalized);

        setFlag("pinned", normalized, !pinnedPills[normalized]);
        return state(normalized);
    }

    function state(id) {
        const normalized = normalizeId(id);

        if (normalized.length === 0)
            return "";

        if (!isKnownPill(normalized))
            return unknownPillMessage(normalized);

        return normalized + " visible=" + isVisible(normalized) + " pinned=" + isPinned(normalized);
    }

    function listPills() {
        const rows = [];

        for (let index = 0; index < knownPills.length; index++) {
            const id = normalizeId(knownPills[index]);

            if (id.length > 0)
                rows.push(state(id));
        }

        return rows.join("\n");
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

    function isKnownPill(id) {
        const normalized = normalizeId(id);

        for (let index = 0; index < knownPills.length; index++) {
            if (normalizeId(knownPills[index]) === normalized)
                return true;
        }

        return false;
    }

    function knownPillList() {
        const ids = [];

        for (let index = 0; index < knownPills.length; index++) {
            const id = normalizeId(knownPills[index]);

            if (id.length > 0)
                ids.push(id);
        }

        return ids.join(", ");
    }

    function unknownPillMessage(id) {
        return "unknown pill: " + id + " (known: " + knownPillList() + ")";
    }
}

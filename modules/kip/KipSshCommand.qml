import QtQuick

// /ssh as the panel sees it: the hosts Places' ssh blocks show (same
// service, so the two never disagree), filtered by the typed words, with
// user@address and reachability on the second line. Enter opens the host in
// kitty via kitten ssh, like Places does. host is KipPanel.
Item {
    id: rootKipSshCommand

    required property QtObject host
    property QtObject places: null

    readonly property QtObject service: places ? places.service : null
    readonly property bool active: host.contentState === "ssh"
    property int index: 0
    property string query: ""
    readonly property var matches: service ? filter(service.sshHosts, query) : []
    readonly property var results: matches.map(item => row(item))
    readonly property bool listVisible: active && results.length > 0
    readonly property string eventKey: service === null ? "ssh.error" : query.trim().length === 0 ? "ssh.ready" : results.length > 0 ? "ssh.found" : "ssh.empty"

    function reset() {
        query = "";
        index = 0;
    }

    // "/ssh " lists every host; typing narrows them (name, host, address).
    // Each show re-checks reachability, the same TCP poke Places does.
    function show() {
        if (!active) {
            host.backToCompose();
            host.contentState = "ssh";
            index = 0;
            if (service)
                service.checkSsh();
        }
        query = host.parsed.argument;
        index = Math.min(index, Math.max(0, results.length - 1));
    }

    function filter(list, text) {
        const words = String(text || "").toLowerCase().split(/\s+/).filter(word => word.length > 0);

        if (words.length === 0)
            return list;

        return list.filter(item => {
            const haystack = (item.label + " " + item.host + " " + item.detail).toLowerCase();
            return words.every(word => haystack.indexOf(word) >= 0);
        });
    }

    // KipResultList shape: origin chip = reachability, or "prod" when kitty's
    // ssh.conf gives the host the prod theme (reachability then goes below).
    // Unreachable hosts are dimmed but still selectable.
    function row(item) {
        const state = service.sshReachable[item.host] || "";
        const prod = service.sshLevel(item) === "prod";
        const parts = [];

        if (item.detail)
            parts.push(item.detail);
        if (item.label !== item.host)
            parts.push(item.host);
        if (prod && state === "down")
            parts.push("unreachable");

        return {
            origin: prod ? "prod" : state === "up" ? "up" : state === "down" ? "down" : "ssh",
            folder: "",
            file: item.label,
            excerpt: parts.join(" · "),
            weak: state === "down"
        };
    }

    function submit(shifted) {
        const item = matches[index];

        if (!item)
            return;

        service.openSsh(item);
        host.closeRequested();
    }

    function handleKey(event) {
        if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && listVisible) {
            index = host.clampIndex(index + (event.key === Qt.Key_Down ? 1 : -1), results.length);
            event.accepted = true;
            return true;
        }
        return false;
    }

    function status() {
        if (service === null)
            return "Places is not loaded";
        if (service.configError.length > 0)
            return service.configError;

        const total = service.sshHosts.length;
        const up = service.sshHosts.filter(item => service.sshReachable[item.host] === "up").length;
        const count = results.length === total ? total + " hosts" : results.length + " of " + total + " hosts";
        return Object.keys(service.sshReachable).length > 0 ? count + " · " + up + " reachable" : count;
    }

    function enterLabel() {
        return listVisible ? "connect" : "";
    }

    function keyHints() {
        return listVisible ? "↑↓ choose · Enter kitten ssh · Esc back" : "Esc back · fewer words?";
    }
}

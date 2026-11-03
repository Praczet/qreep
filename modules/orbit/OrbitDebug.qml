import QtQuick

// F1: what Orbit thinks it is showing, and which file each thing came from.
// Read-only. It formats what the service already knows.
Rectangle {
    id: rootOrbitDebug

    required property QtObject ot
    required property QtObject service
    property bool shown: false

    readonly property string selectedReport: nodeReport(service.selectedNode)
    readonly property string currentReport: contextReport() + "\n" + nodeReport(service.current)

    width: ot.debugWidth
    height: Math.min(content.implicitHeight + 2 * ot.debugPadding, parent.height - 2 * ot.screenMargin)
    radius: ot.debugRadius
    clip: true
    color: ot.debugColor
    border.width: ot.borderWidth
    border.color: ot.nodeBorderColor
    opacity: shown ? 1 : 0
    visible: opacity > 0.001

    Behavior on opacity {
        NumberAnimation {
            duration: rootOrbitDebug.ot.selectDuration
        }
    }

    // Clicks here are not clicks outside Orbit.
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: rootOrbitDebug.ot.debugPadding
        spacing: rootOrbitDebug.ot.debugPadding

        Repeater {
            model: [
                {
                    title: "Selected",
                    report: rootOrbitDebug.selectedReport
                },
                {
                    title: "Current",
                    report: rootOrbitDebug.currentReport
                }
            ]

            Column {
                required property var modelData

                width: content.width
                spacing: 4

                Text {
                    text: parent.modelData.title
                    color: rootOrbitDebug.ot.selectedColor
                    font.family: rootOrbitDebug.ot.debugFontFamily
                    font.pixelSize: rootOrbitDebug.ot.debugPixelSize
                    font.bold: true
                }

                Text {
                    width: parent.width
                    textFormat: Text.PlainText
                    wrapMode: Text.WrapAnywhere
                    text: parent.modelData.report
                    color: rootOrbitDebug.ot.textColor
                    font.family: rootOrbitDebug.ot.debugFontFamily
                    font.pixelSize: rootOrbitDebug.ot.debugPixelSize
                }
            }
        }
    }

    function shortPath(path) {
        return String(path).replace(service.home + "/", "~/");
    }

    function actionOf(node) {
        if (node.app)
            return "app " + node.app;
        if (node.exec)
            return "exec " + (Array.isArray(node.exec) ? node.exec.join(" ") : JSON.stringify(node.exec));
        if (node.ipc)
            return "ipc " + (Array.isArray(node.ipc) ? node.ipc.join(" ") : JSON.stringify(node.ipc));
        return "none";
    }

    function nodeReport(node) {
        if (!node)
            return "nothing";

        const lines = [
            "name: " + node.name,
            "label: " + node.text + (node.key ? "  key: " + node.key : ""),
            "id: " + node.id,
            "source: " + shortPath(node.source) + (node.fromDoc ? " (built from its doc)" : ""),
            "action: " + shortPath(actionOf(node))
        ];

        if (node.itemsSourcePath)
            lines.push("itemsSource: " + shortPath(node.itemsSourcePath));
        if (node.docPath)
            lines.push("doc: " + shortPath(node.docPath));
        if (node.sourceError)
            lines.push("error: " + shortPath(node.sourceError));
        lines.push("items: " + node.items.length);
        node.items.forEach((child, index) => lines.push((node === service.current && index === service.selectedIndex ? "  > " : "  - ") + child.name));
        return lines.join("\n");
    }

    function contextReport() {
        const trail = service.trail.map(step => step.node.name);
        const lines = [
            "file: " + shortPath(service.rootPath),
            "path: " + trail.concat(service.current ? [service.current.name] : []).join(" > "),
            "typed: " + (service.typed || "-"),
            "files read: " + Object.keys(service.files).map(path => path.replace(/^.*\//, "")).join(", ")
        ];

        if (service.error)
            lines.push("error: " + shortPath(service.error));
        return lines.join("\n");
    }
}

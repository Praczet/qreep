import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: rootWorkspaceClients

    required property QtObject theme
    required property QtObject service

    property Item anchorItem
    property var workspace: ({ clients: [] })
    property real popupX: 0
    property real popupY: 0
    readonly property var clients: workspace && workspace.clients ? workspace.clients : []
    readonly property real popupWidth: rootWorkspaceClients.theme.workspaces.tooltipWidth
    readonly property real popupHeight: tooltipLayout.implicitHeight + rootWorkspaceClients.theme.tooltip.verticalPadding * 2
    readonly property real popupMargin: rootWorkspaceClients.theme.bar.topPadding

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: false
    color: "transparent"

    WlrLayershell.namespace: "qreep-popup-workspace-clients"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusiveZone: 0

    onWidthChanged: {
        if (visible)
            updatePosition();
    }

    onHeightChanged: {
        if (visible)
            updatePosition();
    }

    onPopupHeightChanged: {
        if (visible)
            updatePosition();
    }

    onVisibleChanged: {
        if (!visible) {
            rootWorkspaceClients.anchorItem = null;
            rootWorkspaceClients.workspace = ({ clients: [] });
        }
    }

    function showFor(anchorItem, workspace) {
        if (!anchorItem)
            return;

        rootWorkspaceClients.anchorItem = anchorItem;
        rootWorkspaceClients.workspace = workspace || ({ clients: [] });
        rootWorkspaceClients.visible = true;
        rootWorkspaceClients.updatePosition();
        background.forceActiveFocus();
    }

    function hideLater() {
        finishHide();
    }

    function finishHide() {
        rootWorkspaceClients.visible = false;
    }

    function updatePosition() {
        if (!rootWorkspaceClients.anchorItem)
            return;

        const anchorPoint = rootWorkspaceClients.anchorItem.mapToGlobal(Qt.point(rootWorkspaceClients.anchorItem.width / 2, 0));
        const preferredX = anchorPoint.x - rootWorkspaceClients.popupWidth / 2 + rootWorkspaceClients.popupMargin;

        rootWorkspaceClients.popupX = Math.max(rootWorkspaceClients.popupMargin, Math.min(preferredX, rootWorkspaceClients.width - rootWorkspaceClients.popupWidth - rootWorkspaceClients.popupMargin));
        rootWorkspaceClients.popupY = rootWorkspaceClients.popupMargin;
    }

    function appLabel(client) {
        return rootWorkspaceClients.service.appLabel(client);
    }

    function iconName(client) {
        const label = appLabel(client).toLowerCase();

        if (label === "ghostty")
            return "com.mitchellh.ghostty";

        return label;
    }

    function windowTitle(client) {
        const title = String(client.title || "").trim();

        return title.length > 0 ? title : appLabel(client);
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootWorkspaceClients.visible
        onActivated: rootWorkspaceClients.finishHide()
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true

        MouseArea {
            anchors.fill: parent
            onClicked: rootWorkspaceClients.finishHide()
        }
    }

    Rectangle {
        id: tooltipBody

        x: rootWorkspaceClients.popupX
        y: rootWorkspaceClients.popupY
        width: rootWorkspaceClients.popupWidth
        height: rootWorkspaceClients.popupHeight
        transformOrigin: Item.Center
        radius: rootWorkspaceClients.theme.tooltip.radius
        color: rootWorkspaceClients.theme.workspaces.backgroundColor
        border.width: rootWorkspaceClients.theme.tooltip.borderWidth
        border.color: rootWorkspaceClients.theme.workspaces.borderColor

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            id: tooltipLayout

            anchors {
                fill: parent
                margins: rootWorkspaceClients.theme.tooltip.padding
            }
            spacing: rootWorkspaceClients.theme.workspaces.tooltipRowSpacing

            Text {
                width: parent.width
                text: rootWorkspaceClients.workspace.tooltipTitle || "Workspace"
                color: rootWorkspaceClients.theme.calendarHeaderText
                font.pixelSize: rootWorkspaceClients.theme.workspaces.tooltipTitlePixelSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Repeater {
                model: rootWorkspaceClients.clients

                delegate: Rectangle {
                    id: windowRow

                    required property var modelData

                    width: tooltipLayout.width
                    height: rootWorkspaceClients.theme.workspaces.tooltipRowHeight
                    radius: rootWorkspaceClients.theme.workspaces.tooltipRowRadius
                    color: rowMouseArea.containsMouse ? rootWorkspaceClients.theme.moduleHoverBackground : "transparent"

                    Row {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: rootWorkspaceClients.theme.workspaces.tooltipContentSpacing

                        IconImage {
                            width: rootWorkspaceClients.theme.workspaces.tooltipIconSize
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            source: Quickshell.iconPath(rootWorkspaceClients.iconName(windowRow.modelData), "application-x-executable-symbolic")
                        }

                        Text {
                            width: parent.width - rootWorkspaceClients.theme.workspaces.tooltipIconSize - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            text: rootWorkspaceClients.windowTitle(windowRow.modelData)
                            color: rootWorkspaceClients.theme.calendarDayText
                            font.pixelSize: rootWorkspaceClients.theme.workspaces.tooltipWindowPixelSize
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: rowMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootWorkspaceClients.finishHide();
                            rootWorkspaceClients.service.focusClient(windowRow.modelData);
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: rootWorkspaceClients.theme.animationFastDuration
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: rootWorkspaceClients.clients.length === 0
                text: "No windows"
                color: rootWorkspaceClients.theme.calendarMutedText
                font.pixelSize: rootWorkspaceClients.theme.workspaces.tooltipWindowPixelSize
            }
        }
    }
}

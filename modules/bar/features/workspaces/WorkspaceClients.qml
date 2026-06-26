import QtQuick
import Quickshell
import Quickshell.Widgets

PopupWindow {
    id: rootWorkspaceClients

    required property QtObject theme
    required property QtObject service

    property Item anchorItem
    property var workspace: ({ clients: [] })
    readonly property var clients: workspace && workspace.clients ? workspace.clients : []

    anchor {
        item: rootWorkspaceClients.anchorItem
        rect.x: rootWorkspaceClients.anchorItem ? rootWorkspaceClients.anchorItem.width / 2 - rootWorkspaceClients.width / 2 : 0
        rect.y: rootWorkspaceClients.anchorItem ? rootWorkspaceClients.anchorItem.height + rootWorkspaceClients.theme.tooltip.offsetY : 0
    }

    implicitWidth: rootWorkspaceClients.theme.workspaces.tooltipWidth
    implicitHeight: tooltipLayout.implicitHeight + rootWorkspaceClients.theme.tooltip.verticalPadding * 2
    color: "transparent"
    grabFocus: false

    function showFor(anchorItem, workspace) {
        if (!anchorItem)
            return;

        rootWorkspaceClients.anchorItem = anchorItem;
        rootWorkspaceClients.workspace = workspace || ({ clients: [] });
        rootWorkspaceClients.visible = true;
    }

    function hideLater() {
        finishHide();
    }

    function finishHide() {
        rootWorkspaceClients.visible = false;
        rootWorkspaceClients.anchorItem = null;
        rootWorkspaceClients.workspace = ({ clients: [] });
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

    Rectangle {
        id: tooltipBody

        anchors.fill: parent
        transformOrigin: Item.Center
        radius: rootWorkspaceClients.theme.tooltip.radius
        color: rootWorkspaceClients.theme.calendarBackground
        border.width: rootWorkspaceClients.theme.tooltip.borderWidth
        border.color: rootWorkspaceClients.theme.moduleHoverBackground

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

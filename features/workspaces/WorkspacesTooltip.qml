import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: rootWorkspacesTooltip

    required property QtObject theme
    required property QtObject service

    property var workspace: ({ clients: [] })
    property real popupX: 0
    property real popupY: 0
    readonly property var clients: workspace && workspace.clients ? workspace.clients : []

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
    }
    height: Math.max(parent.height, rootWorkspacesTooltip.popupY + tooltipBody.height + 8)
    visible: false
    z: 50

    function showFor(anchorItem, workspace) {
        rootWorkspacesTooltip.workspace = workspace || ({ clients: [] });
        setPosition(anchorItem);
        rootWorkspacesTooltip.visible = true;
        tooltipBody.scale = 1;
    }

    function setPosition(anchorItem) {
        if (!anchorItem) {
            popupX = 0;
            popupY = 0;
            return;
        }

        const mapped = anchorItem.mapToItem(rootWorkspacesTooltip, anchorItem.width / 2, anchorItem.height + rootWorkspacesTooltip.theme.tooltip.offsetY);
        const preferredX = mapped.x - rootWorkspacesTooltip.theme.workspaces.tooltipWidth / 2;
        const maxX = Math.max(0, rootWorkspacesTooltip.width - rootWorkspacesTooltip.theme.workspaces.tooltipWidth);

        popupX = Math.max(0, Math.min(preferredX, maxX));
        popupY = mapped.y;
    }

    function hideLater() {
        finishHide();
    }

    function finishHide() {
        resetHiddenState();
    }

    function resetHiddenState() {
        tooltipBody.scale = 0;
        visible = false;
        workspace = ({ clients: [] });
    }

    function appLabel(client) {
        return rootWorkspacesTooltip.service.appLabel(client);
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

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 0
        onClicked: rootWorkspacesTooltip.finishHide()
    }

    Rectangle {
        id: tooltipBody

        x: rootWorkspacesTooltip.popupX
        y: rootWorkspacesTooltip.popupY
        z: 1
        width: rootWorkspacesTooltip.theme.workspaces.tooltipWidth
        height: tooltipLayout.implicitHeight + rootWorkspacesTooltip.theme.tooltip.verticalPadding * 2
        transformOrigin: Item.Center
        scale: 0
        radius: rootWorkspacesTooltip.theme.tooltip.radius
        color: rootWorkspacesTooltip.theme.calendarBackground
        border.width: rootWorkspacesTooltip.theme.tooltip.borderWidth
        border.color: rootWorkspacesTooltip.theme.moduleHoverBackground

        Column {
            id: tooltipLayout

            anchors {
                fill: parent
                margins: rootWorkspacesTooltip.theme.tooltip.padding
            }
            spacing: rootWorkspacesTooltip.theme.workspaces.tooltipRowSpacing

            Text {
                width: parent.width
                text: rootWorkspacesTooltip.workspace.tooltipTitle || "Workspace"
                color: rootWorkspacesTooltip.theme.calendarHeaderText
                font.pixelSize: rootWorkspacesTooltip.theme.workspaces.tooltipTitlePixelSize
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Repeater {
                model: rootWorkspacesTooltip.clients

                delegate: Rectangle {
                    id: windowRow

                    required property var modelData

                    width: tooltipLayout.width
                    height: rootWorkspacesTooltip.theme.workspaces.tooltipRowHeight
                    radius: rootWorkspacesTooltip.theme.workspaces.tooltipRowRadius
                    color: rowMouseArea.containsMouse ? rootWorkspacesTooltip.theme.moduleHoverBackground : "transparent"

                    Row {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 8
                            rightMargin: 8
                        }
                        spacing: rootWorkspacesTooltip.theme.workspaces.tooltipContentSpacing

                        IconImage {
                            width: rootWorkspacesTooltip.theme.workspaces.tooltipIconSize
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            source: Quickshell.iconPath(rootWorkspacesTooltip.iconName(windowRow.modelData), "application-x-executable-symbolic")
                        }

                        Text {
                            width: parent.width - rootWorkspacesTooltip.theme.workspaces.tooltipIconSize - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            text: rootWorkspacesTooltip.windowTitle(windowRow.modelData)
                            color: rootWorkspacesTooltip.theme.calendarDayText
                            font.pixelSize: rootWorkspacesTooltip.theme.workspaces.tooltipWindowPixelSize
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: rowMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootWorkspacesTooltip.service.focusClient(windowRow.modelData);
                            rootWorkspacesTooltip.finishHide();
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: rootWorkspacesTooltip.theme.animationFastDuration
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: rootWorkspacesTooltip.clients.length === 0
                text: "No windows"
                color: rootWorkspacesTooltip.theme.calendarMutedText
                font.pixelSize: rootWorkspacesTooltip.theme.workspaces.tooltipWindowPixelSize
            }
        }

    }

}

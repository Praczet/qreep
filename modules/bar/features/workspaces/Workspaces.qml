import QtQuick

Rectangle {
    id: rootWorkspaces

    required property QtObject theme
    required property QtObject service

    signal tooltipShowRequested(Item anchorItem, string title, string content, string style)
    signal tooltipHideRequested
    signal workspaceTooltipShowRequested(Item anchorItem, var workspace)

    implicitWidth: workspaceRow.implicitWidth + theme.modules.bar.pill.horizontalPadding
    implicitHeight: theme.modules.bar.pill.height
    radius: theme.modules.bar.pill.radius
    color: workspaceHover.hovered ? theme.modules.bar.moduleHoverBackgroundColor : theme.modules.bar.moduleBackgroundColor

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: rootWorkspaces.theme.modules.bar.workspaces.itemSpacing

        Repeater {
            model: rootWorkspaces.service.workspaceModel

            delegate: Rectangle {
                id: workspaceItem

                required property var modelData

                width: Math.max(rootWorkspaces.theme.modules.bar.workspaces.itemMinWidth, workspaceContent.implicitWidth + rootWorkspaces.theme.modules.bar.workspaces.itemHorizontalPadding)
                height: rootWorkspaces.theme.modules.bar.workspaces.itemHeight
                radius: rootWorkspaces.theme.modules.bar.workspaces.itemRadius
                color: workspaceBackgroundColor()
                border.width: modelData.specialActive ? rootWorkspaces.theme.modules.bar.workspaces.specialActiveBorderWidth : 0
                border.color: specialActiveBorderColor()
                scale: itemHover.hovered ? rootWorkspaces.theme.modules.bar.workspaces.hoverScale : 1
                transformOrigin: Item.Center
                z: itemHover.hovered ? 1 : 0

                function workspaceBackgroundColor() {
                    if (modelData.active)
                        return rootWorkspaces.theme.modules.bar.primaryTextColor;

                    const sourceColor = modelData.specialActive ? rootWorkspaces.theme.modules.bar.accentColor : rootWorkspaces.theme.modules.bar.primaryTextColor;
                    const backgroundOpacity = itemHover.hovered ? rootWorkspaces.theme.modules.bar.workspaces.hoverBackgroundOpacity : modelData.specialActive ? rootWorkspaces.theme.modules.bar.workspaces.specialActiveBackgroundOpacity : modelData.empty ? rootWorkspaces.theme.modules.bar.workspaces.emptyBackgroundOpacity : rootWorkspaces.theme.modules.bar.workspaces.inactiveBackgroundOpacity;

                    return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, backgroundOpacity);
                }

                function specialActiveBorderColor() {
                    const sourceColor = rootWorkspaces.theme.modules.bar.accentColor;

                    return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, rootWorkspaces.theme.modules.bar.workspaces.specialActiveBorderOpacity);
                }

                Row {
                    id: workspaceContent

                    anchors.centerIn: parent
                    spacing: rootWorkspaces.theme.modules.bar.workspaces.contentSpacing
                    opacity: itemHover.hovered ? rootWorkspaces.theme.modules.bar.workspaces.hoverOpacity : modelData.active ? rootWorkspaces.theme.modules.bar.workspaces.activeOpacity : modelData.empty ? rootWorkspaces.theme.modules.bar.workspaces.emptyOpacity : rootWorkspaces.theme.modules.bar.workspaces.inactiveOpacity

                    Behavior on opacity {
                        NumberAnimation {
                            duration: rootWorkspaces.theme.modules.bar.workspaces.hoverAnimationDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        text: workspaceItem.modelData.displayName
                        color: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.moduleBackgroundColor : rootWorkspaces.theme.modules.bar.primaryTextColor
                        font.pixelSize: workspaceItem.modelData.isSpecial ? rootWorkspaces.theme.modules.bar.workspaces.specialTextPixelSize : rootWorkspaces.theme.modules.bar.workspaces.numberTextPixelSize
                        font.weight: workspaceItem.modelData.active ? Font.DemiBold : Font.Normal
                    }

                    Text {
                        visible: rootWorkspaces.theme.modules.bar.workspaces.indicatorMode === "count" && workspaceItem.modelData.windowCount > 0
                        text: workspaceItem.modelData.windowCount
                        color: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.moduleBackgroundColor : rootWorkspaces.theme.modules.bar.secondaryTextColor
                        font.pixelSize: rootWorkspaces.theme.modules.bar.workspaces.countTextPixelSize
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                        visible: rootWorkspaces.theme.modules.bar.workspaces.indicatorMode === "dots" && workspaceItem.modelData.windowCount > 0
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: Math.min(workspaceItem.modelData.windowCount, rootWorkspaces.theme.modules.bar.workspaces.maxDots)

                            delegate: Rectangle {
                                width: rootWorkspaces.theme.modules.bar.workspaces.dotSize
                                height: rootWorkspaces.theme.modules.bar.workspaces.dotSize
                                radius: width / 2
                                color: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.moduleBackgroundColor : rootWorkspaces.theme.modules.bar.secondaryTextColor
                            }
                        }
                    }
                }

                HoverHandler {
                    id: itemHover

                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: {
                        if (hovered) {
                            rootWorkspaces.tooltipShowRequested(workspaceItem, workspaceItem.modelData.tooltipTitle, workspaceItem.modelData.tooltipContent, workspaceItem.modelData.active ? "warning" : "normal");
                        } else {
                            rootWorkspaces.tooltipHideRequested();
                        }
                    }
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onTapped: rootWorkspaces.service.switchToWorkspace(workspaceItem.modelData)
                }

                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: {
                        rootWorkspaces.tooltipHideRequested();
                        rootWorkspaces.workspaceTooltipShowRequested(workspaceItem, workspaceItem.modelData);
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: rootWorkspaces.theme.modules.bar.workspaces.hoverAnimationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: rootWorkspaces.theme.modules.bar.workspaces.hoverAnimationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: rootWorkspaces.theme.modules.bar.workspaces.hoverAnimationDuration
                        easing.type: Easing.OutCubic
                    }
                }

            }
        }
    }

    HoverHandler {
        id: workspaceHover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                rootWorkspaces.service.switchByStep(-1);
            else if (wheel.angleDelta.y < 0)
                rootWorkspaces.service.switchByStep(1);

            wheel.accepted = true;
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: rootWorkspaces.theme.animationFastDuration
        }
    }
}

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: rootWorkspaces

    required property QtObject theme
    required property QtObject service
    property bool collapsedPill: false
    readonly property bool hovered: workspaceHover.hovered
    readonly property bool expandedPill: !collapsedPill || hovered

    signal tooltipShowRequested(Item anchorItem, string title, string content, string style)
    signal tooltipHideRequested
    signal workspaceTooltipShowRequested(Item anchorItem, var workspace)

    implicitWidth: workspaceRow.implicitWidth + theme.modules.bar.pill.horizontalPadding
    implicitHeight: expandedPill ? theme.modules.bar.pill.height : theme.modules.bar.collapsedHeight
    topLeftRadius: expandedPill ? theme.modules.bar.pill.radius : 0
    topRightRadius: expandedPill ? theme.modules.bar.pill.radius : 0
    bottomLeftRadius: expandedPill ? theme.modules.bar.pill.radius : theme.modules.bar.pill.collapsedRadius
    bottomRightRadius: expandedPill ? theme.modules.bar.pill.radius : theme.modules.bar.pill.collapsedRadius
    color: workspaceHover.hovered ? theme.modules.bar.moduleHoverBackgroundColor : theme.modules.bar.moduleBackgroundColor
    clip: collapsedPill && !expandedPill

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: rootWorkspaces.theme.modules.bar.workspaces.itemSpacing
        opacity: rootWorkspaces.expandedPill ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: rootWorkspaces.expandedPill ? rootWorkspaces.theme.modules.bar.pill.expandDuration : rootWorkspaces.theme.modules.bar.pill.collapseDuration
                easing.type: rootWorkspaces.expandedPill ? Easing.OutCubic : Easing.InOutCubic
            }
        }

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
                        anchors.verticalCenter: parent.verticalCenter
                        color: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.moduleBackgroundColor : rootWorkspaces.theme.modules.bar.primaryTextColor
                        font.pixelSize: workspaceItem.modelData.isSpecial ? rootWorkspaces.theme.modules.bar.workspaces.specialTextPixelSize : rootWorkspaces.theme.modules.bar.workspaces.numberTextPixelSize
                        font.weight: workspaceItem.modelData.active ? Font.DemiBold : Font.Normal
                    }

                    Row {
                        visible: rootWorkspaces.theme.modules.bar.workspaces.indicatorMode === "apps" && workspaceItem.modelData.appGroups.length > 0
                        spacing: rootWorkspaces.theme.modules.bar.workspaces.appIconSpacing
                        anchors.verticalCenter: parent.verticalCenter

                        Repeater {
                            model: workspaceItem.modelData.appGroups

                            delegate: Item {
                                id: appIconItem

                                required property var modelData

                                width: rootWorkspaces.theme.modules.bar.workspaces.appIconSlotSize
                                height: rootWorkspaces.theme.modules.bar.workspaces.appIconSlotSize
                                scale: appIconHover.hovered ? rootWorkspaces.theme.modules.bar.workspaces.appIconHoverScale : 1
                                transformOrigin: Item.Center

                                IconImage {
                                    id: appIconImage

                                    anchors.centerIn: parent
                                    width: rootWorkspaces.theme.modules.bar.workspaces.appIconSize
                                    height: width
                                    source: Quickshell.iconPath(String(appIconItem.modelData.iconName || ""), "application-x-executable-symbolic")
                                    visible: false
                                }

                                MultiEffect {
                                    anchors.centerIn: parent
                                    width: rootWorkspaces.theme.modules.bar.workspaces.appIconSize
                                    height: width
                                    source: appIconImage
                                    opacity: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.workspaces.activeAppIconOpacity : rootWorkspaces.theme.modules.bar.workspaces.inactiveAppIconOpacity
                                    colorization: rootWorkspaces.theme.modules.bar.workspaces.appIconColorization
                                    brightness: rootWorkspaces.theme.modules.bar.workspaces.appIconBrightness
                                    contrast: rootWorkspaces.theme.modules.bar.workspaces.appIconContrast
                                    colorizationColor: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.workspaces.activeAppIconColor : rootWorkspaces.theme.modules.bar.workspaces.inactiveAppIconColor
                                }

                                Rectangle {
                                    visible: Number(appIconItem.modelData.count || 0) > 1
                                    width: Math.max(rootWorkspaces.theme.modules.bar.workspaces.appBadgeMinSize, appBadgeText.implicitWidth + rootWorkspaces.theme.modules.bar.workspaces.appBadgeHorizontalPadding)
                                    height: rootWorkspaces.theme.modules.bar.workspaces.appBadgeMinSize
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    radius: height / 2
                                    color: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.moduleBackgroundColor : rootWorkspaces.theme.modules.bar.accentColor
                                    border.width: rootWorkspaces.theme.modules.bar.workspaces.appBadgeBorderWidth
                                    border.color: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.primaryTextColor : rootWorkspaces.theme.modules.bar.moduleBackgroundColor

                                    Text {
                                        id: appBadgeText

                                        anchors.centerIn: parent
                                        text: String(appIconItem.modelData.count || "")
                                        color: workspaceItem.modelData.active ? rootWorkspaces.theme.modules.bar.primaryTextColor : rootWorkspaces.theme.modules.bar.moduleBackgroundColor
                                        font.pixelSize: rootWorkspaces.theme.modules.bar.workspaces.appBadgeTextPixelSize
                                        font.weight: Font.DemiBold
                                    }
                                }

                                HoverHandler {
                                    id: appIconHover

                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: {
                                        rootWorkspaces.tooltipHideRequested();
                                        rootWorkspaces.service.focusClient(appIconItem.modelData.firstClient);
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: rootWorkspaces.theme.modules.bar.workspaces.hoverAnimationDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
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

    Behavior on implicitHeight {
        NumberAnimation {
            duration: rootWorkspaces.expandedPill ? rootWorkspaces.theme.modules.bar.pill.expandDuration : rootWorkspaces.theme.modules.bar.pill.collapseDuration
            easing.type: rootWorkspaces.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on topLeftRadius {
        NumberAnimation {
            duration: rootWorkspaces.expandedPill ? rootWorkspaces.theme.modules.bar.pill.expandDuration : rootWorkspaces.theme.modules.bar.pill.collapseDuration
            easing.type: rootWorkspaces.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on topRightRadius {
        NumberAnimation {
            duration: rootWorkspaces.expandedPill ? rootWorkspaces.theme.modules.bar.pill.expandDuration : rootWorkspaces.theme.modules.bar.pill.collapseDuration
            easing.type: rootWorkspaces.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: rootWorkspaces.expandedPill ? rootWorkspaces.theme.modules.bar.pill.expandDuration : rootWorkspaces.theme.modules.bar.pill.collapseDuration
            easing.type: rootWorkspaces.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on bottomRightRadius {
        NumberAnimation {
            duration: rootWorkspaces.expandedPill ? rootWorkspaces.theme.modules.bar.pill.expandDuration : rootWorkspaces.theme.modules.bar.pill.collapseDuration
            easing.type: rootWorkspaces.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

}

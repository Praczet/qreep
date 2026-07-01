import QtQuick

Rectangle {
    id: rootQreepModule

    required property QtObject theme
    default property alias content: contentContainer.data
    property alias overlay: overlayContainer.data
    readonly property bool hovered: moduleHoverHandler.hovered
    property bool collapsedPill: false
    readonly property bool expandedPill: !collapsedPill || hovered
    property string tooltipTitle
    property string tooltipContent
    property string tooltipStyle: "normal"

    signal clicked
    signal rightClicked
    signal tooltipShowRequested(Item anchorItem, string title, string content, string style)
    signal tooltipHideRequested

    onHoveredChanged: {
        if (hovered && (tooltipTitle.length > 0 || tooltipContent.length > 0)) {
            tooltipShowRequested(rootQreepModule, tooltipTitle, tooltipContent, tooltipStyle);
        } else {
            tooltipHideRequested();
        }
    }

    implicitWidth: contentContainer.implicitWidth + theme.modules.bar.pill.horizontalPadding
    implicitHeight: expandedPill ? theme.modules.bar.pill.height : theme.modules.bar.collapsedHeight
    topLeftRadius: expandedPill ? theme.modules.bar.pill.radius : 0
    topRightRadius: expandedPill ? theme.modules.bar.pill.radius : 0
    bottomLeftRadius: expandedPill ? theme.modules.bar.pill.radius : theme.modules.bar.pill.collapsedRadius
    bottomRightRadius: expandedPill ? theme.modules.bar.pill.radius : theme.modules.bar.pill.collapsedRadius
    color: moduleHoverHandler.hovered ? theme.modules.bar.pill.hoverBackgroundColor : theme.modules.bar.pill.backgroundColor
    clip: collapsedPill && !expandedPill

    Item {
        id: contentContainer

        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        opacity: rootQreepModule.expandedPill ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: rootQreepModule.expandedPill ? rootQreepModule.theme.modules.bar.pill.expandDuration : rootQreepModule.theme.modules.bar.pill.collapseDuration
                easing.type: rootQreepModule.expandedPill ? Easing.OutCubic : Easing.InOutCubic
            }
        }
    }

    Item {
        id: overlayContainer

        anchors.fill: parent
        opacity: rootQreepModule.expandedPill ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: rootQreepModule.expandedPill ? rootQreepModule.theme.modules.bar.pill.expandDuration : rootQreepModule.theme.modules.bar.pill.collapseDuration
                easing.type: rootQreepModule.expandedPill ? Easing.OutCubic : Easing.InOutCubic
            }
        }
    }

    HoverHandler {
        id: moduleHoverHandler

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: rootQreepModule.clicked()
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: rootQreepModule.rightClicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: rootQreepModule.theme.animationFastDuration
        }
    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: rootQreepModule.expandedPill ? rootQreepModule.theme.modules.bar.pill.expandDuration : rootQreepModule.theme.modules.bar.pill.collapseDuration
            easing.type: rootQreepModule.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on topLeftRadius {
        NumberAnimation {
            duration: rootQreepModule.expandedPill ? rootQreepModule.theme.modules.bar.pill.expandDuration : rootQreepModule.theme.modules.bar.pill.collapseDuration
            easing.type: rootQreepModule.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on topRightRadius {
        NumberAnimation {
            duration: rootQreepModule.expandedPill ? rootQreepModule.theme.modules.bar.pill.expandDuration : rootQreepModule.theme.modules.bar.pill.collapseDuration
            easing.type: rootQreepModule.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on bottomLeftRadius {
        NumberAnimation {
            duration: rootQreepModule.expandedPill ? rootQreepModule.theme.modules.bar.pill.expandDuration : rootQreepModule.theme.modules.bar.pill.collapseDuration
            easing.type: rootQreepModule.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

    Behavior on bottomRightRadius {
        NumberAnimation {
            duration: rootQreepModule.expandedPill ? rootQreepModule.theme.modules.bar.pill.expandDuration : rootQreepModule.theme.modules.bar.pill.collapseDuration
            easing.type: rootQreepModule.expandedPill ? Easing.OutCubic : Easing.InOutCubic
        }
    }

}

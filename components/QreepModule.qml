import QtQuick

Rectangle {
    id: rootQreepModule

    required property QtObject theme
    default property alias content: contentContainer.data
    property alias overlay: overlayContainer.data
    readonly property bool hovered: moduleHoverHandler.hovered
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

    implicitWidth: contentContainer.implicitWidth + theme.module.horizontalPadding
    implicitHeight: theme.module.height
    radius: theme.module.radius
    color: moduleHoverHandler.hovered ? theme.moduleHoverBackground : theme.moduleBackground

    Item {
        id: contentContainer

        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    Item {
        id: overlayContainer

        anchors.fill: parent
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
}

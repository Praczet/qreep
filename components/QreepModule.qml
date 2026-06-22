import QtQuick

Rectangle {
    id: rootQreepModule

    required property QtObject theme
    default property alias content: contentContainer.data
    readonly property bool hovered: moduleHoverHandler.hovered

    signal clicked
    signal rightClicked

    implicitWidth:
        contentContainer.implicitWidth + theme.moduleHorizontalPadding
    implicitHeight: theme.moduleHeight
    radius: theme.moduleRadius
    color: moduleHoverHandler.hovered
        ? theme.moduleHoverBackground
        : theme.moduleBackground

    Item {
        id: contentContainer

        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
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
            duration: 100
        }
    }
}

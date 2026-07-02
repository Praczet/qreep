import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootNotificationCenter

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false

    signal closeRequested

    implicitWidth: screen.width
    implicitHeight: screen.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    mask: Region {
        item: panel
    }

    WlrLayershell.namespace: "qreep-notification-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Component.onCompleted: {
        panel.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            panel.forceActiveFocus();
            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootNotificationCenter.closeRequested()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootNotificationCenter.presented = true
    }

    Rectangle {
        id: panel

        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            margins: rootNotificationCenter.theme.modules.notification.centerMargin
            topMargin: rootNotificationCenter.theme.modules.notification.centerTopMargin
        }
        width: Math.min(rootNotificationCenter.theme.modules.notification.centerWidth, parent.width - rootNotificationCenter.theme.modules.notification.centerMargin * 2)
        radius: rootNotificationCenter.theme.modules.notification.panelRadius
        color: rootNotificationCenter.theme.modules.notification.panelColor
        border.width: 1
        border.color: rootNotificationCenter.theme.modules.notification.borderColor
        opacity: rootNotificationCenter.presented ? 1 : 0
        x: rootNotificationCenter.presented ? 0 : 28
        clip: true
        focus: true

        Behavior on opacity {
            NumberAnimation {
                duration: rootNotificationCenter.theme.modules.notification.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: rootNotificationCenter.theme.modules.notification.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Column {
            id: layout

            anchors {
                fill: parent
                margins: rootNotificationCenter.theme.modules.notification.panelPadding
            }
            spacing: rootNotificationCenter.theme.modules.notification.sectionGap

            Row {
                width: parent.width
                height: rootNotificationCenter.theme.modules.notification.headerHeight
                spacing: 10

                Column {
                    width: parent.width - groupToggle.width - clearButton.width - closeCenterButton.width - parent.spacing * 3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        text: "Notifications"
                        color: rootNotificationCenter.theme.modules.notification.primaryTextColor
                        font.pixelSize: rootNotificationCenter.theme.modules.notification.headingPixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: rootNotificationCenter.service.notificationCount + (rootNotificationCenter.service.notificationCount === 1 ? " notification" : " notifications")
                        color: rootNotificationCenter.theme.modules.notification.secondaryTextColor
                        font.pixelSize: rootNotificationCenter.theme.modules.notification.metaPixelSize
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    id: groupToggle

                    width: 94
                    height: 28
                    radius: 6
                    color: rootNotificationCenter.service.groupedByApp ? rootNotificationCenter.theme.modules.notification.selectedControlColor : rootNotificationCenter.theme.modules.notification.controlColor
                    border.width: 1
                    border.color: rootNotificationCenter.service.groupedByApp ? rootNotificationCenter.theme.modules.notification.selectedBorderColor : rootNotificationCenter.theme.modules.notification.borderColor
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "group"
                        color: rootNotificationCenter.theme.modules.notification.primaryTextColor
                        font.pixelSize: rootNotificationCenter.theme.modules.notification.bodyPixelSize
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: rootNotificationCenter.service.groupedByApp = !rootNotificationCenter.service.groupedByApp
                    }
                }

                Rectangle {
                    id: clearButton

                    width: 82
                    height: 28
                    radius: 6
                    color: clearHover.hovered ? rootNotificationCenter.theme.modules.notification.closeButtonHoverColor : rootNotificationCenter.theme.modules.notification.controlColor
                    border.width: 1
                    border.color: rootNotificationCenter.theme.modules.notification.borderColor
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "clear"
                        color: rootNotificationCenter.theme.modules.notification.primaryTextColor
                        font.pixelSize: rootNotificationCenter.theme.modules.notification.bodyPixelSize
                    }

                    HoverHandler {
                        id: clearHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: rootNotificationCenter.service.dismissAll()
                    }
                }

                Rectangle {
                    id: closeCenterButton

                    width: 28
                    height: 28
                    radius: 6
                    color: closeCenterHover.hovered ? rootNotificationCenter.theme.modules.notification.closeButtonHoverColor : rootNotificationCenter.theme.modules.notification.controlColor
                    border.width: 1
                    border.color: rootNotificationCenter.theme.modules.notification.borderColor
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        color: rootNotificationCenter.theme.modules.notification.primaryTextColor
                        font.pixelSize: rootNotificationCenter.theme.modules.notification.closePixelSize
                        font.weight: Font.DemiBold
                    }

                    HoverHandler {
                        id: closeCenterHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: rootNotificationCenter.closeRequested()
                    }
                }
            }

            Flickable {
                id: scroll

                width: parent.width
                height: parent.height - rootNotificationCenter.theme.modules.notification.headerHeight - parent.spacing
                contentWidth: width
                contentHeight: listColumn.implicitHeight
                clip: true

                Column {
                    id: listColumn

                    width: scroll.width
                    spacing: rootNotificationCenter.theme.modules.notification.cardGap

                    Text {
                        visible: rootNotificationCenter.service.notificationCount === 0
                        width: parent.width
                        height: 80
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "No notifications"
                        color: rootNotificationCenter.theme.modules.notification.secondaryTextColor
                        font.pixelSize: rootNotificationCenter.theme.modules.notification.bodyPixelSize
                    }

                    Repeater {
                        model: rootNotificationCenter.service.groupedByApp ? [] : rootNotificationCenter.service.notificationValues

                        NotificationCard {
                            required property var modelData

                            width: listColumn.width
                            theme: rootNotificationCenter.theme
                            service: rootNotificationCenter.service
                            notification: modelData
                            popupMode: false

                            onCloseRequested: (notification, closeAll) => {
                                if (closeAll)
                                    rootNotificationCenter.service.dismissAll();
                                else
                                    rootNotificationCenter.service.dismissNotification(notification);
                            }
                        }
                    }

                    Repeater {
                        model: rootNotificationCenter.service.groupedByApp ? rootNotificationCenter.service.notificationGroups : []

                        Rectangle {
                            id: groupItem

                            required property var modelData

                            width: listColumn.width
                            implicitHeight: groupColumn.implicitHeight + rootNotificationCenter.theme.modules.notification.groupPadding * 2
                            radius: rootNotificationCenter.theme.modules.notification.cardRadius
                            color: rootNotificationCenter.theme.modules.notification.groupColor
                            border.width: 1
                            border.color: rootNotificationCenter.theme.modules.notification.borderColor
                            clip: true

                            Column {
                                id: groupColumn

                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: rootNotificationCenter.theme.modules.notification.groupPadding
                                }
                                spacing: rootNotificationCenter.theme.modules.notification.cardGap

                                Item {
                                    width: parent.width
                                    height: 22

                                    Rectangle {
                                        id: foldButton

                                        anchors {
                                            left: parent.left
                                            verticalCenter: parent.verticalCenter
                                        }
                                        width: rootNotificationCenter.theme.modules.notification.foldButtonSize
                                        height: width
                                        radius: 5
                                        color: groupHeaderHover.hovered ? rootNotificationCenter.theme.modules.notification.controlColor : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: groupItem.modelData.notifications.length > 1 ? (groupItem.modelData.folded ? ">" : "v") : ""
                                            color: rootNotificationCenter.theme.modules.notification.secondaryTextColor
                                            font.pixelSize: rootNotificationCenter.theme.modules.notification.metaPixelSize
                                            font.weight: Font.DemiBold
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: groupItem.modelData.notifications.length > 1
                                            acceptedButtons: Qt.LeftButton
                                            onClicked: rootNotificationCenter.service.toggleGroupFolded(groupItem.modelData)
                                        }
                                    }

                                    Item {
                                        id: titleArea

                                        anchors {
                                            left: foldButton.right
                                            right: countBadge.left
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: 8
                                            rightMargin: 8
                                        }
                                        height: parent.height

                                        Text {
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: groupItem.modelData.title
                                            color: rootNotificationCenter.theme.modules.notification.primaryTextColor
                                            font.pixelSize: rootNotificationCenter.theme.modules.notification.titlePixelSize
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: groupItem.modelData.notifications.length > 1
                                            acceptedButtons: Qt.LeftButton
                                            onClicked: rootNotificationCenter.service.toggleGroupFolded(groupItem.modelData)
                                        }
                                    }

                                    Rectangle {
                                        id: groupClearButton

                                        anchors {
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                        }
                                        width: rootNotificationCenter.theme.modules.notification.groupClearButtonSize
                                        height: width
                                        radius: 5
                                        color: groupClearHover.hovered ? rootNotificationCenter.theme.modules.notification.closeButtonHoverColor : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            color: rootNotificationCenter.theme.modules.notification.secondaryTextColor
                                            font.family: rootNotificationCenter.theme.iconFontFamily
                                            font.pixelSize: rootNotificationCenter.theme.modules.notification.closePixelSize
                                        }

                                        HoverHandler {
                                            id: groupClearHover

                                            cursorShape: Qt.PointingHandCursor
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton
                                            onClicked: rootNotificationCenter.service.dismissGroup(groupItem.modelData)
                                        }
                                    }

                                    Rectangle {
                                        id: countBadge

                                        anchors {
                                            right: groupClearButton.left
                                            rightMargin: 8
                                            verticalCenter: parent.verticalCenter
                                        }
                                        width: Math.max(24, countText.implicitWidth + 12)
                                        height: 20
                                        radius: 10
                                        color: rootNotificationCenter.theme.modules.notification.selectedControlColor

                                        Text {
                                            id: countText

                                            anchors.centerIn: parent
                                            text: String(groupItem.modelData.notifications.length)
                                            color: rootNotificationCenter.theme.modules.notification.primaryTextColor
                                            font.pixelSize: rootNotificationCenter.theme.modules.notification.metaPixelSize
                                        }
                                    }

                                    HoverHandler {
                                        id: groupHeaderHover

                                        cursorShape: modelData.notifications.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    }
                                }

                                Repeater {
                                    model: groupItem.modelData.visibleNotifications

                                    NotificationCard {
                                        required property var modelData

                                        width: groupColumn.width
                                        theme: rootNotificationCenter.theme
                                        service: rootNotificationCenter.service
                                        notification: modelData
                                        popupMode: false

                                        onCloseRequested: (notification, closeAll) => {
                                            if (closeAll)
                                                rootNotificationCenter.service.dismissAll();
                                            else
                                                rootNotificationCenter.service.dismissNotification(notification);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

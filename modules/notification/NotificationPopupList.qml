import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: rootNotificationPopupList

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false

    signal closeRequested(var notification)
    signal closeIdRequested(string id, bool closeAll)
    signal closeAllRequested
    signal popupExpired(var notification)
    signal popupExpiredId(string id)
    signal actionInvoked(string id, var action)

    implicitWidth: screen.width
    implicitHeight: screen.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    visible: rootNotificationPopupList.panelOpen || rootNotificationPopupList.presented
    mask: Region {
        item: popupStack
    }

    WlrLayershell.namespace: "qreep-notification"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Component.onCompleted: {
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootNotificationPopupList.presented = true
    }

    Item {
        id: popupStack

        anchors {
            top: parent.top
            right: parent.right
            topMargin: rootNotificationPopupList.theme.modules.notification.popupTopMargin
            rightMargin: rootNotificationPopupList.theme.modules.notification.popupRightMargin
        }

        width: rootNotificationPopupList.theme.modules.notification.popupWidth
        height: popupColumn.implicitHeight
        opacity: rootNotificationPopupList.presented ? 1 : 0
        x: rootNotificationPopupList.presented ? 0 : 18

        Behavior on opacity {
            NumberAnimation {
                duration: rootNotificationPopupList.theme.modules.notification.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on x {
            NumberAnimation {
                duration: rootNotificationPopupList.theme.modules.notification.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: popupColumn

            width: parent.width
            spacing: rootNotificationPopupList.theme.modules.notification.cardGap

            Repeater {
                model: rootNotificationPopupList.service.popupNotifications

                NotificationCard {
                    required property var modelData

                    theme: rootNotificationPopupList.theme
                    service: rootNotificationPopupList.service
                    notification: modelData
                    popupMode: true

                    onCloseRequested: (notification, closeAll) => {
                        if (closeAll)
                            rootNotificationPopupList.closeAllRequested();
                        else
                            rootNotificationPopupList.closeRequested(notification);
                    }
                    onCloseIdRequested: (id, closeAll) => rootNotificationPopupList.closeIdRequested(id, closeAll)

                    onExpired: notification => rootNotificationPopupList.popupExpired(notification)
                    onExpiredId: id => rootNotificationPopupList.popupExpiredId(id)
                    onActionInvoked: (id, action) => rootNotificationPopupList.actionInvoked(id, action)
                }
            }
        }
    }
}

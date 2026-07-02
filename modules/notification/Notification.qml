// modules/notification/Notification.qml
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: rootNotification

    required property QtObject theme
    property bool centerOpen: false
    readonly property bool popupOpen: notificationService.popupNotifications.length > 0
    readonly property bool centerLoaded: centerOpen || centerCloseTimer.running
    readonly property bool popupLoaded: popupOpen || popupCloseTimer.running

    readonly property alias service: notificationService
    readonly property alias notifications: notificationService.notifications

    NotificationService {
        id: notificationService
        theme: rootNotification.theme

        onNotificationReceived: notification => {
            rootNotification.showPopup();
        }
    }

    readonly property IpcHandler ipc: IpcHandler {
        target: "qreep-notification"

        function toggle() {
            rootNotification.toggle();
        }

        function showMe() {
            rootNotification.show();
        }

        function hideMe() {
            rootNotification.hide();
        }

        function refresh() {
            notificationService.groupedByApp = notificationService.groupedByApp;
        }

        function showPopup() {
            rootNotification.showPopup();
        }

        function hidePopup() {
            rootNotification.hidePopup();
        }

        function togglePopup() {
            rootNotification.popupOpen ? rootNotification.hidePopup() : rootNotification.showPopup();
        }

        function showCenter() {
            rootNotification.show();
        }

        function hideCenter() {
            rootNotification.hide();
        }

        function toggleCenter() {
            rootNotification.toggle();
        }

        function dismissAll() {
            notificationService.dismissAll();
        }
    }

    LazyLoader {
        id: popupListLoader

        active: rootNotification.popupLoaded

        NotificationPopupList {
            theme: rootNotification.theme
            service: notificationService
            panelOpen: rootNotification.popupOpen

            onCloseRequested: notification => notificationService.dismissNotification(notification)
            onCloseAllRequested: notificationService.dismissAll()
            onPopupExpired: notification => notificationService.expirePopup(notification)
        }
    }

    LazyLoader {
        id: centerLoader

        active: rootNotification.centerLoaded

        NotificationCenter {
            theme: rootNotification.theme
            service: notificationService
            panelOpen: rootNotification.centerOpen

            onCloseRequested: rootNotification.hide()
        }
    }

    Timer {
        id: centerCloseTimer

        interval: rootNotification.theme.modules.notification.animationDuration + 40
        repeat: false
    }

    Timer {
        id: popupCloseTimer

        interval: rootNotification.theme.modules.notification.animationDuration + 40
        repeat: false
    }

    onPopupOpenChanged: {
        if (popupOpen) {
            popupCloseTimer.stop();
            return;
        }

        if (popupListLoader.active)
            popupCloseTimer.restart();
    }

    function show() {
        centerCloseTimer.stop();
        centerOpen = true;
    }

    function hide() {
        if (!centerOpen)
            return;

        centerCloseTimer.restart();
        centerOpen = false;
    }

    function toggle() {
        centerOpen ? hide() : show();
    }

    function showPopup() {
        popupCloseTimer.stop();
    }

    function hidePopup() {
        notificationService.popupNotifications = [];
    }

    function togglePopup() {
        if (popupOpen)
            hidePopup();
    }
}

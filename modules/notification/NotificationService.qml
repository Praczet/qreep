import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: rootNotificationService

    required property QtObject theme
    property var popupNotifications: []
    property bool groupedByApp: true
    property var groupFoldOverrides: ({})
    readonly property var notificationValues: notifServer.trackedNotifications.values
    readonly property var notificationGroups: buildGroups(notificationValues, groupFoldOverrides)
    readonly property int notificationCount: notificationValues.length

    readonly property alias server: notifServer
    readonly property alias notifications: notifServer.trackedNotifications

    signal notificationReceived(var notification)

    NotificationServer {
        id: notifServer

        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: false
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            rootNotificationService.showPopupNotification(notification);
            rootNotificationService.notificationReceived(notification);
        }
    }

    function showPopupNotification(notification) {
        const nextNotifications = popupNotifications.filter(item => item && item.id !== notification.id);
        nextNotifications.unshift(notification);
        popupNotifications = nextNotifications.slice(0, theme.modules.notification.maxPopupItems);
    }

    function hidePopupNotification(notification) {
        if (!notification)
            return;

        popupNotifications = popupNotifications.filter(item => item && item.id !== notification.id);
    }

    function dismissNotification(notification) {
        if (!notification)
            return;

        hidePopupNotification(notification);
        notification.dismiss();
    }

    function dismissAll() {
        const values = notificationValues.slice();

        popupNotifications = [];
        for (let i = 0; i < values.length; i++) {
            if (values[i])
                values[i].dismiss();
        }
    }

    function dismissGroup(group) {
        const key = String(group && group.key || "");
        const values = key.length > 0 ? notificationValues.filter(notification => groupKey(notification) === key) : [];

        for (let i = 0; i < values.length; i++) {
            if (values[i])
                dismissNotification(values[i]);
        }
    }

    function expirePopup(notification) {
        hidePopupNotification(notification);
    }

    function closeFromPointer(notification, modifiers) {
        if ((modifiers & Qt.ControlModifier) !== 0) {
            dismissAll();
            return;
        }

        dismissNotification(notification);
    }

    function appLabel(notification) {
        const appName = String(notification && notification.appName || "").trim();
        const desktopEntry = String(notification && notification.desktopEntry || "").trim();

        if (appName.length > 0)
            return appName;

        if (desktopEntry.length > 0)
            return desktopEntry;

        return "Unknown";
    }

    function iconName(notification) {
        const appIcon = String(notification && notification.appIcon || "").trim();
        const desktopEntry = String(notification && notification.desktopEntry || "").trim();

        if (appIcon.length > 0)
            return appIcon;

        if (desktopEntry.length > 0)
            return desktopEntry;

        return "dialog-information-symbolic";
    }

    function summary(notification) {
        const text = plainText(notification && notification.summary || "").trim();
        return text.length > 0 ? text : appLabel(notification);
    }

    function body(notification) {
        return plainText(notification && notification.body || "").trim();
    }

    function contrastTextColor(hexColor) {
        const text = String(hexColor || "").replace("#", "");

        if (text.length !== 6)
            return theme.modules.notification.primaryTextColor;

        const red = parseInt(text.slice(0, 2), 16);
        const green = parseInt(text.slice(2, 4), 16);
        const blue = parseInt(text.slice(4, 6), 16);
        const luminance = (red * 299 + green * 587 + blue * 114) / 1000;

        return luminance > 150 ? "#20242d" : "#f4f7ff";
    }

    function groupKey(notification) {
        return appLabel(notification).toLowerCase();
    }

    function groupFolded(group) {
        const key = String(group && group.key || "");
        const override = groupFoldOverrides[key];

        return override === undefined ? true : !!override;
    }

    function toggleGroupFolded(group) {
        const key = String(group && group.key || "");

        if (key.length === 0)
            return;

        const nextOverrides = Object.assign({}, groupFoldOverrides);
        nextOverrides[key] = !groupFolded(group);
        groupFoldOverrides = nextOverrides;
    }

    function buildGroups(values, foldOverrides) {
        const groupsByKey = {};
        const groups = [];

        for (let i = 0; i < values.length; i++) {
            const notification = values[i];
            const key = groupKey(notification);

            if (!groupsByKey[key]) {
                groupsByKey[key] = {
                    key,
                    title: appLabel(notification),
                    notifications: []
                };
                groups.push(groupsByKey[key]);
            }

            groupsByKey[key].notifications.push(notification);
        }

        for (let groupIndex = 0; groupIndex < groups.length; groupIndex++) {
            const group = groups[groupIndex];
            const override = foldOverrides[group.key];
            const folded = override === undefined ? true : !!override;
            const notifications = group.notifications;

            group.folded = folded;
            group.visibleNotifications = folded && notifications.length > 1 ? [notifications[notifications.length - 1]] : notifications;
        }

        return groups;
    }

    function plainText(value) {
        return String(value || "")
            .replace(/<br\s*\/?>/gi, "\n")
            .replace(/<\/p>/gi, "\n")
            .replace(/<[^>]*>/g, "")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&amp;/g, "&")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;/g, "'");
    }
}

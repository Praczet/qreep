import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Scope {
    id: rootNotificationService

    required property QtObject theme
    property var popupNotifications: []
    property var freshPopupIds: ({})
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
        const id = notificationId(notification);
        const nextNotifications = popupNotifications.filter(item => item && notificationId(item) !== id);
        const nextFreshPopupIds = Object.assign({}, freshPopupIds);

        nextFreshPopupIds[id] = true;
        freshPopupIds = nextFreshPopupIds;

        nextNotifications.unshift(snapshotNotification(notification));
        popupNotifications = nextNotifications.slice(0, theme.modules.notification.maxPopupItems);
        freshPopupClearTimer.restart();
    }

    function popupFresh(notification) {
        const id = notificationId(notification);

        return !!freshPopupIds[id];
    }

    readonly property Timer freshPopupClearTimer: Timer {
        interval: theme.modules.notification.popupEnterDuration + 80
        repeat: false
        onTriggered: freshPopupIds = ({})
    }

    function hidePopupNotification(notification) {
        if (!notification)
            return;

        hidePopupNotificationId(notificationId(notification));
    }

    function hidePopupNotificationId(id) {
        const value = String(id || "");

        if (value.length === 0)
            return;

        popupNotifications = popupNotifications.filter(item => item && notificationId(item) !== value);
    }

    function dismissNotification(notification) {
        if (!notification)
            return;

        hidePopupNotification(notification);
        notification.dismiss();
    }

    function dismissNotificationId(id) {
        const value = String(id || "");
        const notification = findNotification(value);

        hidePopupNotificationId(value);
        if (notification)
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

    function expirePopupId(id) {
        hidePopupNotificationId(id);
    }

    function invokePopupAction(id, actionIndex) {
        hidePopupNotificationId(id);
        invokeNotificationActionId(id, actionIndex);
    }

    function invokeNotificationActionId(id, actionIndex) {
        const notification = findNotification(id);
        const index = Number(actionIndex);

        if (!notification || index < 0)
            return;

        const actions = notification.actions || [];
        const action = actions[index];

        if (action)
            action.invoke();
    }

    function findNotification(id) {
        const value = String(id || "");

        if (value.length === 0)
            return null;

        for (let i = 0; i < notificationValues.length; i++) {
            const notification = notificationValues[i];
            if (notification && String(notification.id) === value)
                return notification;
        }

        return null;
    }

    function notificationId(notification) {
        return String(notification && notification.id || "");
    }

    function isSnapshot(notification) {
        return !!(notification && notification.__qreepSnapshot);
    }

    function snapshotNotification(notification) {
        return {
            __qreepSnapshot: true,
            id: notificationId(notification),
            appName: appLabel(notification),
            iconName: iconName(notification),
            summary: summary(notification),
            body: body(notification),
            image: imageSource(notification),
            urgency: urgencyValue(notification),
            actions: notificationActions(notification)
        };
    }

    function closeFromPointer(notification, modifiers) {
        if ((modifiers & Qt.ControlModifier) !== 0) {
            dismissAll();
            return;
        }

        dismissNotification(notification);
    }

    function appLabel(notification) {
        if (isSnapshot(notification))
            return String(notification.appName || "Unknown");

        const appName = String(notification && notification.appName || "").trim();
        const desktopEntry = String(notification && notification.desktopEntry || "").trim();

        if (appName.length > 0)
            return appName;

        if (desktopEntry.length > 0)
            return desktopEntry;

        return "Unknown";
    }

    function iconName(notification) {
        if (isSnapshot(notification))
            return String(notification.iconName || "dialog-information-symbolic");

        const appIcon = String(notification && notification.appIcon || "").trim();
        const desktopEntry = String(notification && notification.desktopEntry || "").trim();

        if (appIcon.length > 0)
            return appIcon;

        if (desktopEntry.length > 0)
            return desktopEntry;

        return "dialog-information-symbolic";
    }

    function summary(notification) {
        if (isSnapshot(notification))
            return String(notification.summary || appLabel(notification));

        const text = plainText(notification && notification.summary || "").trim();
        return text.length > 0 ? text : appLabel(notification);
    }

    function body(notification) {
        if (isSnapshot(notification))
            return String(notification.body || "");

        return plainText(notification && notification.body || "").trim();
    }

    function imageSource(notification) {
        return String(notification && notification.image || "");
    }

    function urgencyValue(notification) {
        return String(notification && notification.urgency || "");
    }

    function notificationActions(notification) {
        if (!notification)
            return [];

        if (isSnapshot(notification))
            return notification.actions || [];

        const actions = notification.actions || [];
        const visibleActions = [];

        for (let i = 0; i < actions.length; i++) {
            const action = actions[i];
            const text = String(action && action.text || "").trim();

            if (text.length > 0) {
                visibleActions.push({
                    index: i,
                    text
                });
            }
        }

        return visibleActions;
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

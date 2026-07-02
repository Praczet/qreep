import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: rootNotificationCard

    required property QtObject theme
    required property QtObject service
    required property var notification
    property bool popupMode: true
    property bool centerMode: !popupMode
    property bool hovered: false
    property bool entered: true
    property bool exiting: false
    property bool pendingCloseAll: false
    property bool pendingDismiss: false
    property string stableNotificationId: ""
    readonly property string title: service.summary(notification)
    readonly property string body: service.body(notification)
    readonly property string appName: service.appLabel(notification)
    readonly property bool hasBody: body.length > 0
    readonly property bool hasImage: String(notification && notification.image || "").length > 0
    readonly property var visibleActions: notification ? notification.actions.filter(action => String(action && action.text || "").trim().length > 0) : []
    readonly property bool hasActions: visibleActions.length > 0
    readonly property bool critical: notification && String(notification.urgency) === "2"
    readonly property bool hyprshotCard: appName.toLowerCase().indexOf("hyprshot") !== -1
    readonly property bool showImagePreview: hyprshotCard && hasImage
    readonly property string priorityLabel: critical ? "Critical" : ""
    readonly property string appHeader: priorityLabel.length > 0 ? priorityLabel + " " + appName : appName
    readonly property string pickedColor: extractColor(title + " " + body)
    readonly property bool colorPickerCard: pickedColor.length > 0 && (title.toLowerCase().indexOf("color picker") !== -1 || appName.toLowerCase().indexOf("color picker") !== -1)

    signal closeRequested(var notification, bool closeAll)
    signal closeIdRequested(string id, bool closeAll)
    signal expired(var notification)
    signal expiredId(string id)
    signal actionInvoked(string id, var action)

    implicitWidth: popupMode ? theme.modules.notification.popupWidth : parent ? parent.width : theme.modules.notification.centerWidth
    implicitHeight: card.implicitHeight
    opacity: !popupMode || (entered && !exiting) ? 1 : 0
    x: popupMode ? (!entered ? theme.modules.notification.popupCardEnterOffset : exiting ? theme.modules.notification.popupCardExitOffset : 0) : 0
    scale: popupMode && !entered ? 0.985 : 1

    Component.onCompleted: {
        stableNotificationId = String(notification && notification.id || "");
        if (popupMode && service.popupFresh(notification)) {
            entered = false;
            enterTimer.restart();
        }
    }

    Timer {
        id: popupTimer

        interval: rootNotificationCard.theme.modules.notification.popupTimeout
        repeat: false
        running: rootNotificationCard.popupMode && rootNotificationCard.visible && !rootNotificationCard.hasActions
        onTriggered: rootNotificationCard.requestExpire()
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: rootNotificationCard.entered = true
    }

    Timer {
        id: exitTimer

        interval: rootNotificationCard.theme.modules.notification.popupExitDuration
        repeat: false
        onTriggered: {
            if (rootNotificationCard.pendingCloseAll)
                rootNotificationCard.closeIdRequested(rootNotificationCard.stableNotificationId, true);
            else if (rootNotificationCard.pendingDismiss)
                rootNotificationCard.closeIdRequested(rootNotificationCard.stableNotificationId, false);
            else
                rootNotificationCard.expiredId(rootNotificationCard.stableNotificationId);
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: rootNotificationCard.exiting ? rootNotificationCard.theme.modules.notification.popupExitDuration : rootNotificationCard.theme.modules.notification.popupEnterDuration
            easing.type: rootNotificationCard.exiting ? Easing.InCubic : Easing.OutCubic
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: rootNotificationCard.exiting ? rootNotificationCard.theme.modules.notification.popupExitDuration : rootNotificationCard.theme.modules.notification.popupEnterDuration
            easing.type: rootNotificationCard.exiting ? Easing.InCubic : Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: rootNotificationCard.theme.modules.notification.popupEnterDuration
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: card

        width: parent.width
        implicitHeight: (rootNotificationCard.colorPickerCard ? colorPickerContent.implicitHeight : contentColumn.implicitHeight) + rootNotificationCard.theme.modules.notification.cardPadding * 2
        radius: rootNotificationCard.theme.modules.notification.cardRadius
        color: cardHover.hovered ? rootNotificationCard.theme.modules.notification.cardHoverColor : rootNotificationCard.theme.modules.notification.cardColor
        border.width: rootNotificationCard.theme.modules.notification.cardBorderWidth
        border.color: rootNotificationCard.critical ? rootNotificationCard.theme.modules.notification.criticalBorderColor : rootNotificationCard.theme.modules.notification.borderColor
        clip: true

        Behavior on color {
            ColorAnimation {
                duration: rootNotificationCard.theme.modules.notification.animationDuration
            }
        }

        HoverHandler {
            id: cardHover

            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: rootNotificationCard.hovered = hovered
        }

        Column {
            id: contentColumn

            visible: !rootNotificationCard.colorPickerCard
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootNotificationCard.theme.modules.notification.cardPadding
            }
            spacing: rootNotificationCard.theme.modules.notification.contentGap

            Row {
                width: parent.width
                height: Math.max(appHeaderText.implicitHeight, closeButton.height)
                spacing: rootNotificationCard.theme.modules.notification.contentGap

                Text {
                    id: appHeaderText

                    width: parent.width - closeButton.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootNotificationCard.appHeader
                    color: rootNotificationCard.critical ? rootNotificationCard.theme.modules.notification.criticalTextColor : rootNotificationCard.theme.modules.notification.primaryTextColor
                    font.pixelSize: rootNotificationCard.theme.modules.notification.titlePixelSize
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: closeButton

                    width: rootNotificationCard.theme.modules.notification.closeButtonSize
                    height: width
                    radius: 5
                    color: closeHover.hovered ? rootNotificationCard.theme.modules.notification.closeButtonHoverColor : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        color: rootNotificationCard.theme.modules.notification.secondaryTextColor
                        font.pixelSize: rootNotificationCard.theme.modules.notification.closePixelSize
                        font.weight: Font.DemiBold
                    }

                    HoverHandler {
                        id: closeHover

                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: mouse => rootNotificationCard.requestClose((mouse.modifiers & Qt.ControlModifier) !== 0)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: rootNotificationCard.theme.modules.notification.borderColor
            }

            Row {
                width: parent.width
                spacing: rootNotificationCard.theme.modules.notification.contentGap

                Rectangle {
                    visible: rootNotificationCard.showImagePreview
                    width: rootNotificationCard.theme.modules.notification.appImagePreviewSize
                    height: width
                    radius: 6
                    color: rootNotificationCard.theme.modules.notification.controlColor
                    clip: true
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: rootNotificationCard.showImagePreview && rootNotificationCard.notification ? rootNotificationCard.notification.image : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }
                }

                IconImage {
                    visible: !rootNotificationCard.showImagePreview
                    width: rootNotificationCard.theme.modules.notification.appIconSize
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    source: Quickshell.iconPath(rootNotificationCard.service.iconName(rootNotificationCard.notification), "dialog-information-symbolic")
                }

                Column {
                    width: parent.width - (rootNotificationCard.showImagePreview ? rootNotificationCard.theme.modules.notification.appImagePreviewSize : rootNotificationCard.theme.modules.notification.appIconSize) - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        width: parent.width
                        text: rootNotificationCard.title
                        color: rootNotificationCard.theme.modules.notification.primaryTextColor
                        font.pixelSize: rootNotificationCard.theme.modules.notification.titlePixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: rootNotificationCard.hasBody
                        width: parent.width
                        text: rootNotificationCard.body
                        color: rootNotificationCard.theme.modules.notification.primaryTextColor
                        font.pixelSize: rootNotificationCard.theme.modules.notification.bodyPixelSize
                        lineHeight: 1.08
                        wrapMode: Text.Wrap
                        maximumLineCount: rootNotificationCard.popupMode ? 4 : 8
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }
            }

            Flow {
                visible: rootNotificationCard.hasActions
                width: parent.width
                spacing: 6

                Repeater {
                    model: rootNotificationCard.visibleActions

                    Rectangle {
                        required property var modelData

                        width: Math.max(actionText.implicitWidth + 18, 54)
                        height: rootNotificationCard.theme.modules.notification.actionHeight
                        radius: 5
                        color: actionHover.hovered ? rootNotificationCard.theme.modules.notification.actionHoverColor : rootNotificationCard.theme.modules.notification.actionColor
                        border.width: 1
                        border.color: rootNotificationCard.theme.modules.notification.borderColor

                        Text {
                            id: actionText

                            anchors.centerIn: parent
                            text: String(parent.modelData.text || "")
                            color: rootNotificationCard.theme.modules.notification.primaryTextColor
                            font.pixelSize: rootNotificationCard.theme.modules.notification.metaPixelSize
                            elide: Text.ElideRight
                        }

                        HoverHandler {
                            id: actionHover

                            cursorShape: Qt.PointingHandCursor
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                rootNotificationCard.requestAction(parent.modelData);
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: colorPickerContent

            visible: rootNotificationCard.colorPickerCard
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: rootNotificationCard.theme.modules.notification.cardPadding
            }
            spacing: rootNotificationCard.theme.modules.notification.contentGap

            Row {
                width: parent.width
                height: Math.max(colorPickerTitle.implicitHeight, closeButtonColorPicker.height)
                spacing: rootNotificationCard.theme.modules.notification.contentGap

                Text {
                    id: colorPickerTitle

                    width: parent.width - closeButtonColorPicker.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: rootNotificationCard.title
                    color: rootNotificationCard.theme.modules.notification.primaryTextColor
                    font.pixelSize: rootNotificationCard.theme.modules.notification.titlePixelSize + 1
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: closeButtonColorPicker

                    width: rootNotificationCard.theme.modules.notification.closeButtonSize
                    height: width
                    radius: 5
                    color: closeHoverColorPicker.hovered ? rootNotificationCard.theme.modules.notification.closeButtonHoverColor : "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        color: rootNotificationCard.theme.modules.notification.secondaryTextColor
                        font.pixelSize: rootNotificationCard.theme.modules.notification.closePixelSize
                        font.weight: Font.DemiBold
                    }

                    HoverHandler {
                        id: closeHoverColorPicker

                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onClicked: mouse => rootNotificationCard.requestClose((mouse.modifiers & Qt.ControlModifier) !== 0)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: rootNotificationCard.theme.modules.notification.borderColor
            }

            Row {
                width: parent.width
                spacing: rootNotificationCard.theme.modules.notification.contentGap

                Row {
                    width: parent.width - colorBadge.width - parent.spacing
                    spacing: rootNotificationCard.theme.modules.notification.contentGap

                    IconImage {
                        width: rootNotificationCard.theme.modules.notification.colorPickerIconSize
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        source: Quickshell.iconPath(rootNotificationCard.service.iconName(rootNotificationCard.notification), "color-picker-symbolic")
                    }

                    Column {
                        width: parent.width - rootNotificationCard.theme.modules.notification.colorPickerIconSize - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: rootNotificationCard.appName
                            color: rootNotificationCard.theme.modules.notification.secondaryTextColor
                            font.pixelSize: rootNotificationCard.theme.modules.notification.metaPixelSize
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "Selected color"
                            color: rootNotificationCard.theme.modules.notification.primaryTextColor
                            font.pixelSize: rootNotificationCard.theme.modules.notification.bodyPixelSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    id: colorBadge

                    width: rootNotificationCard.theme.modules.notification.colorBadgeWidth
                    height: rootNotificationCard.theme.modules.notification.colorBadgeHeight
                    radius: 6
                    color: rootNotificationCard.pickedColor
                    border.width: 1
                    border.color: rootNotificationCard.theme.modules.notification.borderColor
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: rootNotificationCard.pickedColor
                        color: rootNotificationCard.service.contrastTextColor(rootNotificationCard.pickedColor)
                        font.pixelSize: rootNotificationCard.theme.modules.notification.bodyPixelSize
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    function extractColor(value) {
        const match = String(value || "").match(/#[0-9a-fA-F]{6}\b/);
        return match ? match[0].toLowerCase() : "";
    }

    function requestClose(closeAll) {
        if (!popupMode) {
            closeRequested(notification, closeAll);
            return;
        }

        beginExit(true, closeAll);
    }

    function requestAction(action) {
        if (!popupMode) {
            if (action)
                action.invoke();
            return;
        }

        actionInvoked(stableNotificationId, action);
    }

    function requestExpire() {
        if (!popupMode) {
            expired(notification);
            return;
        }

        beginExit(false, false);
    }

    function beginExit(dismiss, closeAll) {
        if (exiting)
            return;

        pendingDismiss = dismiss;
        pendingCloseAll = closeAll;
        exiting = true;
        exitTimer.restart();
    }
}

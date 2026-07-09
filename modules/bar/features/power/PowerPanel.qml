import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: rootPowerPanel

    required property QtObject theme
    required property QtObject service
    property bool panelOpen: false

    signal actionRequested(string action)
    signal closeRequested
    property var pendingAction: null
    property int selectedActionIndex: 0
    property int selectedConfirmIndex: 0
    readonly property bool fullscreen: service.isFullscreen === true

    readonly property var actions: [
        {
            icon: "system-lock-screen-symbolic",
            label: "Lock",
            action: "lock",
            destructive: false,
            confirmTitle: "Lock the screen",
            confirmContent: "Are you sure you want to lock the screen?"
        },
        {
            icon: "system-log-out-symbolic",
            label: "Log out",
            action: "logout",
            destructive: true,
            confirmTitle: "Log out",
            confirmContent: "Are you sure you want to log out?"
        },
        {
            icon: "media-playback-pause-symbolic",
            label: "Suspend",
            action: "suspend",
            destructive: true,
            confirmTitle: "Suspend the system",
            confirmContent: "Are you sure you want to suspend the system?"
        },
        {
            icon: "system-reboot-symbolic",
            label: "Reboot",
            action: "reboot",
            destructive: true,
            confirmTitle: "Reboot the system",
            confirmContent: "Are you sure you want to reboot the system?"
        },
        {
            icon: "system-shutdown-symbolic",
            label: "Power off",
            action: "poweroff",
            destructive: true,
            confirmTitle: "Power off the system",
            confirmContent: "Are you sure you want to power off the system?"
        }
    ]

    function requestAction(action) {
        if (!action.destructive) {
            rootPowerPanel.actionRequested(action.action);
            rootPowerPanel.closeRequested();
            return;
        }
        pendingAction = action;
        selectedConfirmIndex = 0;
    }

    function confirmPendingAction() {
        if (pendingAction == null)
            return;
        rootPowerPanel.actionRequested(pendingAction.action);
        rootPowerPanel.closeRequested();
        pendingAction = null;
    }

    function cancelPendingAction() {
        pendingAction = null;
        selectedConfirmIndex = 0;
    }

    function clampSelection() {
        if (selectedActionIndex < 0)
            selectedActionIndex = 0;
        if (selectedActionIndex >= actions.length)
            selectedActionIndex = actions.length - 1;
        if (selectedConfirmIndex < 0)
            selectedConfirmIndex = 0;
        if (selectedConfirmIndex > 1)
            selectedConfirmIndex = 1;
    }

    function moveActionSelection(step) {
        if (actions.length === 0)
            return;
        selectedActionIndex = (selectedActionIndex + step + actions.length) % actions.length;
    }

    function moveConfirmSelection(step) {
        selectedConfirmIndex = (selectedConfirmIndex + step + 2) % 2;
    }

    function activateSelection() {
        clampSelection();

        if (pendingAction !== null) {
            if (selectedConfirmIndex === 0)
                cancelPendingAction();
            else
                confirmPendingAction();
            return;
        }

        requestAction(actions[selectedActionIndex]);
    }

    function handlePanelKey(event) {
        switch (event.key) {
        case Qt.Key_Up:
            if (pendingAction === null)
                moveActionSelection(-1);
            else
                moveConfirmSelection(-1);
            event.accepted = true;
            break;
        case Qt.Key_Down:
            if (pendingAction === null)
                moveActionSelection(1);
            else
                moveConfirmSelection(1);
            event.accepted = true;
            break;
        case Qt.Key_Left:
            if (pendingAction === null && fullscreen) {
                moveActionSelection(-1);
                event.accepted = true;
            } else if (pendingAction !== null) {
                moveConfirmSelection(-1);
                event.accepted = true;
            }
            break;
        case Qt.Key_Right:
        case Qt.Key_Tab:
            if (pendingAction === null && fullscreen) {
                moveActionSelection(1);
                event.accepted = true;
            } else if (pendingAction !== null) {
                moveConfirmSelection(1);
                event.accepted = true;
            }
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            activateSelection();
            event.accepted = true;
            break;
        }
    }

    function cardWidth() {
        if (fullscreen) {
            const availableWidth = Math.max(rootPowerPanel.theme.modules.bar.power.cardWidth, rootPowerPanel.width - rootPowerPanel.theme.modules.bar.power.fullscreenCardPadding * 2);
            return Math.min(rootPowerPanel.theme.modules.bar.power.fullscreenCardWidth, availableWidth);
        }

        return rootPowerPanel.theme.modules.bar.power.cardWidth;
    }

    function cardPadding() {
        return fullscreen ? rootPowerPanel.theme.modules.bar.power.fullscreenCardPadding : rootPowerPanel.theme.modules.bar.power.cardPadding;
    }

    function actionHeight() {
        return fullscreen ? rootPowerPanel.theme.modules.bar.power.fullscreenActionHeight : rootPowerPanel.theme.modules.bar.power.actionHeight;
    }

    function actionIconSize() {
        return fullscreen ? rootPowerPanel.theme.modules.bar.power.fullscreenActionIconSize : rootPowerPanel.theme.modules.bar.power.actionIconSize;
    }

    function actionLabelWidth() {
        return fullscreen ? rootPowerPanel.theme.modules.bar.power.fullscreenActionLabelWidth : rootPowerPanel.theme.modules.bar.power.actionLabelWidth;
    }

    function activeContentHeight() {
        if (pendingAction !== null)
            return confirmActionList.implicitHeight;

        return fullscreen ? fullscreenActionList.implicitHeight : actionList.implicitHeight;
    }

    implicitWidth: screen.width
    implicitHeight: screen.height

    visible: rootPowerPanel.panelOpen
    color: rootPowerPanel.fullscreen ? rootPowerPanel.theme.modules.bar.power.backgroundColor : "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-popup-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: {
        if (visible) {
            selectedActionIndex = 0;
            selectedConfirmIndex = 0;
            background.forceActiveFocus();
        } else {
            pendingAction = null;
            selectedActionIndex = 0;
            selectedConfirmIndex = 0;
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: rootPowerPanel.visible
        onActivated: {
            if (rootPowerPanel.pendingAction !== null) {
                rootPowerPanel.cancelPendingAction();
                return;
            }

            rootPowerPanel.closeRequested();
        }
    }

    Rectangle {
        id: background

        anchors.fill: parent
        color: "transparent"
        focus: true

        Keys.onPressed: event => rootPowerPanel.handlePanelKey(event)

        MouseArea {
            anchors.fill: parent
            onClicked: rootPowerPanel.closeRequested()
        }

        Rectangle {
            id: sidebar

            anchors {
                top: parent.top
                right: parent.right
                bottom: parent.bottom
                topMargin: rootPowerPanel.fullscreen ? 0 : rootPowerPanel.theme.modules.bar.power.sidebarMargin
                rightMargin: rootPowerPanel.fullscreen ? 0 : rootPowerPanel.theme.modules.bar.power.sidebarMargin
                bottomMargin: rootPowerPanel.fullscreen ? 0 : rootPowerPanel.theme.modules.bar.power.sidebarMargin
            }
            anchors.left: rootPowerPanel.fullscreen ? parent.left : undefined
            width: rootPowerPanel.fullscreen ? parent.width : rootPowerPanel.theme.modules.bar.power.sidebarWidth
            radius: rootPowerPanel.fullscreen ? 0 : rootPowerPanel.theme.modules.bar.power.sidebarRadius
            color: rootPowerPanel.theme.modules.bar.power.backgroundColor
            border.width: rootPowerPanel.fullscreen ? 0 : rootPowerPanel.theme.modules.bar.power.sidebarBorderWidth
            border.color: rootPowerPanel.theme.modules.bar.power.borderColor

            MouseArea {
                anchors.fill: parent
                onClicked: mouse => mouse.accepted = true
            }

            Rectangle {
                id: actionCard

                anchors.centerIn: parent
                width: rootPowerPanel.cardWidth()
                height: rootPowerPanel.activeContentHeight() + rootPowerPanel.cardPadding() * 2
                radius: rootPowerPanel.theme.modules.bar.power.cardRadius
                color: rootPowerPanel.theme.modules.bar.moduleHoverBackgroundColor

                Column {
                    id: actionList
                    visible: rootPowerPanel.pendingAction === null && !rootPowerPanel.fullscreen

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPowerPanel.cardPadding()
                    }
                    spacing: rootPowerPanel.theme.modules.bar.power.actionSpacing

                    Repeater {
                        model: rootPowerPanel.actions

                        delegate: Rectangle {
                            id: actionButton

                            required property var modelData
                            required property int index

                            width: parent.width
                            height: rootPowerPanel.actionHeight()
                            radius: rootPowerPanel.theme.modules.bar.power.actionRadius
                            color: actionHover.hovered || rootPowerPanel.selectedActionIndex === actionButton.index ? rootPowerPanel.theme.modules.bar.power.actionHoverBackgroundColor : rootPowerPanel.theme.modules.bar.power.actionBackgroundColor
                            border.width: rootPowerPanel.selectedActionIndex === actionButton.index ? rootPowerPanel.theme.modules.bar.power.actionSelectedBorderWidth : 0
                            border.color: rootPowerPanel.theme.modules.bar.power.actionSelectedBorderColor

                            Row {
                                anchors.centerIn: parent
                                spacing: rootPowerPanel.theme.modules.bar.power.actionContentSpacing

                                Item {
                                    width: rootPowerPanel.actionIconSize()
                                    height: rootPowerPanel.actionIconSize()
                                    anchors.verticalCenter: parent.verticalCenter

                                    IconImage {
                                        id: icon

                                        anchors.fill: parent
                                        source: Quickshell.iconPath(actionButton.modelData.icon, "application-x-executable-symbolic")
                                        visible: false
                                    }

                                    MultiEffect {
                                        anchors.fill: parent
                                        source: icon
                                        colorization: rootPowerPanel.theme.modules.bar.power.actionIconColorization
                                        brightness: rootPowerPanel.theme.modules.bar.power.actionIconBrightness
                                        colorizationColor: rootPowerPanel.theme.modules.bar.power.actionIconColor
                                    }
                                }

                                Text {
                                    width: rootPowerPanel.actionLabelWidth()
                                    text: actionButton.modelData.label
                                    color: rootPowerPanel.theme.modules.bar.power.actionTextColor
                                    font.pixelSize: rootPowerPanel.theme.modules.bar.power.actionTextPixelSize
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler {
                                id: actionHover

                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: {
                                    if (hovered)
                                        rootPowerPanel.selectedActionIndex = actionButton.index;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    rootPowerPanel.requestAction(actionButton.modelData);
                                }
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }
                    }
                }

                Row {
                    id: fullscreenActionList
                    visible: rootPowerPanel.pendingAction === null && rootPowerPanel.fullscreen

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPowerPanel.cardPadding()
                    }
                    spacing: rootPowerPanel.theme.modules.bar.power.fullscreenActionSpacing

                    Repeater {
                        model: rootPowerPanel.actions

                        delegate: Rectangle {
                            id: fullscreenActionButton

                            required property var modelData
                            required property int index

                            width: (parent.width - parent.spacing * (rootPowerPanel.actions.length - 1)) / rootPowerPanel.actions.length
                            height: rootPowerPanel.actionHeight()
                            radius: rootPowerPanel.theme.modules.bar.power.actionRadius
                            color: fullscreenActionHover.hovered || rootPowerPanel.selectedActionIndex === fullscreenActionButton.index ? rootPowerPanel.theme.modules.bar.power.actionHoverBackgroundColor : rootPowerPanel.theme.modules.bar.power.actionBackgroundColor
                            border.width: rootPowerPanel.selectedActionIndex === fullscreenActionButton.index ? rootPowerPanel.theme.modules.bar.power.actionSelectedBorderWidth : 0
                            border.color: rootPowerPanel.theme.modules.bar.power.actionSelectedBorderColor

                            Column {
                                anchors.centerIn: parent
                                spacing: rootPowerPanel.theme.modules.bar.power.actionContentSpacing

                                Item {
                                    width: rootPowerPanel.actionIconSize()
                                    height: rootPowerPanel.actionIconSize()
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    IconImage {
                                        id: fullscreenIcon

                                        anchors.fill: parent
                                        source: Quickshell.iconPath(fullscreenActionButton.modelData.icon, "application-x-executable-symbolic")
                                        visible: false
                                    }

                                    MultiEffect {
                                        anchors.fill: parent
                                        source: fullscreenIcon
                                        colorization: rootPowerPanel.theme.modules.bar.power.actionIconColorization
                                        brightness: rootPowerPanel.theme.modules.bar.power.actionIconBrightness
                                        colorizationColor: rootPowerPanel.theme.modules.bar.power.actionIconColor
                                    }
                                }

                                Text {
                                    width: rootPowerPanel.actionLabelWidth()
                                    text: fullscreenActionButton.modelData.label
                                    color: rootPowerPanel.theme.modules.bar.power.actionTextColor
                                    font.pixelSize: rootPowerPanel.theme.modules.bar.power.actionTextPixelSize
                                    horizontalAlignment: Text.AlignHCenter
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            HoverHandler {
                                id: fullscreenActionHover

                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: {
                                    if (hovered)
                                        rootPowerPanel.selectedActionIndex = fullscreenActionButton.index;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: rootPowerPanel.requestAction(fullscreenActionButton.modelData)
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }
                    }
                }

                Column {
                    id: confirmActionList
                    visible: rootPowerPanel.pendingAction !== null

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPowerPanel.cardPadding()
                    }
                    spacing: rootPowerPanel.theme.modules.bar.power.actionSpacing

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmTitle : ""
                        color: rootPowerPanel.theme.modules.bar.power.confirmTextColor
                        font.pixelSize: rootPowerPanel.theme.modules.bar.power.confirmTitlePixelSize
                        font.bold: true
                        wrapMode: Text.Wrap
                    }

                    Text {
                        width: parent.width
                        text: rootPowerPanel.pendingAction !== null ? rootPowerPanel.pendingAction.confirmContent : ""
                        color: rootPowerPanel.theme.modules.bar.power.confirmTextColor
                        font.pixelSize: rootPowerPanel.theme.modules.bar.power.confirmContentPixelSize
                        wrapMode: Text.Wrap
                        bottomPadding: rootPowerPanel.theme.modules.bar.power.confirmContentBottomPadding
                    }

                    Row {
                        width: parent.width
                        spacing: rootPowerPanel.theme.modules.bar.power.confirmButtonSpacing

                        Rectangle {
                            id: cancelButton

                            width: (parent.width - parent.spacing) / 2
                            height: rootPowerPanel.actionHeight()
                            radius: rootPowerPanel.theme.modules.bar.power.actionRadius
                            color: cancelHover.hovered || rootPowerPanel.selectedConfirmIndex === 0 ? rootPowerPanel.theme.modules.bar.power.actionHoverBackgroundColor : rootPowerPanel.theme.modules.bar.power.actionBackgroundColor
                            border.width: rootPowerPanel.selectedConfirmIndex === 0 ? rootPowerPanel.theme.modules.bar.power.actionSelectedBorderWidth : 0
                            border.color: rootPowerPanel.theme.modules.bar.power.actionSelectedBorderColor

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: rootPowerPanel.theme.modules.bar.power.actionTextColor
                                font.pixelSize: rootPowerPanel.theme.modules.bar.power.actionTextPixelSize
                            }

                            HoverHandler {
                                id: cancelHover

                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: {
                                    if (hovered)
                                        rootPowerPanel.selectedConfirmIndex = 0;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: rootPowerPanel.cancelPendingAction()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }

                        Rectangle {
                            id: confirmButton

                            width: (parent.width - parent.spacing) / 2
                            height: rootPowerPanel.actionHeight()
                            radius: rootPowerPanel.theme.modules.bar.power.actionRadius
                            color: confirmHover.hovered || rootPowerPanel.selectedConfirmIndex === 1 ? rootPowerPanel.theme.modules.bar.power.actionHoverBackgroundColor : rootPowerPanel.theme.modules.bar.power.actionBackgroundColor
                            border.width: rootPowerPanel.selectedConfirmIndex === 1 ? rootPowerPanel.theme.modules.bar.power.actionSelectedBorderWidth : 0
                            border.color: rootPowerPanel.theme.modules.bar.power.actionSelectedBorderColor

                            Text {
                                anchors.centerIn: parent
                                text: "Confirm"
                                color: rootPowerPanel.theme.modules.bar.power.actionTextColor
                                font.pixelSize: rootPowerPanel.theme.modules.bar.power.actionTextPixelSize
                            }

                            HoverHandler {
                                id: confirmHover

                                cursorShape: Qt.PointingHandCursor
                                onHoveredChanged: {
                                    if (hovered)
                                        rootPowerPanel.selectedConfirmIndex = 1;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: rootPowerPanel.confirmPendingAction()
                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: rootPowerPanel.theme.animationFastDuration
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

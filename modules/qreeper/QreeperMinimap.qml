import QtQuick
import QtCore
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootQreeperMinimap

    required property QtObject theme
    required property QtObject service
    required property QtObject layout

    property bool followEnabled: true
    property int topMargin: positionSettings.topMargin
    property int rightMargin: positionSettings.rightMargin
    property int dragStartTop: 0
    property int dragStartRight: 0

    signal closeRequested
    signal atlasRequested

    implicitWidth: Math.min(theme.modules.qreeper.minimapWidth, screen.width - theme.modules.qreeper.minimapScreenMargin * 2)
    implicitHeight: Math.min(theme.modules.qreeper.minimapHeight, screen.height - theme.modules.qreeper.minimapScreenMargin * 2)
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }

    anchors {
        top: true
        right: true
    }

    WlrLayershell.namespace: "qreep-qreeper-minimap"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.margins.top: rootQreeperMinimap.topMargin
    WlrLayershell.margins.right: rootQreeperMinimap.rightMargin

    Settings {
        id: positionSettings
        location: "file://" + Quickshell.env("HOME") + "/.config/quickshell/qreep-qreeper.ini"
        category: "qreep/qreeper-minimap"
        property int topMargin: rootQreeperMinimap.theme.modules.qreeper.minimapTopMargin
        property int rightMargin: rootQreeperMinimap.theme.modules.qreeper.minimapRightMargin
    }

    Component.onCompleted: {
        clampPosition();
        initialCenterTimer.start();
    }
    onScreenChanged: clampTimer.restart()

    Timer {
        id: clampTimer
        interval: 0
        onTriggered: rootQreeperMinimap.clampPosition()
    }

    Timer {
        id: initialCenterTimer
        interval: 0
        onTriggered: map.centerOnCurrent(false)
    }

    Rectangle {
        id: card

        anchors.fill: parent
        radius: rootQreeperMinimap.theme.modules.qreeper.panelRadius
        color: rootQreeperMinimap.theme.modules.qreeper.panelColor
        border.width: 1
        border.color: rootQreeperMinimap.service.displayState === "error" ? rootQreeperMinimap.theme.modules.qreeper.errorColor : rootQreeperMinimap.theme.modules.qreeper.borderColor
        clip: true

        Item {
            id: header
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: rootQreeperMinimap.theme.modules.qreeper.headerHeight

            Item {
                id: dragHandle
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    right: headerButtons.left
                }

                DragHandler {
                    target: null
                    acceptedButtons: Qt.LeftButton

                    onActiveChanged: {
                        if (active) {
                            rootQreeperMinimap.dragStartTop = rootQreeperMinimap.topMargin;
                            rootQreeperMinimap.dragStartRight = rootQreeperMinimap.rightMargin;
                        } else {
                            rootQreeperMinimap.clampPosition();
                            positionSettings.topMargin = rootQreeperMinimap.topMargin;
                            positionSettings.rightMargin = rootQreeperMinimap.rightMargin;
                            positionSettings.sync();
                        }
                    }
                    onTranslationChanged: {
                        if (!active)
                            return;
                        rootQreeperMinimap.topMargin = rootQreeperMinimap.dragStartTop + translation.y;
                        rootQreeperMinimap.rightMargin = rootQreeperMinimap.dragStartRight - translation.x;
                    }
                }

                Column {
                    anchors {
                        left: parent.left
                        leftMargin: rootQreeperMinimap.theme.modules.qreeper.panelPadding
                        verticalCenter: parent.verticalCenter
                    }
                    width: parent.width - rootQreeperMinimap.theme.modules.qreeper.panelPadding * 2
                    spacing: 1

                    Text {
                        width: parent.width
                        text: rootQreeperMinimap.service.currentRoom ? (rootQreeperMinimap.service.currentRoom.area || rootQreeperMinimap.service.currentRoom.name) : "Qreeper"
                        color: rootQreeperMinimap.theme.modules.qreeper.primaryTextColor
                        font.pixelSize: rootQreeperMinimap.theme.modules.qreeper.bodyPixelSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: rootQreeperMinimap.service.statusLabel + (rootQreeperMinimap.service.currentRoom ? " · " + rootQreeperMinimap.service.locationLabel : "")
                        color: rootQreeperMinimap.service.displayState === "error" ? rootQreeperMinimap.theme.modules.qreeper.errorColor : rootQreeperMinimap.theme.modules.qreeper.secondaryTextColor
                        font.pixelSize: rootQreeperMinimap.theme.modules.qreeper.metaPixelSize
                        elide: Text.ElideRight
                    }
                }
            }

            Row {
                id: headerButtons
                anchors {
                    right: parent.right
                    rightMargin: 7
                    verticalCenter: parent.verticalCenter
                }
                spacing: 5

                Rectangle {
                    width: rootQreeperMinimap.theme.modules.qreeper.controlSize
                    height: width
                    radius: width / 2
                    color: recenterMouse.containsMouse ? rootQreeperMinimap.theme.modules.qreeper.cardColor : "transparent"
                    border.width: map.userPanActive ? 1 : 0
                    border.color: rootQreeperMinimap.theme.modules.qreeper.accentColor
                    Text { anchors.centerIn: parent; text: "◎"; color: rootQreeperMinimap.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperMinimap.theme.modules.qreeper.iconPixelSize }
                    MouseArea {
                        id: recenterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            map.userPanActive = false;
                            rootQreeperMinimap.followEnabled = true;
                            map.centerOnCurrent(true);
                        }
                    }
                }

                Rectangle {
                    width: rootQreeperMinimap.theme.modules.qreeper.controlSize
                    height: width
                    radius: width / 2
                    color: atlasMouse.containsMouse ? rootQreeperMinimap.theme.modules.qreeper.cardColor : "transparent"
                    Text { anchors.centerIn: parent; text: "↗"; color: rootQreeperMinimap.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperMinimap.theme.modules.qreeper.iconPixelSize }
                    MouseArea { id: atlasMouse; anchors.fill: parent; hoverEnabled: true; onClicked: rootQreeperMinimap.atlasRequested() }
                }

                Rectangle {
                    width: rootQreeperMinimap.theme.modules.qreeper.controlSize
                    height: width
                    radius: width / 2
                    color: closeMouse.containsMouse ? rootQreeperMinimap.theme.modules.qreeper.cardColor : "transparent"
                    Text { anchors.centerIn: parent; text: "×"; color: rootQreeperMinimap.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperMinimap.theme.modules.qreeper.iconPixelSize }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: rootQreeperMinimap.closeRequested() }
                }
            }
        }

        MapView {
            id: map
            anchors {
                left: parent.left
                right: parent.right
                top: header.bottom
                bottom: parent.bottom
                margins: 7
                topMargin: 0
            }
            theme: rootQreeperMinimap.theme
            service: rootQreeperMinimap.service
            layout: rootQreeperMinimap.layout
            level: rootQreeperMinimap.service.currentRoom ? (rootQreeperMinimap.service.currentRoom.level !== null ? rootQreeperMinimap.service.currentRoom.level : Number(rootQreeperMinimap.service.currentRoom.z || 0)) : 0
            mapId: rootQreeperMinimap.service.currentRoom ? rootQreeperMinimap.service.currentRoom.mapId : null
            follow: rootQreeperMinimap.followEnabled
            onManuallyPanned: rootQreeperMinimap.followEnabled = false
        }

        Rectangle {
            visible: !rootQreeperMinimap.service.hasSnapshot
            anchors {
                fill: map
                margins: 12
            }
            radius: 10
            color: rootQreeperMinimap.theme.modules.qreeper.mapColor

            Column {
                anchors.centerIn: parent
                width: parent.width - 30
                spacing: 7
                Text {
                    width: parent.width
                    text: rootQreeperMinimap.service.displayState === "error" ? "The map disagrees with reality." : "Waiting for Qreeper"
                    color: rootQreeperMinimap.service.displayState === "error" ? rootQreeperMinimap.theme.modules.qreeper.errorColor : rootQreeperMinimap.theme.modules.qreeper.primaryTextColor
                    font.pixelSize: rootQreeperMinimap.theme.modules.qreeper.titlePixelSize
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    width: parent.width
                    text: rootQreeperMinimap.service.lastError || rootQreeperMinimap.service.snapshotPath
                    color: rootQreeperMinimap.theme.modules.qreeper.secondaryTextColor
                    font.pixelSize: rootQreeperMinimap.theme.modules.qreeper.metaPixelSize
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    function clampPosition() {
        const margin = theme.modules.qreeper.minimapScreenMargin;
        topMargin = Math.max(margin, Math.min(topMargin, Math.max(margin, screen.height - height - margin)));
        rightMargin = Math.max(margin, Math.min(rightMargin, Math.max(margin, screen.width - width - margin)));
    }

    function recenter() {
        followEnabled = true;
        map.userPanActive = false;
    }
}

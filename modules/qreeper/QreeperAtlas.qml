import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: rootQreeperAtlas

    required property QtObject theme
    required property QtObject service
    required property QtObject layout
    property var selectedRoomId: service.currentRoomId
    readonly property var selectedRoom: service.roomForId(selectedRoomId)
    readonly property var selectedExits: selectedRoom ? service.exitsFrom(selectedRoom.id) : []

    signal closeRequested
    signal fontScaleStepRequested(int direction)

    implicitWidth: screen.width
    implicitHeight: screen.height
    visible: true
    color: theme.modules.qreeper.atlasOverlayColor
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
        bottom: true
        left: true
    }

    WlrLayershell.namespace: "qreep-qreeper-atlas"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        background.forceActiveFocus();
        initialCenter.start();
    }

    Shortcut { sequence: "Escape"; context: Qt.WindowShortcut; onActivated: rootQreeperAtlas.closeRequested() }

    Timer {
        id: initialCenter
        interval: 0
        onTriggered: map.centerOnCurrent(false)
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "transparent"
        focus: true
        MouseArea { anchors.fill: parent; onClicked: rootQreeperAtlas.closeRequested() }
    }

    Rectangle {
        id: atlasCard
        anchors.fill: parent
        anchors.margins: rootQreeperAtlas.theme.modules.qreeper.atlasMargin
        radius: rootQreeperAtlas.theme.modules.qreeper.panelRadius
        color: rootQreeperAtlas.theme.modules.qreeper.panelColor
        border.width: 1
        border.color: rootQreeperAtlas.theme.modules.qreeper.borderColor
        clip: true

        MouseArea { anchors.fill: parent; onClicked: mouse => mouse.accepted = true }

        Item {
            id: atlasHeader
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Math.round(54 * rootQreeperAtlas.theme.modules.qreeper.fontScale)

            Column {
                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                spacing: 2
                Text { text: "Qreeper Atlas"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.atlasTitlePixelSize; font.weight: Font.DemiBold }
                Text { text: rootQreeperAtlas.service.statusLabel + " · revision " + rootQreeperAtlas.service.revision; color: rootQreeperAtlas.theme.modules.qreeper.secondaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.metaPixelSize }
            }

            Row {
                anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                spacing: 7
                Rectangle {
                    width: Math.round(34 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "−"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.iconPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: map.level-- }
                }
                Rectangle {
                    width: Math.round(72 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "level " + map.level; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: { if (rootQreeperAtlas.service.currentRoom) map.level = rootQreeperAtlas.service.currentRoom.level !== null ? rootQreeperAtlas.service.currentRoom.level : Number(rootQreeperAtlas.service.currentRoom.z || 0); } }
                }
                Rectangle {
                    width: Math.round(34 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "+"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.iconPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: map.level++ }
                }
                Rectangle {
                    width: Math.round(88 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "current ◎"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: map.centerOnCurrent(true) }
                }
                // Re-run the organic layout; pinned rooms stay where you put them.
                Rectangle {
                    width: Math.round(92 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "rearrange"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: rootQreeperAtlas.layout.rearrange() }
                }
                // Forget every position and pin. Double-click, because it throws away your arranging.
                Rectangle {
                    width: Math.round(72 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "reset"; color: rootQreeperAtlas.theme.modules.qreeper.secondaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize }
                    MouseArea { anchors.fill: parent; onDoubleClicked: rootQreeperAtlas.layout.reset() }
                }
                // Text size, for displays where the default reads like a footnote.
                Rectangle {
                    width: Math.round(40 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "A−"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: rootQreeperAtlas.fontScaleStepRequested(-1) }
                }
                Rectangle {
                    width: Math.round(40 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 7; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "A+"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: rootQreeperAtlas.fontScaleStepRequested(1) }
                }
                Rectangle {
                    width: Math.round(34 * rootQreeperAtlas.theme.modules.qreeper.fontScale); height: Math.round(30 * rootQreeperAtlas.theme.modules.qreeper.fontScale); radius: 17; color: rootQreeperAtlas.theme.modules.qreeper.cardColor
                    Text { anchors.centerIn: parent; text: "×"; color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.iconPixelSize }
                    MouseArea { anchors.fill: parent; onClicked: rootQreeperAtlas.closeRequested() }
                }
            }
        }

        MapView {
            id: map
            anchors {
                left: parent.left
                right: details.left
                top: atlasHeader.bottom
                bottom: parent.bottom
                margins: 10
                topMargin: 0
                rightMargin: 6
            }
            theme: rootQreeperAtlas.theme
            service: rootQreeperAtlas.service
            layout: rootQreeperAtlas.layout
            selectedRoomId: rootQreeperAtlas.selectedRoomId
            level: rootQreeperAtlas.service.currentRoom ? (rootQreeperAtlas.service.currentRoom.level !== null ? rootQreeperAtlas.service.currentRoom.level : Number(rootQreeperAtlas.service.currentRoom.z || 0)) : 0
            mapId: rootQreeperAtlas.service.currentRoom ? rootQreeperAtlas.service.currentRoom.mapId : null
            onRoomSelected: room => rootQreeperAtlas.selectedRoomId = room.id
        }

        Rectangle {
            id: details
            anchors {
                right: parent.right
                top: atlasHeader.bottom
                bottom: parent.bottom
                margins: 10
                topMargin: 0
            }
            width: rootQreeperAtlas.theme.modules.qreeper.atlasSidebarWidth
            radius: 10
            color: rootQreeperAtlas.theme.modules.qreeper.cardColor

            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentWidth: width
                contentHeight: detailsLayout.implicitHeight
                clip: true

                Column {
                    id: detailsLayout
                    width: parent.width
                    spacing: 9

                    Text {
                        width: parent.width
                        text: rootQreeperAtlas.selectedRoom ? rootQreeperAtlas.selectedRoom.name : "Select a room"
                        color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor
                        font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.titlePixelSize
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                    }
                    Text {
                        visible: !!rootQreeperAtlas.selectedRoom
                        width: parent.width
                        text: rootQreeperAtlas.selectedRoom ? rootQreeperAtlas.service.roomLocation(rootQreeperAtlas.selectedRoom) + " · " + rootQreeperAtlas.selectedRoom.positionStatus : ""
                        color: rootQreeperAtlas.theme.modules.qreeper.secondaryTextColor
                        font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.metaPixelSize
                        wrapMode: Text.Wrap
                    }
                    Text {
                        visible: !!rootQreeperAtlas.selectedRoom && rootQreeperAtlas.selectedRoom.description.length > 0
                        width: parent.width
                        text: rootQreeperAtlas.selectedRoom ? rootQreeperAtlas.selectedRoom.description : ""
                        color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor
                        font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Text {
                        visible: !!rootQreeperAtlas.selectedRoom && rootQreeperAtlas.layout.isPinned(rootQreeperAtlas.selectedRoom.id)
                        text: "Pinned by you · right-click the room to release"
                        color: rootQreeperAtlas.theme.modules.qreeper.accentColor
                        font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.metaPixelSize
                    }

                    Text { visible: !!rootQreeperAtlas.selectedRoom; text: "Exits"; color: rootQreeperAtlas.theme.modules.qreeper.accentColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize; font.weight: Font.DemiBold }

                    Repeater {
                        model: rootQreeperAtlas.selectedExits
                        Text {
                            required property var modelData
                            width: detailsLayout.width
                            text: "• " + modelData.direction + " → " + (modelData.to === null ? "unexplored" : "#" + modelData.to) + (modelData.geometry === "regular" ? "" : "  [" + modelData.geometry + "]")
                            color: modelData.geometry === "regular" ? rootQreeperAtlas.theme.modules.qreeper.primaryTextColor : rootQreeperAtlas.theme.modules.qreeper.irregularColor
                            font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize
                            wrapMode: Text.Wrap
                        }
                    }

                    Text { visible: !!rootQreeperAtlas.selectedRoom; text: "Notes"; color: rootQreeperAtlas.theme.modules.qreeper.accentColor; font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize; font.weight: Font.DemiBold }
                    Text {
                        visible: !!rootQreeperAtlas.selectedRoom && rootQreeperAtlas.selectedRoom.notes.length === 0
                        text: "No notes. Suspiciously tidy."
                        color: rootQreeperAtlas.theme.modules.qreeper.secondaryTextColor
                        font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize
                    }
                    Repeater {
                        model: rootQreeperAtlas.selectedRoom ? rootQreeperAtlas.selectedRoom.notes : []
                        Text {
                            required property var modelData
                            width: detailsLayout.width
                            text: "• " + modelData.text
                            color: rootQreeperAtlas.theme.modules.qreeper.primaryTextColor
                            font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.bodyPixelSize
                            wrapMode: Text.Wrap
                        }
                    }

                    Text {
                        width: parent.width
                        text: "Every exit leaves its room in its recorded direction, then follows the path. Solid: the geography agrees. Dashed with arrows: the exit is real but contradicts its neighbours. Accent: named exits. Dotted stubs: unexplored. Drag a room to pin it; right-click to release. Proximity is not navigation truth."
                        color: rootQreeperAtlas.theme.modules.qreeper.secondaryTextColor
                        font.pixelSize: rootQreeperAtlas.theme.modules.qreeper.metaPixelSize
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}

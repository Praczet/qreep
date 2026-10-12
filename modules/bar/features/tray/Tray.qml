import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../../../components" as Components

Components.QreepModule {
    id: rootTray

    readonly property int itemCount: trayItems.count

    function showMenu(trayItem, anchorItem) {
        if (!trayItem || !trayItem.hasMenu || !rootTray.window)
            return;

        const point = anchorItem.mapToItem(null, 0, anchorItem.height);
        trayItem.display(rootTray.window, Math.round(point.x), Math.round(point.y));
    }

    Row {
        id: trayContent

        spacing: rootTray.theme.modules.bar.tray.itemSpacing

        Repeater {
            id: trayItems

            model: SystemTray.items

            delegate: Item {
                id: rootTrayItem

                required property SystemTrayItem modelData

                width: rootTray.theme.modules.bar.tray.iconSize
                height: rootTray.theme.modules.bar.tray.iconSize

                IconImage {
                    anchors.fill: parent
                    source: rootTrayItem.modelData.icon
                    opacity: rootTrayItem.modelData.status === Status.Passive
                        ? rootTray.theme.modules.bar.tray.passiveOpacity
                        : 1
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true

                    onEntered: {
                        const title = rootTrayItem.modelData.tooltipTitle
                            || rootTrayItem.modelData.title
                            || rootTrayItem.modelData.id;
                        rootTray.tooltipShowRequested(rootTrayItem, title, rootTrayItem.modelData.tooltipDescription, "normal");
                    }
                    onExited: rootTray.tooltipHideRequested()
                    onClicked: mouse => {
                        rootTray.tooltipHideRequested();

                        if (mouse.button === Qt.RightButton) {
                            rootTray.showMenu(rootTrayItem.modelData, rootTrayItem);
                        } else if (mouse.button === Qt.MiddleButton) {
                            rootTrayItem.modelData.secondaryActivate();
                        } else if (rootTrayItem.modelData.onlyMenu) {
                            rootTray.showMenu(rootTrayItem.modelData, rootTrayItem);
                        } else {
                            rootTrayItem.modelData.activate();
                        }
                    }
                    onWheel: wheel => {
                        const horizontal = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y);
                        const delta = horizontal ? wheel.angleDelta.x : wheel.angleDelta.y;
                        rootTrayItem.modelData.scroll(delta, horizontal);
                        wheel.accepted = true;
                    }
                }
            }
        }
    }
}

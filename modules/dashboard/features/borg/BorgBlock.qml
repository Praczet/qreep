import QtQuick
import QtQuick.Layouts

Item {
    id: rootBorgBlock

    required property QtObject theme
    property var config: ({})

    implicitHeight: content.implicitHeight

    BorgStatusService {
        id: borgStatus

        config: rootBorgBlock.config
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Borg"
                color: rootBorgBlock.theme.modules.dashboard.primaryTextColor
                font.pixelSize: 24
                font.weight: Font.DemiBold
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: statusText.implicitWidth + 18
                Layout.preferredHeight: 26
                radius: height / 2
                color: statusColor(0.18)
                border.width: 1
                border.color: statusColor(0.72)

                Text {
                    id: statusText

                    anchors.centerIn: parent
                    text: borgStatus.statusText
                    color: statusColor(1)
                    font.pixelSize: rootBorgBlock.theme.modules.dashboard.metaPixelSize
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: borgStatus.finishedText
            color: rootBorgBlock.theme.modules.dashboard.primaryTextColor
            font.pixelSize: rootBorgBlock.theme.modules.dashboard.bodyPixelSize
            font.weight: Font.Medium
            elide: Text.ElideRight
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 14
            rowSpacing: 7

            Text {
                text: "Profile"
                color: rootBorgBlock.theme.modules.dashboard.secondaryTextColor
                font.pixelSize: rootBorgBlock.theme.modules.dashboard.metaPixelSize
                Layout.preferredWidth: 70
            }

            Text {
                Layout.fillWidth: true
                text: borgStatus.profile.length > 0 ? borgStatus.profile : "Unknown"
                color: rootBorgBlock.theme.modules.dashboard.primaryTextColor
                font.pixelSize: rootBorgBlock.theme.modules.dashboard.bodyPixelSize
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            Text {
                text: "Archive"
                color: rootBorgBlock.theme.modules.dashboard.secondaryTextColor
                font.pixelSize: rootBorgBlock.theme.modules.dashboard.metaPixelSize
                Layout.preferredWidth: 70
            }

            Text {
                Layout.fillWidth: true
                text: borgStatus.archive.length > 0 ? borgStatus.archive : "Unknown"
                color: rootBorgBlock.theme.modules.dashboard.primaryTextColor
                font.pixelSize: rootBorgBlock.theme.modules.dashboard.bodyPixelSize
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideMiddle
            }

            Text {
                text: "RC"
                color: rootBorgBlock.theme.modules.dashboard.secondaryTextColor
                font.pixelSize: rootBorgBlock.theme.modules.dashboard.metaPixelSize
                Layout.preferredWidth: 70
            }

            Text {
                Layout.fillWidth: true
                text: borgStatus.rc >= 0 ? String(borgStatus.rc) : "Unknown"
                color: rootBorgBlock.theme.modules.dashboard.primaryTextColor
                font.pixelSize: rootBorgBlock.theme.modules.dashboard.bodyPixelSize
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }

        Text {
            visible: borgStatus.message.length > 0 || borgStatus.error.length > 0
            Layout.fillWidth: true
            text: borgStatus.message.length > 0 ? borgStatus.message : borgStatus.error
            color: borgStatus.error.length > 0 ? rootBorgBlock.theme.modules.dashboard.errorColor : rootBorgBlock.theme.modules.dashboard.secondaryTextColor
            font.pixelSize: rootBorgBlock.theme.modules.dashboard.metaPixelSize
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    function statusColor(alpha) {
        const state = String(borgStatus.state || "");
        const source = state === "success" ? rootBorgBlock.theme.modules.dashboard.accentColor
            : (state === "running" ? rootBorgBlock.theme.modules.dashboard.secondaryTextColor : rootBorgBlock.theme.modules.dashboard.errorColor);

        return Qt.rgba(source.r, source.g, source.b, alpha);
    }
}

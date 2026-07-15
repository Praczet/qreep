import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick.Effects

PanelWindow {
    id: rootPolkitPanel

    required property QtObject theme
    required property QtObject service
    required property bool panelOpen

    property bool presented: false

    signal closeRequested(string reason)
    signal authenticated

    implicitWidth: screen.width
    implicitHeight: screen.height

    color: rootPolkitPanel.theme.modules.polkit.overlayColor
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    WlrLayershell.namespace: "qreep-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
        passwordInput.forceActiveFocus();
        if (panelOpen)
            enterTimer.restart();
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
            enterTimer.restart();
            return;
        }

        enterTimer.stop();
        presented = false;
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: rootPolkitPanel.closeRequested("escape")
    }

    Timer {
        id: enterTimer

        interval: 16
        repeat: false
        onTriggered: presented = true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: rootPolkitPanel.closeRequested("outside")
    }

    Rectangle {
        id: card

        width: Math.min(rootPolkitPanel.theme.modules.polkit.panelWidth, rootPolkitPanel.width - 28)
        height: formContent.implicitHeight + rootPolkitPanel.theme.modules.polkit.panelPadding * 2

        anchors.centerIn: parent

        radius: rootPolkitPanel.theme.modules.polkit.panelRadius
        color: rootPolkitPanel.theme.modules.polkit.panelColor
        border.color: rootPolkitPanel.theme.modules.polkit.borderColor
        opacity: rootPolkitPanel.presented ? 1 : 0
        scale: rootPolkitPanel.presented ? 1 : 0.97

        border.width: 0
        clip: false

        Behavior on opacity {
            NumberAnimation {
                duration: rootPolkitPanel.theme.modules.polkit.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: rootPolkitPanel.theme.modules.polkit.animationDuration
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }
        /*
     * This rectangle provides the alpha mask.
     * ShaderEffectSource hides the actual white rectangle while still
     * allowing MultiEffect to use it.
     */
        Rectangle {
            id: roundedCardMask

            anchors.fill: parent
            radius: card.radius
            color: "white"
        }

        Row {
            id: content

            anchors.fill: parent
            spacing: 0

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true

                maskSource: ShaderEffectSource {
                    sourceItem: roundedCardMask
                    hideSource: true
                }
            }

            Rectangle {
                id: artworkFrame

                width: visible ? rootPolkitPanel.theme.modules.polkit.artworkRailWidth : 0
                height: parent.height
                color: "transparent"
                clip: true
                visible: rootPolkitPanel.service.artworkSource.length > 0

                Image {
                    anchors.fill: parent
                    source: rootPolkitPanel.service.artworkSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    clip: true
                }
            }

            Item {
                width: parent.width - artworkFrame.width
                height: parent.height

                Column {
                    id: formContent

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: rootPolkitPanel.theme.modules.polkit.panelPadding
                    }
                    spacing: rootPolkitPanel.theme.modules.polkit.sectionSpacing

                    readonly property bool hasDetails: rootPolkitPanel.service.detailText.length > 0 || rootPolkitPanel.service.actionId.length > 0

                    Row {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: rootPolkitPanel.theme.modules.polkit.iconBoxSize
                            height: rootPolkitPanel.theme.modules.polkit.iconBoxSize
                            radius: 7
                            color: rootPolkitPanel.theme.modules.polkit.fieldColor
                            border.width: 1
                            border.color: rootPolkitPanel.theme.modules.polkit.borderColor

                            IconImage {
                                anchors.centerIn: parent
                                width: rootPolkitPanel.theme.modules.polkit.iconSize
                                height: width
                                source: Quickshell.iconPath(rootPolkitPanel.service.iconName, "dialog-password-symbolic")
                            }
                        }

                        Column {
                            width: parent.width - rootPolkitPanel.theme.modules.polkit.iconBoxSize - parent.spacing
                            spacing: 4

                            Text {
                                width: parent.width
                                text: rootPolkitPanel.service.title
                                color: rootPolkitPanel.theme.modules.polkit.primaryTextColor
                                font.pixelSize: rootPolkitPanel.theme.modules.polkit.titlePixelSize
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: rootPolkitPanel.service.sourceLabel
                                color: rootPolkitPanel.theme.modules.polkit.secondaryTextColor
                                font.pixelSize: rootPolkitPanel.theme.modules.polkit.metaPixelSize
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: rootPolkitPanel.service.message
                        color: rootPolkitPanel.theme.modules.polkit.primaryTextColor
                        font.pixelSize: rootPolkitPanel.theme.modules.polkit.bodyPixelSize
                        wrapMode: Text.Wrap
                    }

                    Rectangle {
                        visible: formContent.hasDetails
                        width: parent.width
                        height: detailColumn.implicitHeight + 18
                        radius: 7
                        color: rootPolkitPanel.theme.modules.polkit.fieldColor
                        border.width: 1
                        border.color: rootPolkitPanel.theme.modules.polkit.borderColor

                        Column {
                            id: detailColumn

                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                margins: 10
                            }
                            spacing: 5

                            Text {
                                visible: rootPolkitPanel.service.detailText.length > 0
                                width: parent.width
                                text: rootPolkitPanel.service.detailText
                                color: rootPolkitPanel.theme.modules.polkit.secondaryTextColor
                                font.pixelSize: rootPolkitPanel.theme.modules.polkit.detailPixelSize
                                wrapMode: Text.Wrap
                            }

                            Text {
                                visible: rootPolkitPanel.service.actionId.length > 0
                                width: parent.width
                                text: "Action: " + rootPolkitPanel.service.actionId
                                color: rootPolkitPanel.theme.modules.polkit.primaryTextColor
                                font.pixelSize: rootPolkitPanel.theme.modules.polkit.actionPixelSize
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            width: parent.width
                            text: rootPolkitPanel.service.inputPrompt + " for " + rootPolkitPanel.service.userName
                            color: rootPolkitPanel.theme.modules.polkit.secondaryTextColor
                            font.pixelSize: rootPolkitPanel.theme.modules.polkit.metaPixelSize
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: parent.width
                            height: rootPolkitPanel.theme.modules.polkit.fieldHeight
                            radius: 7
                            color: rootPolkitPanel.theme.modules.polkit.fieldColor
                            border.width: 1
                            border.color: passwordInput.activeFocus ? rootPolkitPanel.theme.modules.polkit.focusBorderColor : rootPolkitPanel.theme.modules.polkit.borderColor

                            TextInput {
                                id: passwordInput

                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                echoMode: TextInput.Password
                                passwordCharacter: "*"
                                color: rootPolkitPanel.theme.modules.polkit.primaryTextColor
                                selectionColor: rootPolkitPanel.theme.modules.polkit.accentColor
                                selectedTextColor: rootPolkitPanel.theme.modules.polkit.panelColor
                                font.pixelSize: rootPolkitPanel.theme.modules.polkit.bodyPixelSize
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (rootPolkitPanel.service.submitDemo(text))
                                            rootPolkitPanel.authenticated();
                                        event.accepted = true;
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: rootPolkitPanel.service.statusText.length > 0
                            text: rootPolkitPanel.service.statusText
                            color: rootPolkitPanel.service.authenticated ? rootPolkitPanel.theme.modules.polkit.successColor : rootPolkitPanel.theme.modules.polkit.errorColor
                            font.pixelSize: rootPolkitPanel.theme.modules.polkit.metaPixelSize
                            wrapMode: Text.Wrap
                        }
                    }

                    Row {
                        width: parent.width
                        height: rootPolkitPanel.theme.modules.polkit.buttonHeight
                        spacing: 8
                        layoutDirection: Qt.RightToLeft

                        Rectangle {
                            width: rootPolkitPanel.theme.modules.polkit.buttonWidth
                            height: parent.height
                            radius: 7
                            color: authHover.containsMouse ? rootPolkitPanel.theme.modules.polkit.accentColor : rootPolkitPanel.theme.modules.polkit.actionColor

                            Text {
                                anchors.centerIn: parent
                                text: "Authenticate"
                                color: rootPolkitPanel.theme.modules.polkit.actionTextColor
                                font.pixelSize: rootPolkitPanel.theme.modules.polkit.bodyPixelSize
                                font.bold: true
                            }

                            MouseArea {
                                id: authHover

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (rootPolkitPanel.service.submitDemo(passwordInput.text))
                                        rootPolkitPanel.authenticated();
                                }
                            }
                        }

                        Rectangle {
                            width: rootPolkitPanel.theme.modules.polkit.buttonWidth
                            height: parent.height
                            radius: 7
                            color: cancelHover.containsMouse ? rootPolkitPanel.theme.modules.polkit.fieldColor : rootPolkitPanel.theme.modules.polkit.quietActionColor
                            border.width: 1
                            border.color: rootPolkitPanel.theme.modules.polkit.borderColor

                            Text {
                                anchors.centerIn: parent
                                text: "Cancel"
                                color: rootPolkitPanel.theme.modules.polkit.quietActionTextColor
                                font.pixelSize: rootPolkitPanel.theme.modules.polkit.bodyPixelSize
                            }

                            MouseArea {
                                id: cancelHover

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: rootPolkitPanel.closeRequested("cancel-button")
                            }
                        }
                    }
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: card.radius

            color: "transparent"
            border.width: 1
            border.color: rootPolkitPanel.theme.modules.polkit.borderColor

            z: 100
        }
    }
}

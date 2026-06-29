import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootMprisButton

    required property QtObject service
    readonly property real noteStartX: theme.modules.bar.pill.horizontalPadding / 2 + theme.modules.bar.mpris.noteLayerWidth / 2
    readonly property real noteStartY: height / 2

    tooltipTitle: rootMprisButton.service.tooltipTitle
    tooltipContent: ""
    clip: false

    Item {
        id: pillContent

        implicitWidth: pillRow.implicitWidth
        implicitHeight: pillRow.implicitHeight

        Row {
            id: pillRow

            spacing: rootMprisButton.theme.modules.bar.mpris.pillContentSpacing
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: iconLayer

                width: Math.max(playbackIcon.implicitWidth, rootMprisButton.theme.modules.bar.mpris.noteLayerWidth)
                height: playbackIcon.implicitHeight

                Text {
                    id: playbackIcon

                    anchors.centerIn: parent
                    text: rootMprisButton.service.playbackStateIcon
                    color: rootMprisButton.theme.modules.bar.primaryTextColor
                    font.family: rootMprisButton.theme.iconFontFamily
                    font.pixelSize: rootMprisButton.theme.modules.bar.mpris.pillIconPixelSize
                }
            }

            Text {
                width: rootMprisButton.theme.modules.bar.mpris.pillAlbumWidth
                text: rootMprisButton.service.album
                color: rootMprisButton.theme.modules.bar.secondaryTextColor
                elide: Text.ElideRight
                font.pixelSize: rootMprisButton.theme.modules.bar.mpris.pillMutedTextPixelSize
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: rootMprisButton.theme.modules.bar.mpris.pillTitleWidth
                text: rootMprisButton.service.title
                color: rootMprisButton.theme.modules.bar.primaryTextColor
                elide: Text.ElideRight
                font.pixelSize: rootMprisButton.theme.modules.bar.mpris.pillTextPixelSize
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: rootMprisButton.theme.modules.bar.mpris.pillArtistWidth
                text: rootMprisButton.service.artists
                color: rootMprisButton.theme.modules.bar.secondaryTextColor
                elide: Text.ElideRight
                font.pixelSize: rootMprisButton.theme.modules.bar.mpris.pillMutedTextPixelSize
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    overlay: Item {
        anchors.fill: parent
        clip: false
        visible: rootMprisButton.theme.modules.bar.mpris.animatePlayingNotes && rootMprisButton.service.isPlaying

        Repeater {
            model: 3

            Text {
                id: note

                readonly property int noteIndex: index
                property real drift: 0
                property real peakOpacity: 0.45
                property real spinFrom: 0
                property real spinTo: 0
                readonly property int travelDuration: rootMprisButton.theme.modules.bar.mpris.noteFadeDuration

                function randomize() {
                    drift = -14 + Math.random() * 28;
                    peakOpacity = 0.25 + Math.random() * 0.45;
                    spinFrom = -22 + Math.random() * 44;
                    spinTo = spinFrom + (Math.random() > 0.5 ? 1 : -1) * (26 + Math.random() * 44);
                }

                x: rootMprisButton.noteStartX
                y: rootMprisButton.noteStartY
                text: noteIndex === 1 ? "♫" : "♪"
                color: rootMprisButton.theme.modules.bar.primaryTextColor
                opacity: 0
                rotation: noteIndex * 18
                font.pixelSize: rootMprisButton.theme.modules.bar.mpris.notePixelSize

                SequentialAnimation on y {
                    running: note.visible
                    loops: Animation.Infinite
                    PauseAnimation {
                        duration: note.noteIndex * rootMprisButton.theme.modules.bar.mpris.noteStaggerDuration
                    }
                    ScriptAction {
                        script: note.randomize()
                    }
                    NumberAnimation {
                        from: rootMprisButton.noteStartY
                        to: -rootMprisButton.theme.modules.bar.mpris.notePixelSize
                        duration: note.travelDuration
                        easing.type: Easing.OutCubic
                    }
                }

                SequentialAnimation on opacity {
                    running: note.visible
                    loops: Animation.Infinite
                    PauseAnimation {
                        duration: note.noteIndex * rootMprisButton.theme.modules.bar.mpris.noteStaggerDuration
                    }
                    NumberAnimation {
                        from: 0
                        to: note.peakOpacity
                        duration: 200
                    }
                    NumberAnimation {
                        from: note.peakOpacity
                        to: 0
                        duration: note.travelDuration
                    }
                }

                SequentialAnimation on x {
                    running: note.visible
                    loops: Animation.Infinite
                    PauseAnimation {
                        duration: note.noteIndex * rootMprisButton.theme.modules.bar.mpris.noteStaggerDuration
                    }
                    NumberAnimation {
                        from: rootMprisButton.noteStartX
                        to: rootMprisButton.noteStartX + note.drift
                        duration: note.travelDuration
                        easing.type: Easing.InOutSine
                    }
                }

                RotationAnimation on rotation {
                    running: note.visible
                    loops: Animation.Infinite
                    from: note.spinFrom
                    to: note.spinTo
                    duration: note.travelDuration
                    easing.type: Easing.InOutSine
                }

                Component.onCompleted: randomize()
            }
        }
    }
}

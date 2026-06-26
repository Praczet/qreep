import QtQuick
import "../../../../components" as Components

Components.QreepModule {
    id: rootMprisButton

    required property QtObject service
    readonly property real noteStartX: theme.module.horizontalPadding / 2 + theme.mpris.noteLayerWidth / 2
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

            spacing: rootMprisButton.theme.mpris.pillContentSpacing
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: iconLayer

                width: Math.max(playbackIcon.implicitWidth, rootMprisButton.theme.mpris.noteLayerWidth)
                height: playbackIcon.implicitHeight

                Text {
                    id: playbackIcon

                    anchors.centerIn: parent
                    text: rootMprisButton.service.playbackStateIcon
                    color: rootMprisButton.theme.primaryText
                    font.family: rootMprisButton.theme.iconFontFamily
                    font.pixelSize: rootMprisButton.theme.mpris.pillIconPixelSize
                }
            }

            Text {
                width: rootMprisButton.theme.mpris.pillAlbumWidth
                text: rootMprisButton.service.album
                color: rootMprisButton.theme.secondaryText
                elide: Text.ElideRight
                font.pixelSize: rootMprisButton.theme.mpris.pillMutedTextPixelSize
                horizontalAlignment: Text.AlignLeft
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: rootMprisButton.theme.mpris.pillTitleWidth
                text: rootMprisButton.service.title
                color: rootMprisButton.theme.primaryText
                elide: Text.ElideRight
                font.pixelSize: rootMprisButton.theme.mpris.pillTextPixelSize
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: rootMprisButton.theme.mpris.pillArtistWidth
                text: rootMprisButton.service.artists
                color: rootMprisButton.theme.secondaryText
                elide: Text.ElideRight
                font.pixelSize: rootMprisButton.theme.mpris.pillMutedTextPixelSize
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    overlay: Item {
        anchors.fill: parent
        clip: false
        visible: rootMprisButton.theme.mpris.animatePlayingNotes && rootMprisButton.service.isPlaying

        Repeater {
            model: 3

            Text {
                id: note

                readonly property int noteIndex: index
                property real drift: 0
                property real peakOpacity: 0.45
                property real spinFrom: 0
                property real spinTo: 0
                readonly property int travelDuration: rootMprisButton.theme.mpris.noteFadeDuration

                function randomize() {
                    drift = -14 + Math.random() * 28;
                    peakOpacity = 0.25 + Math.random() * 0.45;
                    spinFrom = -22 + Math.random() * 44;
                    spinTo = spinFrom + (Math.random() > 0.5 ? 1 : -1) * (26 + Math.random() * 44);
                }

                x: rootMprisButton.noteStartX
                y: rootMprisButton.noteStartY
                text: noteIndex === 1 ? "♫" : "♪"
                color: rootMprisButton.theme.primaryText
                opacity: 0
                rotation: noteIndex * 18
                font.pixelSize: rootMprisButton.theme.mpris.notePixelSize

                SequentialAnimation on y {
                    running: note.visible
                    loops: Animation.Infinite
                    PauseAnimation {
                        duration: note.noteIndex * rootMprisButton.theme.mpris.noteStaggerDuration
                    }
                    ScriptAction {
                        script: note.randomize()
                    }
                    NumberAnimation {
                        from: rootMprisButton.noteStartY
                        to: -rootMprisButton.theme.mpris.notePixelSize
                        duration: note.travelDuration
                        easing.type: Easing.OutCubic
                    }
                }

                SequentialAnimation on opacity {
                    running: note.visible
                    loops: Animation.Infinite
                    PauseAnimation {
                        duration: note.noteIndex * rootMprisButton.theme.mpris.noteStaggerDuration
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
                        duration: note.noteIndex * rootMprisButton.theme.mpris.noteStaggerDuration
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

import QtQuick

// One channel of the universe: a track painted with what the channel does
// (seven colour stops), a handle, the value as text. Drag or click to set.
Item {
    id: rootPrismSlider

    required property QtObject pt
    property string label: ""
    property string valueText: ""
    // 0..1
    property real value: 0
    // Exactly seven colours, left to right.
    property var stops: ["#000000", "#000000", "#000000", "#000000", "#000000", "#000000", "#000000"]

    signal moved(real value)

    height: 26

    Text {
        id: labelText

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: 18
        text: rootPrismSlider.label
        color: rootPrismSlider.pt.secondaryTextColor
        font.pixelSize: rootPrismSlider.pt.bodyPixelSize
        font.bold: true
    }

    Rectangle {
        id: track

        anchors {
            left: labelText.right
            leftMargin: 8
            right: valueLabel.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
        height: 14
        radius: 7
        border.width: 1
        border.color: rootPrismSlider.pt.borderColor

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop { position: 0 / 6; color: rootPrismSlider.stops[0] }
            GradientStop { position: 1 / 6; color: rootPrismSlider.stops[1] }
            GradientStop { position: 2 / 6; color: rootPrismSlider.stops[2] }
            GradientStop { position: 3 / 6; color: rootPrismSlider.stops[3] }
            GradientStop { position: 4 / 6; color: rootPrismSlider.stops[4] }
            GradientStop { position: 5 / 6; color: rootPrismSlider.stops[5] }
            GradientStop { position: 6 / 6; color: rootPrismSlider.stops[6] }
        }

        Rectangle {
            x: Math.max(0, Math.min(track.width, rootPrismSlider.value * track.width)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            color: "transparent"
            border.width: 3
            border.color: "white"

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: "#80000000"
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            preventStealing: true

            function emit(mouse) {
                rootPrismSlider.moved(Math.max(0, Math.min(1, (mouse.x - 6) / track.width)));
            }

            onPressed: mouse => emit(mouse)
            onPositionChanged: mouse => emit(mouse)
        }
    }

    Text {
        id: valueLabel

        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: 48
        horizontalAlignment: Text.AlignRight
        text: rootPrismSlider.valueText
        color: rootPrismSlider.pt.primaryTextColor
        font.pixelSize: rootPrismSlider.pt.bodyPixelSize
    }
}

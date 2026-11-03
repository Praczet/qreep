import QtQuick

// One circle, for the whole life of the panel. `entry` from the scene says
// where it should be; play() animates there from wherever it is now, so an
// interrupted move just turns around.
//
// Laid out at centre size and scaled down, never resized: text and icons do not
// re-layout or re-rasterise on every animation frame.
Item {
    id: rootOrbitNode

    required property QtObject ot
    required property var entry
    // The middle of the screen, in the parent's coordinates.
    required property real originX
    required property real originY
    // Degrees. Applies only while this node is on the ring.
    required property real ringAngle
    property string text: ""
    property string name: ""
    property string iconSource: ""
    // What to type for this node. Shown only when the circle does not say so.
    property string hint: ""
    property bool pinnedKey: false
    property bool selected: false
    property bool dimmed: false
    property bool hasItems: false

    signal clicked

    readonly property string role: entry ? entry.role : "hidden"
    readonly property bool hasIcon: icon.status === Image.Ready
    readonly property bool emphasised: role === "center" || role === "parent"
    property real posX: 0
    property real posY: 0
    property bool onRing: false
    readonly property real ringRadians: onRing ? ringAngle * Math.PI / 180 : 0
    // Where the circle really is: posX/posY turned by the ring's angle.
    readonly property real shownX: posX * Math.cos(ringRadians) - posY * Math.sin(ringRadians)
    readonly property real shownY: posX * Math.sin(ringRadians) + posY * Math.cos(ringRadians)
    // Pointing away from the centre.
    readonly property real distanceOut: Math.sqrt(shownX * shownX + shownY * shownY)
    readonly property real outX: distanceOut > 0 ? shownX / distanceOut : 0
    readonly property real outY: distanceOut > 0 ? shownY / distanceOut : -1

    width: ot.centerSize
    height: ot.centerSize
    x: originX + shownX - width / 2
    y: originY + shownY - height / 2
    scale: 0
    opacity: 0
    visible: opacity > 0.001 && scale > 0.001
    z: role === "center" ? 3 : role === "ring" ? 2 : role === "parent" ? 1 : 0

    onEntryChanged: play()
    Component.onCompleted: play()

    function play() {
        if (!entry)
            return;

        const scaleTo = entry.size / ot.centerSize;

        if (xAnimation.to === entry.x && yAnimation.to === entry.y && scaleAnimation.to === scaleTo && opacityAnimation.to === entry.opacity)
            return;

        const shrinking = scaleTo < scale;
        const growing = entry.role === "ring" && !shrinking;
        const duration = shrinking ? ot.shrinkDuration : growing ? ot.growDuration : ot.moveDuration;

        moves.stop();
        setOnRing(entry.role === "ring");
        pause.duration = entry.delay;
        xAnimation.to = entry.x;
        yAnimation.to = entry.y;
        scaleAnimation.to = scaleTo;
        opacityAnimation.to = entry.opacity;
        xAnimation.duration = duration;
        yAnimation.duration = duration;
        scaleAnimation.duration = duration;
        opacityAnimation.duration = shrinking ? ot.shrinkDuration : ot.selectDuration;
        // The small overshoot on the way out is the "growing" part.
        scaleAnimation.easing.type = growing ? Easing.OutBack : Easing.OutCubic;
        scaleAnimation.easing.overshoot = ot.growOvershoot;
        moves.start();
    }

    // Joining or leaving the ring changes what posX/posY mean. Convert them so
    // the circle stays exactly where it is, and carries on from there.
    function setOnRing(value) {
        if (value === onRing)
            return;

        const radians = value ? ringAngle * Math.PI / 180 : 0;
        const fromX = shownX;
        const fromY = shownY;

        posX = fromX * Math.cos(radians) + fromY * Math.sin(radians);
        posY = fromY * Math.cos(radians) - fromX * Math.sin(radians);
        onRing = value;
    }

    SequentialAnimation {
        id: moves

        PauseAnimation {
            id: pause
        }

        ParallelAnimation {
            NumberAnimation {
                id: xAnimation

                target: rootOrbitNode
                property: "posX"
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: yAnimation

                target: rootOrbitNode
                property: "posY"
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                id: scaleAnimation

                target: rootOrbitNode
                property: "scale"
            }

            NumberAnimation {
                id: opacityAnimation

                target: rootOrbitNode
                property: "opacity"
            }
        }
    }

    Item {
        anchors.fill: parent
        scale: rootOrbitNode.selected ? rootOrbitNode.ot.selectedScale : 1
        opacity: rootOrbitNode.dimmed ? rootOrbitNode.ot.dimmedOpacity : 1

        Behavior on scale {
            NumberAnimation {
                duration: rootOrbitNode.ot.selectDuration
                easing.type: Easing.OutBack
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: rootOrbitNode.ot.selectDuration
            }
        }

        // Says "there is more in here". Behind the fill and on the outer side, so
        // it stays clear of the line to the centre.
        Rectangle {
            readonly property real reach: parent.width / 2 * rootOrbitNode.ot.itemsMarkerOffset

            x: parent.width / 2 - width / 2 + rootOrbitNode.outX * reach
            y: parent.height / 2 - height / 2 + rootOrbitNode.outY * reach
            width: parent.width * rootOrbitNode.ot.itemsMarkerSize
            height: width
            radius: width / 2
            color: rootOrbitNode.ot.selectedColor
            opacity: rootOrbitNode.hasItems && rootOrbitNode.role === "ring" ? rootOrbitNode.ot.itemsMarkerOpacity : 0
            visible: opacity > 0.001

            Behavior on opacity {
                NumberAnimation {
                    duration: rootOrbitNode.ot.selectDuration
                }
            }
        }

        // Behind the fill, so shrinking back simply disappears under the node.
        Rectangle {
            id: selectionRing

            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: rootOrbitNode.ot.selectionRingWidth
            border.color: rootOrbitNode.ot.selectedColor
            scale: 1
            opacity: 0
            visible: opacity > 0.001

            states: State {
                name: "selected"
                when: rootOrbitNode.selected

                PropertyChanges {
                    selectionRing.scale: rootOrbitNode.ot.selectionRingScale
                    selectionRing.opacity: 1
                }
            }

            transitions: [
                Transition {
                    to: "selected"

                    NumberAnimation {
                        property: "scale"
                        duration: rootOrbitNode.ot.selectionRingDuration
                        easing.type: Easing.OutBack
                        easing.overshoot: rootOrbitNode.ot.selectionRingOvershoot
                    }

                    NumberAnimation {
                        property: "opacity"
                        duration: rootOrbitNode.ot.selectDuration
                    }
                },
                Transition {
                    from: "selected"

                    NumberAnimation {
                        properties: "scale,opacity"
                        duration: rootOrbitNode.ot.selectDuration
                        easing.type: Easing.OutCubic
                    }
                }
            ]
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: rootOrbitNode.emphasised ? rootOrbitNode.ot.centerColor : rootOrbitNode.selected ? rootOrbitNode.ot.selectedColor : rootOrbitNode.ot.nodeColor
            border.width: rootOrbitNode.selected || rootOrbitNode.emphasised ? 0 : rootOrbitNode.ot.borderWidth
            border.color: rootOrbitNode.ot.nodeBorderColor

            Behavior on color {
                ColorAnimation {
                    duration: rootOrbitNode.ot.selectDuration
                }
            }
        }

        Image {
            id: icon

            anchors.centerIn: parent
            width: parent.width * rootOrbitNode.ot.iconRatio
            height: width
            source: rootOrbitNode.iconSource
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: rootOrbitNode.hasIcon
        }

        Text {
            anchors.centerIn: parent
            visible: !rootOrbitNode.hasIcon
            text: rootOrbitNode.text
            color: rootOrbitNode.emphasised ? rootOrbitNode.ot.centerTextColor : rootOrbitNode.selected ? rootOrbitNode.ot.selectedTextColor : rootOrbitNode.ot.textColor
            font.pixelSize: rootOrbitNode.height * rootOrbitNode.ot.textRatio
            font.bold: true
        }

        // Counter-scaled so the badge reads the same whatever the ring size is.
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            transformOrigin: Item.BottomRight
            scale: rootOrbitNode.entry && rootOrbitNode.entry.size > 0 ? rootOrbitNode.ot.centerSize / rootOrbitNode.entry.size : 1
            visible: rootOrbitNode.role === "ring" && rootOrbitNode.hint.length > 0 && (rootOrbitNode.hasIcon || rootOrbitNode.pinnedKey)
            width: Math.max(rootOrbitNode.ot.hintSize, hintText.implicitWidth + 8)
            height: rootOrbitNode.ot.hintSize
            radius: height / 2
            color: rootOrbitNode.ot.hintColor

            Text {
                id: hintText

                anchors.centerIn: parent
                text: rootOrbitNode.hint
                color: rootOrbitNode.ot.textColor
                font.pixelSize: rootOrbitNode.ot.hintPixelSize
            }
        }
    }

    // Stays outward as the ring turns, and clears the selection circle whether
    // or not it is showing, so the name does not shift when selected. Sizes in
    // here are counter-scaled, so `unscale` turns screen pixels into local ones.
    Text {
        id: nameLabel

        readonly property real unscale: rootOrbitNode.entry && rootOrbitNode.entry.size > 0 ? rootOrbitNode.ot.centerSize / rootOrbitNode.entry.size : 1
        readonly property real reach: rootOrbitNode.width / 2 * rootOrbitNode.ot.selectedScale * rootOrbitNode.ot.selectionRingScale
            + unscale * (rootOrbitNode.ot.nameGap + Math.abs(rootOrbitNode.outX) * width / 2 + Math.abs(rootOrbitNode.outY) * height / 2)

        x: rootOrbitNode.width / 2 - width / 2 + rootOrbitNode.outX * reach
        y: rootOrbitNode.height / 2 - height / 2 + rootOrbitNode.outY * reach
        scale: unscale
        visible: rootOrbitNode.ot.showNodeNames && rootOrbitNode.role === "ring"
        width: Math.min(implicitWidth, rootOrbitNode.ot.nameMaxWidth)
        elide: Text.ElideRight
        text: rootOrbitNode.name
        color: rootOrbitNode.selected ? rootOrbitNode.ot.selectedColor : rootOrbitNode.ot.textColor
        opacity: rootOrbitNode.dimmed ? rootOrbitNode.ot.dimmedOpacity : 1
        font.pixelSize: rootOrbitNode.ot.namePixelSize
        font.bold: rootOrbitNode.selected
    }

    MouseArea {
        anchors.fill: parent
        enabled: rootOrbitNode.role !== "hidden"
        cursorShape: Qt.PointingHandCursor
        onClicked: rootOrbitNode.clicked()
    }
}

import QtQuick

// The universe: one colour, opened up. A hue ring with a saturation/value
// square inside, H S V A sliders, the colour in every notation, and the
// harmonies it belongs to. Click a harmony swatch to travel there; the
// origin is one click away. The panel owns copy / favourite / add-to-combo,
// which act on `hex`.
Item {
    id: rootPrismUniverse

    required property QtObject pt
    required property QtObject service
    property string iconFont: ""
    // From the panel: every colour box here can be dragged onto the sidebar.
    property var dragGhost: null
    property var dragHost: null

    // Where the journey started, and where it is now.
    property string origin: "#000000"
    property real h: 0
    property real s: 0
    property real v: 0
    property real a: 1
    readonly property string hex: service.hsvToHex(h, s, v, a)
    readonly property var harmonies: service.harmonies(h, s, v, a)

    signal saveHarmony(var colors, string label)
    signal copyRequested(string text)

    function open(fromHex) {
        origin = fromHex;
        setHex(fromHex);
    }

    function setHex(value) {
        const hsv = service.hexToHsv(value);
        // Greys have no hue of their own: keep the current one.
        if (hsv.s > 0)
            h = hsv.h;
        s = hsv.s;
        v = hsv.v;
        a = hsv.a;
    }

    function nudge(dh, ds, dv) {
        h = ((h + dh) % 360 + 360) % 360;
        s = Math.max(0, Math.min(1, s + ds));
        v = Math.max(0, Math.min(1, v + dv));
    }

    readonly property real wheelSize: Math.min(height * 0.55, width * 0.36)

    // --- wheel -------------------------------------------------------------------
    Item {
        id: wheel

        anchors {
            left: parent.left
            top: parent.top
            leftMargin: 8
        }
        width: rootPrismUniverse.wheelSize
        height: width

        readonly property real ring: width * 0.11
        readonly property real inner: width / 2 - ring

        // 360 one-degree slices: exact hue placement, no gradient guesswork.
        // Hue grows counter-clockwise from 3 o'clock.
        Canvas {
            id: ringCanvas

            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d");
                const c = width / 2;

                ctx.reset();
                for (let deg = 0; deg < 360; deg++) {
                    ctx.beginPath();
                    ctx.strokeStyle = rootPrismUniverse.service.display(rootPrismUniverse.service.hsvToHex(deg, 1, 1, 1));
                    ctx.lineWidth = wheel.ring;
                    ctx.arc(c, c, c - wheel.ring / 2, -(deg + 0.6) * Math.PI / 180, -(deg - 0.6) * Math.PI / 180);
                    ctx.stroke();
                }
            }
        }

        // Hue handle on the ring.
        Rectangle {
            readonly property real angle: -rootPrismUniverse.h * Math.PI / 180
            readonly property real orbit: wheel.width / 2 - wheel.ring / 2

            x: wheel.width / 2 + Math.cos(angle) * orbit - width / 2
            y: wheel.height / 2 + Math.sin(angle) * orbit - height / 2
            width: wheel.ring * 0.8
            height: width
            radius: width / 2
            color: rootPrismUniverse.service.display(rootPrismUniverse.service.hsvToHex(rootPrismUniverse.h, 1, 1, 1))
            border.width: 3
            border.color: "white"
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true

            function hueAt(mouse) {
                const dx = mouse.x - wheel.width / 2;
                const dy = mouse.y - wheel.height / 2;
                return (-Math.atan2(dy, dx) * 180 / Math.PI + 360) % 360;
            }

            // Presses in the ring set hue; the square has its own MouseArea.
            onPressed: mouse => {
                const dx = mouse.x - wheel.width / 2;
                const dy = mouse.y - wheel.height / 2;
                const distance = Math.sqrt(dx * dx + dy * dy);
                if (distance < wheel.inner || distance > wheel.width / 2) {
                    mouse.accepted = false;
                    return;
                }
                rootPrismUniverse.h = hueAt(mouse);
            }
            onPositionChanged: mouse => rootPrismUniverse.h = hueAt(mouse)
        }

        // Saturation (→) and value (↑) for the current hue.
        Rectangle {
            id: square

            anchors.centerIn: parent
            width: wheel.inner * 1.3
            height: width
            radius: 4
            color: rootPrismUniverse.service.display(rootPrismUniverse.service.hsvToHex(rootPrismUniverse.h, 1, 1, 1))

            Rectangle {
                anchors.fill: parent
                radius: 4
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: "#00ffffff" }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 4
                gradient: Gradient {
                    GradientStop { position: 0; color: "#00000000" }
                    GradientStop { position: 1; color: "black" }
                }
            }

            Rectangle {
                x: rootPrismUniverse.s * square.width - width / 2
                y: (1 - rootPrismUniverse.v) * square.height - height / 2
                width: 16
                height: 16
                radius: 8
                color: "transparent"
                border.width: 3
                border.color: rootPrismUniverse.v > 0.5 && rootPrismUniverse.s < 0.4 ? "black" : "white"
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true

                function set(mouse) {
                    rootPrismUniverse.s = Math.max(0, Math.min(1, mouse.x / square.width));
                    rootPrismUniverse.v = Math.max(0, Math.min(1, 1 - mouse.y / square.height));
                }

                onPressed: mouse => set(mouse)
                onPositionChanged: mouse => set(mouse)
            }
        }
    }

    // --- controls: before/now, sliders, notations --------------------------------
    Column {
        id: controls

        anchors {
            left: wheel.right
            leftMargin: 32
            right: parent.right
            top: parent.top
        }
        spacing: 12

        Row {
            spacing: 14

            // Before → now. Click "before" to go back.
            Rectangle {
                width: 90
                height: 64
                radius: 10
                color: rootPrismUniverse.service.display(rootPrismUniverse.origin)
                border.width: 1
                border.color: rootPrismUniverse.pt.borderColor

                Text {
                    anchors.centerIn: parent
                    text: "↺"
                    color: rootPrismUniverse.service.textOn(rootPrismUniverse.origin, null)
                    font.pixelSize: 20
                }

                MouseArea {
                    id: originMouse

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    drag.target: rootPrismUniverse.dragGhost
                    drag.threshold: 10
                    preventStealing: true
                    onPressed: mouse => rootPrismUniverse.dragHost.dragPress(originMouse, mouse, rootPrismUniverse.origin, rootPrismUniverse.service.nameOf(rootPrismUniverse.origin))
                    onPositionChanged: rootPrismUniverse.dragHost.dragMove(originMouse)
                    onReleased: rootPrismUniverse.dragHost.dragRelease()
                    onClicked: {
                        if (!rootPrismUniverse.dragHost.consumeDragClick())
                            rootPrismUniverse.setHex(rootPrismUniverse.origin);
                    }
                }
            }

            // The colour being made: drag it onto a combo to keep it.
            Rectangle {
                width: 160
                height: 64
                radius: 10
                color: rootPrismUniverse.service.display(rootPrismUniverse.hex)
                border.width: 1
                border.color: rootPrismUniverse.pt.borderColor

                MouseArea {
                    id: nowMouse

                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    drag.target: rootPrismUniverse.dragGhost
                    drag.threshold: 6
                    preventStealing: true
                    onPressed: mouse => rootPrismUniverse.dragHost.dragPress(nowMouse, mouse, rootPrismUniverse.hex, rootPrismUniverse.service.nameOf(rootPrismUniverse.hex))
                    onPositionChanged: rootPrismUniverse.dragHost.dragMove(nowMouse)
                    onReleased: rootPrismUniverse.dragHost.dragRelease()
                    onClicked: rootPrismUniverse.dragHost.consumeDragClick()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: rootPrismUniverse.service.nameOf(rootPrismUniverse.hex)
                    color: rootPrismUniverse.pt.primaryTextColor
                    font.pixelSize: rootPrismUniverse.pt.titlePixelSize
                    font.bold: true
                }

                Text {
                    text: rootPrismUniverse.origin === rootPrismUniverse.hex ? rootPrismUniverse.hex : rootPrismUniverse.origin + "  →  " + rootPrismUniverse.hex
                    color: rootPrismUniverse.pt.secondaryTextColor
                    font.family: rootPrismUniverse.iconFont
                    font.pixelSize: rootPrismUniverse.pt.bodyPixelSize
                }
            }
        }

        PrismSlider {
            width: controls.width
            pt: rootPrismUniverse.pt
            label: "H"
            value: rootPrismUniverse.h / 360
            valueText: Math.round(rootPrismUniverse.h) + "°"
            stops: [0, 60, 120, 180, 240, 300, 360].map(deg => rootPrismUniverse.service.display(rootPrismUniverse.service.hsvToHex(deg, rootPrismUniverse.s, rootPrismUniverse.v, 1)))
            onMoved: value => rootPrismUniverse.h = value * 360
        }

        PrismSlider {
            width: controls.width
            pt: rootPrismUniverse.pt
            label: "S"
            value: rootPrismUniverse.s
            valueText: Math.round(rootPrismUniverse.s * 100) + "%"
            stops: [0, 1, 2, 3, 4, 5, 6].map(i => rootPrismUniverse.service.display(rootPrismUniverse.service.hsvToHex(rootPrismUniverse.h, i / 6, rootPrismUniverse.v, 1)))
            onMoved: value => rootPrismUniverse.s = value
        }

        PrismSlider {
            width: controls.width
            pt: rootPrismUniverse.pt
            label: "V"
            value: rootPrismUniverse.v
            valueText: Math.round(rootPrismUniverse.v * 100) + "%"
            stops: [0, 1, 2, 3, 4, 5, 6].map(i => rootPrismUniverse.service.display(rootPrismUniverse.service.hsvToHex(rootPrismUniverse.h, rootPrismUniverse.s, i / 6, 1)))
            onMoved: value => rootPrismUniverse.v = value
        }

        PrismSlider {
            width: controls.width
            pt: rootPrismUniverse.pt
            label: "A"
            value: rootPrismUniverse.a
            valueText: Math.round(rootPrismUniverse.a * 100) + "%"
            stops: [0, 1, 2, 3, 4, 5, 6].map(i => rootPrismUniverse.service.display(rootPrismUniverse.service.hsvToHex(rootPrismUniverse.h, rootPrismUniverse.s, rootPrismUniverse.v, i / 6)))
            onMoved: value => rootPrismUniverse.a = value
        }

        // Every notation, click to copy.
        Flow {
            width: controls.width
            spacing: 8

            Repeater {
                model: ["hex", "rgb", "hsl", "qt", "hypr"]

                Rectangle {
                    id: notation

                    required property string modelData

                    readonly property string text: rootPrismUniverse.service.formatColor(rootPrismUniverse.hex, modelData)

                    width: notationText.implicitWidth + 18
                    height: 28
                    radius: 8
                    color: notationMouse.containsMouse ? rootPrismUniverse.pt.hoveredColor : rootPrismUniverse.pt.chipColor

                    Text {
                        id: notationText

                        anchors.centerIn: parent
                        text: notation.text
                        color: rootPrismUniverse.pt.primaryTextColor
                        font.family: rootPrismUniverse.iconFont
                        font.pixelSize: rootPrismUniverse.pt.metaPixelSize + 1
                    }

                    MouseArea {
                        id: notationMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPrismUniverse.copyRequested(notation.text)
                    }
                }
            }
        }
    }

    // --- harmonies -------------------------------------------------------------------
    Column {
        anchors {
            left: parent.left
            right: parent.right
            top: wheel.bottom
            topMargin: 24
        }
        spacing: 8

        Repeater {
            model: rootPrismUniverse.harmonies

            Item {
                id: harmonyRow

                required property var modelData

                width: parent.width
                height: 40

                Text {
                    id: harmonyLabel

                    anchors {
                        left: parent.left
                        leftMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    width: 170
                    text: harmonyRow.modelData.label
                    color: rootPrismUniverse.pt.secondaryTextColor
                    font.pixelSize: rootPrismUniverse.pt.bodyPixelSize
                }

                Row {
                    anchors {
                        left: harmonyLabel.right
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 6

                    Repeater {
                        model: harmonyRow.modelData.colors

                        Rectangle {
                            id: harmonySwatch

                            required property string modelData
                            required property int index

                            readonly property bool isCurrent: modelData === rootPrismUniverse.hex

                            width: 72
                            height: 36
                            radius: 8
                            color: rootPrismUniverse.service.display(modelData)
                            border.width: isCurrent || swatchMouse.containsMouse ? 2 : 1
                            border.color: isCurrent ? rootPrismUniverse.pt.selectedBorderColor : swatchMouse.containsMouse ? rootPrismUniverse.pt.primaryTextColor : rootPrismUniverse.pt.borderColor

                            Text {
                                anchors.centerIn: parent
                                text: harmonySwatch.modelData
                                color: rootPrismUniverse.service.textOn(harmonySwatch.modelData, null)
                                font.family: rootPrismUniverse.iconFont
                                font.pixelSize: rootPrismUniverse.pt.metaPixelSize - 1
                            }

                            MouseArea {
                                id: swatchMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                drag.target: rootPrismUniverse.dragGhost
                                drag.threshold: 10
                                preventStealing: true
                                onPressed: mouse => rootPrismUniverse.dragHost.dragPress(swatchMouse, mouse, harmonySwatch.modelData, rootPrismUniverse.service.nameOf(harmonySwatch.modelData))
                                onPositionChanged: rootPrismUniverse.dragHost.dragMove(swatchMouse)
                                onReleased: rootPrismUniverse.dragHost.dragRelease()
                                // Click: travel there. Double click: copy it. Drag: onto a combo.
                                onClicked: {
                                    if (!rootPrismUniverse.dragHost.consumeDragClick())
                                        rootPrismUniverse.setHex(harmonySwatch.modelData);
                                }
                                onDoubleClicked: rootPrismUniverse.copyRequested(harmonySwatch.modelData)
                            }
                        }
                    }
                }

                Rectangle {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: saveText.implicitWidth + 20
                    height: 28
                    radius: 8
                    color: saveMouse.containsMouse ? rootPrismUniverse.pt.hoveredColor : rootPrismUniverse.pt.chipColor

                    Text {
                        id: saveText

                        anchors.centerIn: parent
                        text: "󰐕  save as combo"
                        color: rootPrismUniverse.pt.secondaryTextColor
                        font.family: rootPrismUniverse.iconFont
                        font.pixelSize: rootPrismUniverse.pt.metaPixelSize + 1
                    }

                    MouseArea {
                        id: saveMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootPrismUniverse.saveHarmony(harmonyRow.modelData.colors, harmonyRow.modelData.label)
                    }
                }
            }
        }
    }
}

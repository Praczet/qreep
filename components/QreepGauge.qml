import QtQuick

// Bar-sized arc gauge: a 270 degree track with an open bottom, filled to
// `value` (0..1). Center content goes in as children.
Item {
    id: rootQreepGauge

    property real value: 0
    property real lineWidth: 3
    property color trackColor: "#3b4252"
    property color color: "#88c0d0"
    default property alias content: centerContainer.data

    readonly property real clampedValue: Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0

    implicitWidth: 26
    implicitHeight: 26

    onClampedValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const context = getContext("2d");
            const radius = Math.min(width, height) / 2 - rootQreepGauge.lineWidth / 2;
            const start = Math.PI * 0.75;
            const sweep = Math.PI * 1.5;

            context.reset();
            context.lineWidth = rootQreepGauge.lineWidth;
            context.lineCap = "round";

            context.strokeStyle = rootQreepGauge.trackColor;
            context.beginPath();
            context.arc(width / 2, height / 2, radius, start, start + sweep);
            context.stroke();

            if (rootQreepGauge.clampedValue <= 0)
                return;

            context.strokeStyle = rootQreepGauge.color;
            context.beginPath();
            context.arc(width / 2, height / 2, radius, start, start + sweep * rootQreepGauge.clampedValue);
            context.stroke();
        }
    }

    Item {
        id: centerContainer

        anchors.fill: parent
    }
}

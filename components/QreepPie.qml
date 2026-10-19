import QtQuick

// Bar-sized pie: a filled track disc with a wedge from 12 o'clock, clockwise,
// sized by `value` (0..1). Center content goes in as children.
Item {
    id: rootQreepPie

    property real value: 0
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
            const centerX = width / 2;
            const centerY = height / 2;
            const radius = Math.min(width, height) / 2;
            const start = -Math.PI / 2;

            context.reset();

            context.fillStyle = rootQreepPie.trackColor;
            context.beginPath();
            context.arc(centerX, centerY, radius, 0, Math.PI * 2);
            context.fill();

            if (rootQreepPie.clampedValue <= 0)
                return;

            context.fillStyle = rootQreepPie.color;
            context.beginPath();
            context.moveTo(centerX, centerY);
            context.arc(centerX, centerY, radius, start, start + Math.PI * 2 * rootQreepPie.clampedValue);
            context.closePath();
            context.fill();
        }
    }

    Item {
        id: centerContainer

        anchors.fill: parent
    }
}

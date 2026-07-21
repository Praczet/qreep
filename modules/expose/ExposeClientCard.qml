import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

Rectangle {
    id: rootExposeClientCard

    required property QtObject theme
    required property var client
    property bool selected: false
    property bool compact: false
    property bool entrancePresented: true
    property bool entranceMotionActive: false
    property bool exposeVisible: true
    property int entranceIndex: 0
    property point entranceGatherPoint: Qt.point(0, 0)
    readonly property bool useScreencopy: Boolean(theme.modules.expose.useScreencopy)
    readonly property var previewSource: client.previewSource || null
    readonly property bool hasLivePreview: useScreencopy && previewSource !== null
    readonly property string thumbPath: String(client.thumbPath || "")
    readonly property bool useEntranceMotion: !compact
    property real entrancePushX: 0
    property real entrancePushY: 0
    property real entranceSettleX: 0
    property real entranceSettleY: 0
    property real entrancePushScaleX: 1
    property real entrancePushScaleY: 1
    property real entranceSettleScaleX: 1
    property real entranceSettleScaleY: 1
    property int chromeRevealDelay: 0
    property real chromeOpacity: 1
    readonly property bool chromeVisible: compact || chromeOpacity > 0.02
    readonly property real previewInset: 10
    readonly property real finalPreviewHeight: theme.modules.expose.currentCardPreviewHeight
    readonly property real previewTargetWidth: Math.max(1, width - previewInset * 2)
    readonly property real previewTargetHeight: Math.max(1, compact ? height - previewInset * 2 : finalPreviewHeight)
    readonly property point previewTargetCenter: Qt.point(width / 2, previewInset + previewTargetHeight / 2)
    readonly property color activeCardColor: cardHover.hovered || selected ? theme.modules.expose.cardHoverColor : theme.modules.expose.cardColor
    readonly property color activeBorderColor: selected ? theme.modules.expose.selectedBorderColor : theme.modules.expose.borderColor

    signal selectedRequested(var card)
    signal activated(var client)

    width: compact ? theme.modules.expose.miniCardWidth : theme.modules.expose.currentCardWidth
    height: compact ? theme.modules.expose.miniCardHeight : theme.modules.expose.currentCardHeight
    radius: theme.modules.expose.cardRadius
    color: Qt.rgba(activeCardColor.r, activeCardColor.g, activeCardColor.b, activeCardColor.a * chromeOpacity)
    border.width: chromeVisible ? selected ? theme.modules.expose.selectedBorderWidth : theme.modules.expose.borderWidth : 0
    border.color: Qt.rgba(activeBorderColor.r, activeBorderColor.g, activeBorderColor.b, activeBorderColor.a * chromeOpacity)
    opacity: selected || !compact ? 1 : theme.modules.expose.inactiveCardOpacity
    scale: selected && chromeVisible && !entranceMotionActive ? theme.modules.expose.selectedScale : 1
    clip: true

    transform: [
        Scale {
            id: entranceScale

            origin.x: rootExposeClientCard.previewTargetCenter.x
            origin.y: rootExposeClientCard.previewTargetCenter.y
            xScale: 1
            yScale: 1
        },

        Translate {
            id: entranceTranslate

            x: 0
            y: 0
        }
    ]

    SequentialAnimation {
        id: entranceAnimation

        PauseAnimation {
            duration: rootExposeClientCard.entranceIndex * rootExposeClientCard.theme.modules.expose.cardEntranceStagger
        }

        ParallelAnimation {
            NumberAnimation {
                target: entranceScale
                property: "xScale"
                to: rootExposeClientCard.entrancePushScaleX
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.42
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceScale
                property: "yScale"
                to: rootExposeClientCard.entrancePushScaleY
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.42
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "x"
                to: rootExposeClientCard.entrancePushX
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.42
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "y"
                to: rootExposeClientCard.entrancePushY
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.42
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: entranceScale
                property: "xScale"
                to: rootExposeClientCard.entranceSettleScaleX
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.34
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceScale
                property: "yScale"
                to: rootExposeClientCard.entranceSettleScaleY
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.34
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "x"
                to: rootExposeClientCard.entranceSettleX
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.34
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "y"
                to: rootExposeClientCard.entranceSettleY
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.34
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: entranceScale
                property: "xScale"
                to: 1
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.24
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceScale
                property: "yScale"
                to: 1
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.24
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "x"
                to: 0
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.24
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: entranceTranslate
                property: "y"
                to: 0
                duration: rootExposeClientCard.theme.modules.expose.cardEntranceDuration * 0.24
                easing.type: Easing.OutCubic
            }
        }

        onStopped: {
            if (!rootExposeClientCard.entranceMotionActive)
                rootExposeClientCard.resetFinalEntrance();
        }
    }

    SequentialAnimation {
        id: chromeAnimation

        PauseAnimation {
            duration: rootExposeClientCard.entranceIndex * rootExposeClientCard.theme.modules.expose.cardEntranceStagger + rootExposeClientCard.chromeRevealDelay
        }

        NumberAnimation {
            target: rootExposeClientCard
            property: "chromeOpacity"
            to: 1
            duration: rootExposeClientCard.theme.modules.expose.cardChromeRevealDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: rootExposeClientCard.theme.modules.expose.animationDuration
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: rootExposeClientCard.theme.modules.expose.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on x {
        enabled: rootExposeClientCard.entrancePresented && !rootExposeClientCard.entranceMotionActive

        NumberAnimation {
            duration: rootExposeClientCard.theme.modules.expose.layoutAnimationDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
    }

    Behavior on y {
        enabled: rootExposeClientCard.entrancePresented && !rootExposeClientCard.entranceMotionActive

        NumberAnimation {
            duration: rootExposeClientCard.theme.modules.expose.layoutAnimationDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.25
        }
    }

    Component.onCompleted: {
        if (entranceMotionActive)
            playEntrance();
        else
            resetFinalEntrance();
    }

    onEntranceMotionActiveChanged: {
        if (entranceMotionActive)
            playEntrance();
        else if (!entranceAnimation.running)
            resetFinalEntrance();
    }

    HoverHandler {
        id: cardHover

        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered)
                rootExposeClientCard.selectedRequested(rootExposeClientCard);
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: rootExposeClientCard.activated(rootExposeClientCard.client)
    }

    Rectangle {
        id: preview

        visible: !rootExposeClientCard.compact
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: rootExposeClientCard.previewInset
        }
        height: rootExposeClientCard.previewTargetHeight
        radius: rootExposeClientCard.theme.modules.expose.previewRadius * rootExposeClientCard.chromeOpacity
        color: Qt.rgba(rootExposeClientCard.theme.modules.expose.previewColor.r, rootExposeClientCard.theme.modules.expose.previewColor.g, rootExposeClientCard.theme.modules.expose.previewColor.b, rootExposeClientCard.theme.modules.expose.previewColor.a * rootExposeClientCard.chromeOpacity)
        border.width: rootExposeClientCard.chromeVisible ? 1 : 0
        border.color: Qt.rgba(rootExposeClientCard.theme.modules.expose.borderColor.r, rootExposeClientCard.theme.modules.expose.borderColor.g, rootExposeClientCard.theme.modules.expose.borderColor.b, 0.42 * rootExposeClientCard.chromeOpacity)
        clip: true

        ScreencopyView {
            anchors.fill: parent
            captureSource: rootExposeClientCard.previewSource
            live: rootExposeClientCard.hasLivePreview && rootExposeClientCard.exposeVisible
            paintCursor: false
            constraintSize: Qt.size(width, height)
            visible: rootExposeClientCard.hasLivePreview
        }

        Image {
            anchors.fill: parent
            source: rootExposeClientCard.thumbPath.length > 0 ? "file://" + rootExposeClientCard.thumbPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            visible: !rootExposeClientCard.hasLivePreview && rootExposeClientCard.thumbPath.length > 0
        }

        Text {
            anchors.centerIn: parent
            visible: !rootExposeClientCard.hasLivePreview && rootExposeClientCard.thumbPath.length === 0
            text: rootExposeClientCard.client.floating ? "󰹙" : "󰖲"
            color: rootExposeClientCard.theme.modules.expose.secondaryTextColor
            font.family: rootExposeClientCard.theme.iconFontFamily
            font.pixelSize: 44
            opacity: 0.52
        }
    }

    Row {
        id: metaRow

        opacity: rootExposeClientCard.chromeOpacity
        visible: rootExposeClientCard.compact || rootExposeClientCard.chromeVisible
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: compact ? 10 : 14
        }
        height: compact ? parent.height - 20 : 54
        spacing: compact ? 8 : 12

        IconImage {
            width: compact ? rootExposeClientCard.theme.modules.expose.miniIconSize : rootExposeClientCard.theme.modules.expose.iconSize
            height: width
            anchors.verticalCenter: parent.verticalCenter
            source: Quickshell.iconPath(String(rootExposeClientCard.client.iconName || ""), "application-x-executable-symbolic")
        }

        Column {
            width: parent.width - parent.spacing - (compact ? rootExposeClientCard.theme.modules.expose.miniIconSize : rootExposeClientCard.theme.modules.expose.iconSize)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: rootExposeClientCard.client.title.length > 0 ? rootExposeClientCard.client.title : rootExposeClientCard.client.appLabel
                color: rootExposeClientCard.theme.modules.expose.primaryTextColor
                font.pixelSize: compact ? rootExposeClientCard.theme.modules.expose.subtitlePixelSize : rootExposeClientCard.theme.modules.expose.titlePixelSize
                font.weight: compact ? Font.Normal : Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                visible: !rootExposeClientCard.compact
                width: parent.width
                text: rootExposeClientCard.client.className
                color: rootExposeClientCard.theme.modules.expose.secondaryTextColor
                font.pixelSize: rootExposeClientCard.theme.modules.expose.subtitlePixelSize
                elide: Text.ElideRight
            }
        }
    }

    function windowOffsetFromCurrentCard() {
        const at = rootExposeClientCard.client.at || [0, 0];
        const size = rootExposeClientCard.client.size || [0, 0];
        const windowCenterX = Number(at[0] || 0) + Number(size[0] || 0) / 2;
        const windowCenterY = Number(at[1] || 0) + Number(size[1] || 0) / 2;
        const previewCenter = rootExposeClientCard.mapToGlobal(rootExposeClientCard.previewTargetCenter);

        return Qt.point(windowCenterX - previewCenter.x, windowCenterY - previewCenter.y);
    }

    function resetInitialEntrance() {
        const offset = rootExposeClientCard.useEntranceMotion ? windowOffsetFromCurrentCard() : Qt.point(0, 0);
        const sourceScale = rootExposeClientCard.useEntranceMotion ? windowScaleFromCurrentCard() : Qt.point(1, 1);

        entranceAnimation.stop();
        chromeAnimation.stop();
        chromeOpacity = rootExposeClientCard.useEntranceMotion ? 0 : 1;
        entranceScale.xScale = sourceScale.x;
        entranceScale.yScale = sourceScale.y;
        entranceTranslate.x = offset.x;
        entranceTranslate.y = offset.y;
    }

    function resetFinalEntrance() {
        entranceAnimation.stop();
        chromeAnimation.stop();
        chromeOpacity = 1;
        entranceScale.xScale = 1;
        entranceScale.yScale = 1;
        entranceTranslate.x = 0;
        entranceTranslate.y = 0;
    }

    function playEntrance() {
        const offset = rootExposeClientCard.useEntranceMotion ? windowOffsetFromCurrentCard() : Qt.point(0, 0);
        const sourceScale = rootExposeClientCard.useEntranceMotion ? windowScaleFromCurrentCard() : Qt.point(1, 1);

        resetInitialEntrance();
        entrancePushX = offset.x * rootExposeClientCard.theme.modules.expose.cardEntrancePushOffset;
        entrancePushY = offset.y * rootExposeClientCard.theme.modules.expose.cardEntrancePushOffset;
        entranceSettleX = offset.x * rootExposeClientCard.theme.modules.expose.cardEntranceSettleOffset;
        entranceSettleY = offset.y * rootExposeClientCard.theme.modules.expose.cardEntranceSettleOffset;
        entrancePushScaleX = rootExposeClientCard.theme.modules.expose.cardEntrancePushScale;
        entrancePushScaleY = rootExposeClientCard.theme.modules.expose.cardEntrancePushScale;
        entranceSettleScaleX = rootExposeClientCard.theme.modules.expose.cardEntranceSettleScale;
        entranceSettleScaleY = rootExposeClientCard.theme.modules.expose.cardEntranceSettleScale;
        chromeRevealDelay = chromeRevealDelayForScale(sourceScale);
        entranceAnimation.restart();
        chromeAnimation.restart();
    }

    function windowScaleFromCurrentCard() {
        const size = rootExposeClientCard.client.size || [0, 0];
        const sourceWidth = Math.max(1, Number(size[0] || rootExposeClientCard.width));
        const sourceHeight = Math.max(1, Number(size[1] || rootExposeClientCard.height));

        return Qt.point(sourceWidth / rootExposeClientCard.previewTargetWidth, sourceHeight / rootExposeClientCard.previewTargetHeight);
    }

    function chromeRevealDelayForScale(sourceScale) {
        const source = Math.max(Number(sourceScale.x || 1), Number(sourceScale.y || 1));
        const reveal = Math.max(1, Number(rootExposeClientCard.theme.modules.expose.cardChromeRevealScale || 1.2));
        const push = Number(rootExposeClientCard.theme.modules.expose.cardEntrancePushScale || 1);
        const settle = Number(rootExposeClientCard.theme.modules.expose.cardEntranceSettleScale || 1);
        const duration = Number(rootExposeClientCard.theme.modules.expose.cardEntranceDuration || 0);

        if (source <= reveal)
            return 0;

        if (source !== push && reveal >= Math.min(source, push) && reveal <= Math.max(source, push))
            return duration * 0.42 * ((source - reveal) / (source - push));

        if (push !== settle && reveal >= Math.min(push, settle) && reveal <= Math.max(push, settle))
            return duration * 0.42 + duration * 0.34 * ((push - reveal) / (push - settle));

        return duration * 0.76;
    }
}

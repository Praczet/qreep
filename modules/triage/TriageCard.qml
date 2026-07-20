import QtQuick

Rectangle {
    id: rootTriageCard

    required property QtObject theme
    required property var itemData
    property bool selected: false

    signal clicked
    signal inspectRequested

    width: ListView.view ? ListView.view.width - rootTriageCard.theme.modules.triage.rowGap : 320
    height: rootTriageCard.theme.modules.triage.rowHeight
    radius: rootTriageCard.theme.modules.triage.rowRadius
    color: selected ? rootTriageCard.theme.modules.triage.selectedRowColor : rowHover.hovered ? rootTriageCard.theme.modules.triage.hoveredRowColor : rootTriageCard.theme.modules.triage.sectionColor
    border.width: selected ? 1 : 0
    border.color: rootTriageCard.theme.modules.triage.focusBorderColor

    HoverHandler {
        id: rowHover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: mouse => {
            rootTriageCard.clicked();
            if (mouse.modifiers & Qt.ControlModifier)
                rootTriageCard.inspectRequested();
        }
        onDoubleClicked: rootTriageCard.inspectRequested()
    }

    Text {
        id: packageName

        anchors {
            left: parent.left
            right: versionsVisible() ? oldVersionText.left : parent.right
            top: parent.top
            leftMargin: 10
            rightMargin: 8
            topMargin: 8
        }
        height: 18
        text: rootTriageCard.itemData.package || ""
        color: rootTriageCard.theme.modules.triage.primaryTextColor
        font.pixelSize: rootTriageCard.theme.modules.triage.bodyPixelSize
        font.bold: true
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: oldVersionText

        anchors {
            right: newVersionText.left
            top: parent.top
            rightMargin: 10
            topMargin: 8
        }
        visible: versionsVisible()
        width: 84
        height: 18
        text: oldVersion()
        color: rootTriageCard.theme.modules.triage.secondaryTextColor
        font.pixelSize: rootTriageCard.theme.modules.triage.metaPixelSize
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Text {
        id: newVersionText

        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 10
            topMargin: 8
        }
        visible: versionsVisible()
        width: 94
        height: 18
        text: newVersion()
        color: rootTriageCard.theme.modules.triage.primaryTextColor
        font.pixelSize: rootTriageCard.theme.modules.triage.metaPixelSize
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Text {
        anchors {
            left: parent.left
            right: decisionText.left
            bottom: parent.bottom
            leftMargin: 10
            rightMargin: 8
            bottomMargin: 8
        }
        height: 16
        text: notePreview().length > 0 ? (rootTriageCard.itemData.source || "") + " | " + notePreview() : rootTriageCard.itemData.source || ""
        color: rootTriageCard.theme.modules.triage.secondaryTextColor
        font.pixelSize: rootTriageCard.theme.modules.triage.metaPixelSize
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: decisionText

        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 10
            bottomMargin: 8
        }
        width: 92
        height: 16
        text: latestDecision()
        color: decisionColor()
        font.pixelSize: rootTriageCard.theme.modules.triage.metaPixelSize
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    function versionsVisible() {
        return itemData && itemData.source === "updates" && (oldVersion().length > 0 || newVersion().length > 0);
    }

    function oldVersion() {
        return itemData && itemData.oldVersion ? String(itemData.oldVersion) : "";
    }

    function newVersion() {
        return itemData && itemData.newVersion ? String(itemData.newVersion) : "";
    }

    function latestDecision() {
        if (!itemData || !itemData.latestDecision)
            return "none";

        return itemData.latestDecision.kind || "none";
    }

    function notePreview() {
        if (!itemData || !itemData.latestDecision || !itemData.latestDecision.note)
            return "";

        return String(itemData.latestDecision.note);
    }

    function decisionColor() {
        const decision = latestDecision();
        if (decision === "keep")
            return rootTriageCard.theme.modules.triage.successColor;
        if (decision === "investigate")
            return rootTriageCard.theme.modules.triage.warningColor;
        if (decision === "plan-remove")
            return rootTriageCard.theme.modules.triage.errorColor;
        if (decision === "skip")
            return rootTriageCard.theme.modules.triage.secondaryTextColor;

        return rootTriageCard.theme.modules.triage.secondaryTextColor;
    }
}

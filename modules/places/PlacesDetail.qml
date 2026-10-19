import QtQuick

// Right side: everything about the selected project. Sections only appear
// when they have something to say (no git, no questlog, no README: no card).
Flickable {
    id: rootPlacesDetail

    required property QtObject theme
    required property QtObject service

    readonly property QtObject pt: theme.modules.places
    readonly property var project: service.selected
    readonly property var summary: service.selectedSummary
    readonly property var detail: service.detail
    readonly property var stats: project ? (service.languages[project.id] || null) : null
    readonly property bool hasGit: summary !== null && summary.git
    readonly property int halfWidth: (width - pt.sectionGap) / 2
    // Rows per list: more when the pane is tall, never fewer than minListRows.
    readonly property int listRows: Math.max(pt.minListRows, Math.min(pt.maxListRows, Math.floor(height / 80)))
    // Editor first so a plain Enter still opens the editor.
    readonly property var actions: buildActions()
    property int actionIndex: 0

    readonly property bool isPlace: project !== null && project.kind === "place"
    readonly property var blocks: project ? project.blocks : []
    // Blocks laid out in rows: apps get a full row, the rest pair up.
    readonly property var blockRows: {
        const rows = [];
        let pending = null;

        for (const block of blocks) {
            if (block.type === "apps") {
                if (pending)
                    rows.push([pending]);
                pending = null;
                rows.push([block]);
            } else if (pending) {
                rows.push([pending, block]);
                pending = null;
            } else {
                pending = block;
            }
        }
        if (pending)
            rows.push([pending]);
        return rows;
    }

    // Something in a card was picked (click, or Enter while selected). item is
    // { kind: "file" | "folder" | "app", path | id }; the panel decides what
    // happens: Open with for files and folders, launch for apps.
    signal itemChosen(var item)

    // Keyboard focus inside cards. A project has its four file cards first,
    // then its blocks; a place has only blocks. Alt+N is the Nth card in this
    // order; "" means the project list has the arrows.
    readonly property var cardOrder: project ? (isPlace ? [] : ["uncommitted", "pinned", "recent", "docs"]).concat(blocks.map(block => block.id)) : []
    property string focusedCard: ""
    property int focusedIndex: 0
    readonly property var focusedItems: cardItems(focusedCard)

    function fileItems(paths) {
        return paths.map(path => ({
                    kind: "file",
                    path: path
                }));
    }

    function cardItems(card) {
        if (card === "uncommitted")
            return fileItems(detail.changes.slice(0, listRows).map(change => change.path.replace(/^.* -> /, "")));
        if (card === "pinned")
            return fileItems(service.pinnedFiles());
        if (card === "recent")
            return fileItems(detail.recent.slice(0, listRows).map(file => file.path));
        if (card === "docs")
            return fileItems(detail.docs.slice(0, listRows).map(file => file.path));

        const block = blocks.find(candidate => candidate.id === card);
        return block ? block.items : [];
    }

    // "Alt+3" for the third card, nothing past 9.
    function shortcutFor(card) {
        const number = cardOrder.indexOf(card) + 1;
        return number > 0 && number <= 9 ? "Alt+" + number : "";
    }

    // Alt+number: 1-based position in cardOrder. Empty cards are skipped silently.
    function focusCardNumber(number) {
        const card = cardOrder[number - 1];

        if (card && cardItems(card).length > 0) {
            focusedCard = card;
            focusedIndex = 0;
        }
    }

    // Left/Right: the next card in cardOrder that has items, wrapping.
    function stepCard(step) {
        if (cardOrder.length === 0)
            return;

        const start = Math.max(0, cardOrder.indexOf(focusedCard));

        for (let offset = 1; offset <= cardOrder.length; offset++) {
            const card = cardOrder[(start + step * offset + cardOrder.length * 4) % cardOrder.length];

            if (cardItems(card).length > 0) {
                focusedCard = card;
                focusedIndex = Math.min(focusedIndex, cardItems(card).length - 1);
                return;
            }
        }
    }

    // Tab / Shift+Tab: one ring of stops, the action buttons first, then every
    // file card that has files, then back to the first button.
    function cycleFocus(step) {
        const stops = actions.map((action, index) => ({
                    card: "",
                    index: index
                })).concat(cardOrder.filter(card => cardItems(card).length > 0).map(card => ({
                        card: card,
                        index: 0
                    })));

        if (stops.length === 0)
            return;

        const current = focusedCard.length > 0 ? stops.findIndex(stop => stop.card === focusedCard) : actionIndex;
        const next = stops[(Math.max(0, current) + step + stops.length) % stops.length];

        focusedCard = next.card;
        if (next.card.length > 0)
            focusedIndex = 0;
        else
            actionIndex = next.index;
    }

    function moveFile(step) {
        focusedIndex = Math.max(0, Math.min(focusedItems.length - 1, focusedIndex + step));
    }

    function focusedItem() {
        return focusedItems[focusedIndex] || null;
    }

    function isFileSelected(card, index) {
        return focusedCard === card && focusedIndex === index;
    }

    // Keep the selected row on screen inside the Flickable.
    function ensureVisible(item) {
        const top = item.mapToItem(column, 0, 0).y;
        const bottom = top + item.height;

        // Near the top (the buttons under the header): go all the way up so
        // the project name and description come back too.
        if (top < contentY)
            contentY = top < height / 2 ? 0 : Math.max(0, top - 12);
        else if (bottom > contentY + height)
            contentY = Math.min(contentHeight - height, bottom - height + 12);
    }

    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // A new project starts at the top, with the editor action selected.
    onProjectChanged: {
        contentY = 0;
        actionIndex = 0;
        focusedCard = "";
    }

    function runAction(action) {
        if (!project || !action)
            return;

        if (action.kind === "editor")
            service.openInEditor(project, "", action.editor);
        else if (action.kind === "cockpit")
            service.openCockpit(project);
        else if (action.kind === "folder")
            service.openFolder(project, "");
        else if (action.kind === "terminal")
            service.openTerminal(project);
        else if (action.kind === "link")
            service.openLink(project, action.link);
    }

    function buildActions() {
        if (!project)
            return [];

        // A place has no editor or cockpit: its folder (if any) and links.
        if (isPlace) {
            const placeActions = project.path ? [{
                    kind: "folder",
                    icon: "󰉋",
                    label: "Folder",
                    hint: "^O"
                }, {
                    kind: "terminal",
                    icon: "󰆍",
                    label: "Terminal",
                    hint: "^T"
                }] : [];

            return placeActions.concat(project.links.map(link => ({
                        kind: "link",
                        link: link,
                        icon: "󰌷",
                        label: link.name,
                        hint: ""
                    })));
        }

        const current = editorName();
        const list = [{
                kind: "editor",
                editor: current,
                icon: "󰈮",
                label: current,
                hint: "↵"
            }];

        if (project.cockpit.length > 0)
            list.push({
                kind: "cockpit",
                icon: "󰍹",
                label: "Cockpit",
                hint: "⇧↵"
            });
        list.push({
            kind: "folder",
            icon: "󰉋",
            label: "Folder",
            hint: "^O"
        });
        list.push({
            kind: "terminal",
            icon: "󰆍",
            label: "Terminal",
            hint: "^T"
        });

        const others = service.editorNames().filter(name => name !== current);

        for (let index = 0; index < others.length; index++)
            list.push({
                kind: "editor",
                editor: others[index],
                icon: "󰈮",
                label: others[index],
                hint: index === 0 ? "^E" : ""
            });

        for (const link of project.links)
            list.push({
                kind: "link",
                link: link,
                icon: "󰌷",
                label: link.name,
                hint: ""
            });

        return list;
    }

    Column {
        id: column

        width: rootPlacesDetail.width
        spacing: rootPlacesDetail.pt.sectionGap
        visible: rootPlacesDetail.project !== null

        // --- hero ----------------------------------------------------------
        Item {
            width: parent.width
            height: Math.max(heroIcon.height, heroText.implicitHeight)

            PlacesIcon {
                id: heroIcon

                width: rootPlacesDetail.pt.heroIconSize
                height: width
                source: rootPlacesDetail.service.iconSource(rootPlacesDetail.project)
                glyph: rootPlacesDetail.project ? rootPlacesDetail.project.icon : ""
                name: rootPlacesDetail.project ? rootPlacesDetail.project.name : ""
                color: rootPlacesDetail.pt.accentColor
                fontFamily: rootPlacesDetail.theme.iconFontFamily
            }

            Column {
                id: heroText

                anchors {
                    left: heroIcon.right
                    leftMargin: 16
                    right: parent.right
                }
                spacing: 4

                Text {
                    width: parent.width
                    text: rootPlacesDetail.project ? rootPlacesDetail.project.name : ""
                    color: rootPlacesDetail.pt.primaryTextColor
                    font.pixelSize: rootPlacesDetail.pt.titlePixelSize
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: rootPlacesDetail.project ? rootPlacesDetail.project.displayPath + (rootPlacesDetail.project.group ? "  ·  " + rootPlacesDetail.project.group : "") : ""
                    color: rootPlacesDetail.pt.secondaryTextColor
                    font.family: rootPlacesDetail.pt.monoFontFamily
                    font.pixelSize: rootPlacesDetail.pt.metaPixelSize
                    elide: Text.ElideMiddle
                }

                Text {
                    visible: text.length > 0
                    width: parent.width
                    topPadding: 4
                    text: rootPlacesDetail.service.description()
                    color: rootPlacesDetail.pt.primaryTextColor
                    opacity: 0.86
                    font.pixelSize: rootPlacesDetail.pt.bodyPixelSize
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }

        // --- git line + actions ---------------------------------------------
        Flow {
            visible: !rootPlacesDetail.isPlace
            width: parent.width
            spacing: 8

            Repeater {
                model: rootPlacesDetail.gitChips()

                PlacesChip {
                    required property var modelData

                    pt: rootPlacesDetail.pt
                    text: modelData.text
                    textColor: modelData.color || rootPlacesDetail.pt.primaryTextColor
                    mono: true
                }
            }
        }

        // Action buttons. Tab / Shift+Tab move `actionIndex`, Enter runs it;
        // the panel owns the keys, this owns the list.
        Flow {
            width: parent.width
            spacing: 10

            Repeater {
                model: rootPlacesDetail.actions

                PlacesActionButton {
                    required property var modelData
                    required property int index

                    pt: rootPlacesDetail.pt
                    icon: modelData.icon
                    label: modelData.label
                    hint: modelData.hint
                    selected: rootPlacesDetail.focusedCard.length === 0 && index === rootPlacesDetail.actionIndex
                    iconFontFamily: rootPlacesDetail.theme.iconFontFamily
                    // Tab wrapping from the last file card lands here while the
                    // pane is scrolled down; bring the button back into view.
                    onSelectedChanged: {
                        if (selected)
                            rootPlacesDetail.ensureVisible(this);
                    }
                    onClicked: rootPlacesDetail.runAction(modelData)
                }
            }
        }

        // --- questlog ---------------------------------------------------------
        PlacesQuests {
            visible: rootPlacesDetail.service.questlog !== null || rootPlacesDetail.service.questlogError.length > 0
            width: parent.width
            pt: rootPlacesDetail.pt
            service: rootPlacesDetail.service
        }

        // --- a year of commits ---------------------------------------------------
        PlacesActivity {
            visible: rootPlacesDetail.hasGit
            width: parent.width
            pt: rootPlacesDetail.pt
            service: rootPlacesDetail.service
            times: rootPlacesDetail.detail.activityTimes
        }

        // --- files: changes/recent/docs | pinned/commits ------------------------
        Row {
            width: parent.width
            spacing: rootPlacesDetail.pt.sectionGap

            Column {
                width: rootPlacesDetail.halfWidth
                spacing: rootPlacesDetail.pt.sectionGap

                PlacesSection {
                    visible: rootPlacesDetail.detail.changes.length > 0
                    width: parent.width
                    pt: rootPlacesDetail.pt
                    title: "Uncommitted"
                    shortcut: rootPlacesDetail.shortcutFor("uncommitted")
                    focused: rootPlacesDetail.focusedCard === "uncommitted"
                    subtitle: rootPlacesDetail.detail.changes.length + " file" + (rootPlacesDetail.detail.changes.length === 1 ? "" : "s")

                    Repeater {
                        model: rootPlacesDetail.detail.changes.slice(0, rootPlacesDetail.listRows)

                        PlacesFileRow {
                            required property var modelData
                            required property int index

                            pt: rootPlacesDetail.pt
                            selected: rootPlacesDetail.isFileSelected("uncommitted", index)
                            onSelectedChanged: {
                                if (selected)
                                    rootPlacesDetail.ensureVisible(this);
                            }
                            tag: modelData.status
                            tagColor: rootPlacesDetail.changeColor(modelData.status)
                            path: modelData.path
                            onClicked: rootPlacesDetail.itemChosen({ kind: "file", path: modelData.path.replace(/^.* -> /, "") })
                        }
                    }
                }

                PlacesSection {
                    visible: rootPlacesDetail.detail.recent.length > 0
                    width: parent.width
                    pt: rootPlacesDetail.pt
                    title: "Recently touched"
                    shortcut: rootPlacesDetail.shortcutFor("recent")
                    focused: rootPlacesDetail.focusedCard === "recent"
                    subtitle: "last " + rootPlacesDetail.pt.recentFileDays + " days"

                    Repeater {
                        model: rootPlacesDetail.detail.recent.slice(0, rootPlacesDetail.listRows)

                        PlacesFileRow {
                            required property var modelData
                            required property int index

                            pt: rootPlacesDetail.pt
                            selected: rootPlacesDetail.isFileSelected("recent", index)
                            onSelectedChanged: {
                                if (selected)
                                    rootPlacesDetail.ensureVisible(this);
                            }
                            tag: "•"
                            tagColor: rootPlacesDetail.pt.accentColor
                            path: modelData.path
                            trailing: rootPlacesDetail.service.ago(modelData.time)
                            onClicked: rootPlacesDetail.itemChosen({ kind: "file", path: modelData.path })
                        }
                    }
                }

                // docs/, two levels, newest first. Click opens in the editor.
                PlacesSection {
                    visible: rootPlacesDetail.detail.docs.length > 0
                    width: parent.width
                    pt: rootPlacesDetail.pt
                    title: "Docs"
                    shortcut: rootPlacesDetail.shortcutFor("docs")
                    focused: rootPlacesDetail.focusedCard === "docs"
                    subtitle: rootPlacesDetail.detail.docs.length + (rootPlacesDetail.detail.docs.length >= rootPlacesDetail.pt.docLimit ? "+" : "") + " in docs/"

                    Repeater {
                        model: rootPlacesDetail.detail.docs.slice(0, rootPlacesDetail.listRows)

                        PlacesFileRow {
                            required property var modelData
                            required property int index

                            pt: rootPlacesDetail.pt
                            selected: rootPlacesDetail.isFileSelected("docs", index)
                            onSelectedChanged: {
                                if (selected)
                                    rootPlacesDetail.ensureVisible(this);
                            }
                            tag: "󰈙"
                            tagColor: rootPlacesDetail.pt.accentColor
                            path: modelData.path.replace(/^docs\//, "")
                            trailing: rootPlacesDetail.service.ago(modelData.time)
                            onClicked: rootPlacesDetail.itemChosen({ kind: "file", path: modelData.path })
                        }
                    }
                }
            }

            Column {
                width: rootPlacesDetail.halfWidth
                spacing: rootPlacesDetail.pt.sectionGap

                PlacesSection {
                    id: pinnedSection

                    readonly property var files: rootPlacesDetail.detail ? rootPlacesDetail.service.pinnedFiles() : []

                    visible: files.length > 0
                    width: parent.width
                    pt: rootPlacesDetail.pt
                    title: "Pinned"
                    shortcut: rootPlacesDetail.shortcutFor("pinned")
                    focused: rootPlacesDetail.focusedCard === "pinned"

                    Repeater {
                        model: pinnedSection.files

                        PlacesFileRow {
                            required property var modelData
                            required property int index

                            pt: rootPlacesDetail.pt
                            selected: rootPlacesDetail.isFileSelected("pinned", index)
                            onSelectedChanged: {
                                if (selected)
                                    rootPlacesDetail.ensureVisible(this);
                            }
                            tag: "󰐃"
                            tagColor: rootPlacesDetail.pt.accentColor
                            path: modelData
                            onClicked: rootPlacesDetail.itemChosen({ kind: "file", path: modelData })
                        }
                    }
                }

                PlacesSection {
                    visible: rootPlacesDetail.detail.commits.length > 0
                    width: parent.width
                    pt: rootPlacesDetail.pt
                    title: "Commits"
                    subtitle: rootPlacesDetail.detail.commitCount > 0 ? rootPlacesDetail.service.formatCount(rootPlacesDetail.detail.commitCount) + " total" : ""

                    Repeater {
                        model: rootPlacesDetail.detail.commits.slice(0, rootPlacesDetail.listRows)

                        Item {
                            required property var modelData

                            width: parent.width
                            height: 22

                            Text {
                                id: hashText

                                anchors.verticalCenter: parent.verticalCenter
                                width: 62
                                text: modelData.hash
                                color: rootPlacesDetail.pt.accentColor
                                font.family: rootPlacesDetail.pt.monoFontFamily
                                font.pixelSize: rootPlacesDetail.pt.metaPixelSize
                            }

                            Text {
                                anchors {
                                    left: hashText.right
                                    right: ageText.left
                                    rightMargin: 8
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData.subject
                                color: rootPlacesDetail.pt.primaryTextColor
                                font.pixelSize: rootPlacesDetail.pt.metaPixelSize + 1
                                elide: Text.ElideRight
                            }

                            Text {
                                id: ageText

                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                }
                                text: rootPlacesDetail.service.ago(modelData.time)
                                color: rootPlacesDetail.pt.secondaryTextColor
                                font.family: rootPlacesDetail.pt.monoFontFamily
                                font.pixelSize: rootPlacesDetail.pt.metaPixelSize
                            }
                        }
                    }
                }
            }
        }

        // --- configured blocks: apps get a row, the rest pair up --------------------
        Repeater {
            model: rootPlacesDetail.blockRows

            Row {
                id: blockRow

                required property var modelData

                width: parent.width
                spacing: rootPlacesDetail.pt.sectionGap

                Repeater {
                    model: blockRow.modelData

                    PlacesBlock {
                        required property var modelData

                        width: blockRow.modelData.length === 1 ? blockRow.width : rootPlacesDetail.halfWidth
                        pt: rootPlacesDetail.pt
                        service: rootPlacesDetail.service
                        detailPane: rootPlacesDetail
                        block: modelData
                        iconFontFamily: rootPlacesDetail.theme.iconFontFamily
                        onActivated: item => rootPlacesDetail.itemChosen(item)
                    }
                }
            }
        }

        // --- stats ------------------------------------------------------------
        PlacesStats {
            visible: !rootPlacesDetail.isPlace
            width: parent.width
            pt: rootPlacesDetail.pt
            service: rootPlacesDetail.service
            detail: rootPlacesDetail.detail
            stats: rootPlacesDetail.stats
        }
    }

    function editorName() {
        const config = service.config || {};
        return (project && project.editor) || config.defaultEditor || "nvim";
    }

    function changeColor(status) {
        if (status.indexOf("D") >= 0)
            return pt.errorColor;
        if (status.indexOf("A") >= 0 || status === "??")
            return pt.successColor;
        return pt.warningColor;
    }

    function gitChips() {
        if (!summary)
            return [];
        if (summary.missing)
            return [{
                    text: "folder missing",
                    color: pt.errorColor
                }];
        if (!summary.git)
            return [{
                    text: "not a git repo",
                    color: pt.secondaryTextColor
                }];

        const chips = [{
                text: "⎇ " + summary.branch,
                color: pt.accentColor
            }];

        if (summary.ahead > 0)
            chips.push({
                text: "↑" + summary.ahead,
                color: pt.warningColor
            });
        if (summary.behind > 0)
            chips.push({
                text: "↓" + summary.behind,
                color: pt.warningColor
            });
        chips.push(summary.changed > 0 ? {
            text: "● " + summary.changed + " changed",
            color: pt.warningColor
        } : {
            text: "✓ clean",
            color: pt.successColor
        });
        if (summary.lastCommitSubject)
            chips.push({
                text: service.ago(summary.lastCommitTime) + " ago · " + summary.lastCommitSubject,
                color: pt.secondaryTextColor
            });
        return chips;
    }
}

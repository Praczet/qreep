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
    // Editor first so a plain Enter still opens the editor.
    readonly property var actions: buildActions()
    property int actionIndex: 0

    contentWidth: width
    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    // A new project starts at the top, with the editor action selected.
    onProjectChanged: {
        contentY = 0;
        actionIndex = 0;
    }

    function cycleAction(step) {
        if (actions.length > 0)
            actionIndex = (actionIndex + step + actions.length) % actions.length;
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
                    text: rootPlacesDetail.service.readmeSummary
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
            spacing: 8

            Repeater {
                model: rootPlacesDetail.actions

                PlacesChip {
                    required property var modelData
                    required property int index

                    pt: rootPlacesDetail.pt
                    text: modelData.icon + "  " + modelData.label
                    hint: modelData.hint
                    accent: index === rootPlacesDetail.actionIndex
                    fontFamily: rootPlacesDetail.theme.iconFontFamily
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

        // --- files: changes/recent | pinned/commits -----------------------------
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
                    subtitle: rootPlacesDetail.detail.changes.length + " file" + (rootPlacesDetail.detail.changes.length === 1 ? "" : "s")

                    Repeater {
                        model: rootPlacesDetail.detail.changes.slice(0, 8)

                        PlacesFileRow {
                            required property var modelData

                            pt: rootPlacesDetail.pt
                            tag: modelData.status
                            tagColor: rootPlacesDetail.changeColor(modelData.status)
                            path: modelData.path
                            onClicked: rootPlacesDetail.service.openInEditor(rootPlacesDetail.project, modelData.path.replace(/^.* -> /, ""))
                        }
                    }
                }

                PlacesSection {
                    visible: rootPlacesDetail.detail.recent.length > 0
                    width: parent.width
                    pt: rootPlacesDetail.pt
                    title: "Recently touched"
                    subtitle: "last " + rootPlacesDetail.pt.recentFileDays + " days"

                    Repeater {
                        model: rootPlacesDetail.detail.recent

                        PlacesFileRow {
                            required property var modelData

                            pt: rootPlacesDetail.pt
                            tag: "•"
                            tagColor: rootPlacesDetail.pt.accentColor
                            path: modelData.path
                            trailing: rootPlacesDetail.service.ago(modelData.time)
                            onClicked: rootPlacesDetail.service.openInEditor(rootPlacesDetail.project, modelData.path)
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

                    Repeater {
                        model: pinnedSection.files

                        PlacesFileRow {
                            required property var modelData

                            pt: rootPlacesDetail.pt
                            tag: "󰐃"
                            tagColor: rootPlacesDetail.pt.accentColor
                            path: modelData
                            onClicked: rootPlacesDetail.service.openInEditor(rootPlacesDetail.project, modelData)
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
                        model: rootPlacesDetail.detail.commits

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

        // --- stats ------------------------------------------------------------
        PlacesStats {
            width: parent.width
            pt: rootPlacesDetail.pt
            service: rootPlacesDetail.service
            detail: rootPlacesDetail.detail
            stats: rootPlacesDetail.stats
            hasGit: rootPlacesDetail.hasGit
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

// Run with: QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tools/kip/tst_kip_command.qml
import QtQuick
import QtTest
import "../../modules/kip"

TestCase {
    name: "KipNotesCommand"

    KipNotesCommand {
        id: keep
    }

    function test_plain_text_is_kept_as_a_note() {
        const planned = keep.plan("qsv: process CSV");
        compare(planned.action, "save");
        verify(planned.valid);
        compare(planned.args, ["add", "--", "qsv: process CSV"]);
        compare(planned.tag, "#kip");
        verify(planned.preview.indexOf("- qsv: process CSV #kip") >= 0);
    }

    function test_try_and_idea_choose_their_tag() {
        compare(keep.plan("try qsv").args, ["try", "--", "qsv"]);
        compare(keep.plan("try qsv").tag, "#kip/try");
        compare(keep.plan("IDEA mox reads binds").args, ["idea", "--", "mox reads binds"]);
        compare(keep.plan("idea x").tag, "#kip/idea");
    }

    function test_todo_previews_a_plain_task_without_a_tag() {
        const planned = keep.plan("todo renew the domain");
        compare(planned.args, ["todo", "--", "renew the domain"]);
        verify(planned.preview.indexOf("- TODO renew the domain\n") >= 0);
        verify(planned.preview.indexOf("#kip") < 0);
        verify(keep.plan("todo TODO x").preview.indexOf("- TODO x\n") >= 0);
        verify(!keep.plan("todo").valid);
    }

    function test_add_keeps_a_note_starting_with_a_command_word() {
        const planned = keep.plan("add idea for dinner");
        compare(planned.args, ["add", "--", "idea for dinner"]);
    }

    function test_example_is_literal_with_quotes_and_pipes() {
        const example = 'qsv sqlp a.csv "SELECT id, code FROM a WHERE g=\'x\'" | qsv table';
        const planned = keep.plan("try qsv: columns --example " + example);
        compare(planned.args, ["try", "--example=" + example, "--", "qsv: columns"]);
        compare(planned.text, "qsv: columns");
        compare(planned.example, example);
        verify(planned.preview.indexOf("  example:: " + example) >= 0);
    }

    function test_example_equals_form_and_word_inside_text() {
        compare(keep.plan("a --example=b c").example, "b c");
        compare(keep.plan("about--example words").example, "");
    }

    function test_a_note_starting_with_a_dash_cannot_become_a_flag() {
        const args = keep.plan("-x is a flag").args;
        compare(args[args.length - 2], "--");
        compare(args[args.length - 1], "-x is a flag");
    }

    function test_nothing_to_save_is_invalid_and_explains() {
        verify(!keep.plan("try").valid);
        verify(keep.plan("try").error.length > 0);
        verify(!keep.plan("--example only").valid);
    }

    function test_empty_input_shows_help_without_saving() {
        const planned = keep.plan("");
        compare(planned.action, "help");
        verify(!planned.valid);
        verify(planned.preview.indexOf("/kip try") >= 0);
    }

    function test_list_plans() {
        compare(keep.plan("list").args, ["list", "--json"]);
        compare(keep.plan("list").kinds, ["todo", "note", "try", "idea"]);
        compare(keep.plan("list todo").args, ["list", "--json", "--kind", "todo"]);
        compare(keep.plan("list try").args, ["list", "--json", "--kind", "try"]);
        verify(!keep.plan("list nonsense").valid);
        verify(!keep.plan("list try extra").valid);
    }

    function test_object_property_names_are_not_commands() {
        compare(keep.plan("constructor is a word").args, ["add", "--", "constructor is a word"]);
        compare(keep.plan("toString is a word").args[0], "add");
    }

    readonly property var doc: ({
        schemaVersion: 1,
        format: "kip-items",
        sources: [{ id: "logseq", status: "ok" }],
        items: [
            { kind: "try", title: "qsv", text: "CSV", example: "qsv stats a.csv" },
            { kind: "note", title: "fd", text: "", example: "" },
            { kind: "todo", title: "renew", text: "", example: "" },
            { kind: "shortcut", title: "Super + M", text: "Minimize", example: "" }
        ]
    })

    function test_list_page_shows_only_the_asked_kinds() {
        const page = keep.listMarkdown(doc, ["note", "try", "idea"]);
        verify(page.indexOf("**qsv**: CSV") >= 0);
        verify(page.indexOf("`qsv stats a.csv`") >= 0);
        verify(page.indexOf("**fd**") >= 0);
        verify(page.indexOf("Super + M") < 0);
        verify(page.indexOf("idea") < 0);
    }

    function test_todo_is_its_own_group_at_the_top() {
        const page = keep.listMarkdown(doc, keep.defaultListKinds);
        verify(page.indexOf("## todo · 1") === 0);
        verify(page.indexOf("**renew**") < page.indexOf("## note"));
    }

    function test_list_page_is_honest_about_empty_and_broken() {
        verify(keep.listMarkdown(Object.assign({}, doc, { items: [] }), ["try"]).indexOf("Nothing here yet") >= 0);
        verify(keep.listMarkdown({ schemaVersion: 9 }, ["try"]).indexOf("does not understand") >= 0);
        const broken = Object.assign({}, doc, { sources: [{ id: "logseq", status: "error" }] });
        verify(keep.listMarkdown(broken, ["try"]).indexOf("Could not read: logseq") >= 0);
    }
}

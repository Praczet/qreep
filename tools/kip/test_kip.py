#!/usr/bin/env python3
"""Run with: python3 tools/kip/test_kip.py"""
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

KIP = Path(__file__).with_name("kip")


class KipAddTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.base = Path(temp.name)
        self.graph = self.base / "graph"
        for name in ("journals", "pages", "logseq"):
            (self.graph / name).mkdir(parents=True)

    def run_kip(self, *args, **env):
        return subprocess.run(
            [str(KIP), *args],
            capture_output=True,
            text=True,
            env={**os.environ, "KIP_LOGSEQ_DIR": str(self.graph), **env},
        )

    def journal(self):
        return "".join(path.read_text() for path in (self.graph / "journals").iterdir())

    @unittest.skipUnless(shutil.which("lsq"), "lsq is not installed")
    def test_add_writes_one_tagged_line_through_lsq(self):
        result = self.run_kip("add", "qsv:", "process", "CSV")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.journal(), "- qsv: process CSV #kip\n")
        self.assertIn("qsv: process CSV #kip", result.stdout)

    @unittest.skipUnless(shutil.which("lsq"), "lsq is not installed")
    def test_add_keeps_earlier_notes_and_writes_properties(self):
        self.run_kip("add", "first")
        result = self.run_kip("add", "qsv: process CSV", "--example", "qsv stats --everything a.csv")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.journal(),
            "- first #kip\n"
            "- qsv: process CSV #kip\n"
            "  example:: qsv stats --everything a.csv\n",
        )

    @unittest.skipUnless(shutil.which("lsq"), "lsq is not installed")
    def test_each_command_writes_its_own_tag_through_lsq(self):
        for args in (("plain", "text"), ("try", "qsv"), ("idea", "mox", "shortcuts")):
            self.assertEqual(self.run_kip(*args).returncode, 0)

        self.assertEqual(self.journal(), "- plain text #kip\n- qsv #kip/try\n- mox shortcuts #kip/idea\n")

    def test_plain_text_means_add_however_it_starts(self):
        cases = {
            ("qsv", "--dry-run"): "- qsv #kip\n",
            ("--dry-run", "qsv"): "- qsv #kip\n",
            ("--example", "x y", "qsv", "--dry-run"): "- qsv #kip\n  example:: x y\n",
            ("add", "try this later", "--dry-run"): "- try this later #kip\n",
        }
        for args, expected in cases.items():
            with self.subTest(args):
                self.assertEqual(self.run_kip(*args).stdout, expected)

    def test_kip_tags_are_not_repeated(self):
        cases = {
            ("try", "qsv #kip/try", "--dry-run"): "- qsv #kip/try\n",
            ("idea", "x #kip/idea y", "--dry-run"): "- x #kip/idea y\n",
            ("x #kip/try", "--dry-run"): "- x #kip/try\n",
            ("try", "x #kip", "--dry-run"): "- x #kip #kip/try\n",
        }
        for args, expected in cases.items():
            with self.subTest(args):
                self.assertEqual(self.run_kip(*args).stdout, expected)

    def test_commands_need_text(self):
        for args in ((), ("try",), ("idea",), ("add",)):
            with self.subTest(args):
                result = self.run_kip(*args)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(result.stdout, "")
        self.assertEqual(self.journal(), "")

    def test_removed_flags_are_rejected_not_saved_as_text(self):
        for flag in ("--type", "--try"):
            with self.subTest(flag):
                self.assertEqual(self.run_kip("qsv", flag, "tool").returncode, 2)
        self.assertEqual(self.journal(), "")

    def test_existing_tag_is_not_repeated(self):
        result = self.run_kip("add", "qsv #kip csv", "--dry-run")
        self.assertEqual(result.stdout, "- qsv #kip csv\n")

    def test_similar_tag_still_gets_the_real_tag(self):
        result = self.run_kip("add", "about #kipling", "--dry-run")
        self.assertEqual(result.stdout, "- about #kipling #kip\n")

    def test_leading_bullet_is_not_doubled(self):
        result = self.run_kip("add", "- qsv", "--dry-run")
        self.assertEqual(result.stdout, "- qsv #kip\n")

    def test_dry_run_saves_nothing(self):
        result = self.run_kip("add", "qsv", "--dry-run")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.journal(), "")

    def test_invalid_notes_are_rejected_and_save_nothing(self):
        cases = {
            "empty": ("add", "   "),
            "only a bullet": ("add", "- "),
            "property": ("add", "type:: tool"),
            "multi-line note": ("add", "one\ntwo"),
            "multi-line example": ("add", "qsv", "--example", "one\ntwo"),
            "empty example": ("add", "qsv", "--example", " "),
        }
        for label, args in cases.items():
            with self.subTest(label):
                result = self.run_kip(*args)
                self.assertEqual(result.returncode, 1)
                self.assertTrue(result.stderr.startswith("kip: "), result.stderr)
                self.assertEqual(result.stdout, "")
        self.assertEqual(self.journal(), "")

    def test_missing_lsq_says_nothing_was_saved(self):
        result = self.run_kip("add", "qsv", KIP_LSQ=str(self.base / "missing"))
        self.assertEqual(result.returncode, 1)
        self.assertIn("Nothing was saved", result.stderr)

    def test_lsq_failure_says_nothing_was_saved(self):
        fake = self.base / "fake-lsq"
        fake.write_text("#!/bin/sh\necho 'graph is on holiday' >&2\nexit 3\n")
        fake.chmod(0o755)

        result = self.run_kip("add", "qsv", KIP_LSQ=str(fake))

        self.assertEqual(result.returncode, 1)
        self.assertIn("Nothing was saved", result.stderr)
        self.assertIn("graph is on holiday", result.stderr)
        self.assertEqual(result.stdout, "")


class KipListTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.base = Path(temp.name)
        self.graph = self.base / "graph"
        for name in ("journals", "pages"):
            (self.graph / name).mkdir(parents=True)
        self.env = {
            "KIP_LOGSEQ_DIR": str(self.graph),
            "KIP_ZSH_TIPS": str(self.base / "tips.txt"),
            "KIP_HYPRCTL": str(self.fake_hyprctl("[]")),
        }

    def fake_hyprctl(self, output, status=0):
        path = self.base / "fake-hyprctl"
        (self.base / "binds.json").write_text(output)
        path.write_text(f"#!/bin/sh\ncat '{self.base}/binds.json'\nexit {status}\n")
        path.chmod(0o755)
        return path

    def listing(self, *args):
        result = subprocess.run(
            [str(KIP), "list", "--json", *args],
            capture_output=True,
            text=True,
            env={**os.environ, **self.env},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def source(self, document, source_id):
        return next(source for source in document["sources"] if source["id"] == source_id)

    def test_notes_keep_kind_title_example_and_reference(self):
        (self.graph / "journals" / "2026_11_02.md").write_text(
            "- qsv: process CSV #kip/try\n"
            "  example:: qsv stats file.csv\n"
            "- plain thing #kip\n"
            "- mox shows TODO #kip/idea\n"
            "\t- nested: under a parent #kip\n"
            "- not for kip #kipling\n"
            "- just a journal line\n"
        )

        document = self.listing()

        self.assertEqual(document["schemaVersion"], 1)
        self.assertEqual(document["format"], "kip-items")
        items = document["items"]
        self.assertEqual([item["kind"] for item in items], ["try", "note", "idea", "note"])
        self.assertEqual(items[0]["title"], "qsv")
        self.assertEqual(items[0]["text"], "process CSV")
        self.assertEqual(items[0]["example"], "qsv stats file.csv")
        self.assertEqual(items[0]["source"], {"kind": "logseq", "reference": "journals/2026_11_02.md"})
        self.assertEqual(items[1]["title"], "plain thing")
        self.assertEqual(items[1]["text"], "")

    def test_example_of_the_next_note_is_not_borrowed(self):
        (self.graph / "journals" / "a.md").write_text(
            "- one #kip\n- two #kip\n  example:: for two\n"
        )
        items = self.listing()["items"]
        self.assertEqual([item["example"] for item in items], ["", "for two"])

    def test_tags_inside_code_blocks_are_ignored(self):
        (self.graph / "pages" / "a.md").write_text("- ```bash\n  - echo #kip\n  ```\n- real #kip\n")
        self.assertEqual([item["title"] for item in self.listing()["items"]], ["real"])

    def test_same_note_twice_has_one_stable_id(self):
        (self.graph / "journals" / "a.md").write_text("- qsv: CSV #kip\n")
        (self.graph / "journals" / "b.md").write_text("- QSV: csv #kip/try\n")
        first = self.listing()["items"]
        (self.graph / "journals" / "a.md").unlink()
        second = self.listing()["items"]
        self.assertEqual(len(first), 1)
        self.assertEqual(first[0]["id"], second[0]["id"])

    def test_binds_become_shortcuts_without_mouse_or_switches(self):
        self.env["KIP_HYPRCTL"] = str(self.fake_hyprctl(json.dumps([
            {"modmask": 64, "key": "SPACE", "description": "KIP", "mouse": False},
            {"modmask": 69, "key": "M", "description": "Mox  tip", "mouse": False},
            {"modmask": 64, "key": "mouse:272", "description": "Drag", "mouse": True},
            {"modmask": 0, "key": "switch:Lid Switch", "description": "Lid", "mouse": False},
            {"modmask": 0, "key": "XF86MonBrightnessUp", "description": "Brightness", "mouse": False},
            {"modmask": 64, "key": "xf86audioplay", "description": "Play", "mouse": False},
            {"modmask": 64, "key": "X", "description": "", "mouse": False},
        ])))

        items = self.listing()["items"]

        self.assertEqual([item["title"] for item in items], ["Super + SPACE", "Super + Ctrl + Shift + M"])
        self.assertEqual(items[1]["text"], "Mox tip")
        self.assertEqual(items[1]["kind"], "shortcut")

    def test_zsh_tips_file_is_optional_and_parsed(self):
        document = self.listing()
        self.assertEqual(self.source(document, "zsh")["status"], "missing")

        (self.base / "tips.txt").write_text("# comment|ignored\nCTRL-R|atuin history search\nbroken line\n")
        document = self.listing()

        self.assertEqual(self.source(document, "zsh")["status"], "ok")
        self.assertEqual([(i["kind"], i["title"], i["text"]) for i in document["items"]], [("tip", "CTRL-R", "atuin history search")])

    def test_one_failed_source_does_not_hide_the_others(self):
        (self.graph / "journals" / "a.md").write_text("- real #kip\n")
        self.env["KIP_HYPRCTL"] = str(self.fake_hyprctl("not json"))

        document = self.listing()

        self.assertEqual(self.source(document, "hyprland")["status"], "error")
        self.assertEqual(self.source(document, "logseq")["status"], "ok")
        self.assertEqual(len(document["items"]), 1)

    def test_missing_graph_is_an_error_not_an_empty_list(self):
        self.env["KIP_LOGSEQ_DIR"] = str(self.base / "nope")
        self.assertEqual(self.source(self.listing(), "logseq")["status"], "error")

    def test_kind_filter(self):
        (self.graph / "journals" / "a.md").write_text("- a #kip\n- b #kip/try\n")
        self.assertEqual([i["title"] for i in self.listing("--kind", "try")["items"]], ["b"])


if __name__ == "__main__":
    unittest.main()

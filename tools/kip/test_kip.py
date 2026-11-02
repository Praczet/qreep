#!/usr/bin/env python3
"""Run with: python3 tools/kip/test_kip.py"""
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
        result = self.run_kip("add", "qsv: process CSV", "--type", "tool", "--try", "qsv stats --everything a.csv")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.journal(),
            "- first #kip\n"
            "- qsv: process CSV #kip\n"
            "  type:: tool\n"
            "  try:: qsv stats --everything a.csv\n",
        )

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
            "multi-line example": ("add", "qsv", "--try", "one\ntwo"),
            "empty type": ("add", "qsv", "--type", " "),
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


if __name__ == "__main__":
    unittest.main()

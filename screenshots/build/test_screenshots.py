"""
Smoke tests for the App Store screenshot caption pipeline.

The single most important assertion: every captioned PNG must have the
EXACT pixel dimensions of its raw counterpart. Apple rejects screenshots
that don't match the device-class spec (1290 x 2796 for iPhone 6.7").

Run with:
    python screenshots/build/test_screenshots.py
"""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_screenshots  # noqa: E402

EXPECTED_SIZE = (1290, 2796)
MAX_BYTES_PER_FILE = 8 * 1024 * 1024  # Apple's per-screenshot cap


class ScreenshotPipelineTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls) -> None:
        cls.outputs = build_screenshots.build_all()

    def test_all_ten_outputs_written(self) -> None:
        self.assertEqual(len(self.outputs), 10,
                         "Expect 10 captioned screenshots (slots 1-10)")

    def test_dimensions_preserved(self) -> None:
        """Apple spec: iPhone 6.7" Display screenshots must be exactly
        1290 x 2796. Any other size = rejection."""
        for out in self.outputs:
            with self.subTest(file=out.name):
                with Image.open(out) as im:
                    self.assertEqual(im.size, EXPECTED_SIZE,
                                     f"{out.name}: dimensions changed!")

    def test_dimensions_match_raw_input(self) -> None:
        """Cross-check: each captioned file matches its raw counterpart
        exactly. Catches an accidental resize even if EXPECTED_SIZE
        changes upstream."""
        raw_dir = build_screenshots.RAW_DIR
        for out in self.outputs:
            with self.subTest(file=out.name):
                raw_match = next(raw_dir.glob(out.name), None)
                self.assertIsNotNone(raw_match,
                                     f"No raw match for {out.name}")
                with Image.open(raw_match) as raw, Image.open(out) as cap:
                    self.assertEqual(raw.size, cap.size,
                                     f"{out.name}: raw {raw.size} vs"
                                     f" captioned {cap.size}")

    def test_outputs_are_valid_png(self) -> None:
        for out in self.outputs:
            with self.subTest(file=out.name):
                with Image.open(out) as im:
                    self.assertEqual(im.format, "PNG")
                    im.verify()

    def test_outputs_under_apple_size_cap(self) -> None:
        """Apple rejects screenshots > 8 MB."""
        for out in self.outputs:
            with self.subTest(file=out.name):
                self.assertLess(out.stat().st_size, MAX_BYTES_PER_FILE,
                                f"{out.name}: exceeds Apple's 8 MB cap")

    def test_every_slot_has_a_caption_defined(self) -> None:
        """If a raw file is added, it must have a caption registered in
        CAPTIONS — otherwise the band renders blank."""
        for raw in build_screenshots.RAW_DIR.glob("*.[Pp][Nn][Gg]"):
            with self.subTest(file=raw.name):
                self.assertIsNotNone(
                    build_screenshots.find_caption(raw.name),
                    f"{raw.name}: no caption registered in CAPTIONS")


if __name__ == "__main__":
    unittest.main(verbosity=2)

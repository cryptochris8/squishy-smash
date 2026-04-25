"""
Smoke tests for the Squishy Smash KDP book pipeline.

Run with:
    python -m unittest book.build.test_build

Or directly:
    python book/build/test_build.py

Tests assert that:
  - The interior PDF builds without raising and lands in the expected location
  - The interior has 32 pages at 8.75 x 8.75 in
  - The cover wrap PDF builds and is the expected width (back + spine + front
    + outside bleed) and height
  - All 48 character WebPs referenced by config exist on disk
"""

from __future__ import annotations

import struct
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_cover  # noqa: E402
import build_interior  # noqa: E402
from config import (  # noqa: E402
    COVER_H, COVER_W, INCH, OUT_DIR, PAGE_H, PAGE_W, SPINE_W_IN, TRIM_IN,
    all_characters,
)


def _read_pdf_pages_and_size(pdf_path: Path) -> tuple[int, float, float]:
    """Tiny PDF inspector: counts /Type /Page objects and pulls the first
    /MediaBox to get page size in points. Avoids adding pypdf as a dep just
    for two assertions in a smoke test."""
    data = pdf_path.read_bytes()
    # Page count: count "/Type /Page" not followed by "s" (Pages tree).
    # Cheaper than parsing the trailer; reportlab outputs are predictable.
    page_count = 0
    i = 0
    while True:
        idx = data.find(b"/Type /Page", i)
        if idx < 0:
            break
        # Skip "/Type /Pages" (the root container)
        next_char = data[idx + len(b"/Type /Page"): idx + len(b"/Type /Page") + 1]
        if next_char != b"s":
            page_count += 1
        i = idx + len(b"/Type /Page")

    # First MediaBox: "/MediaBox [llx lly urx ury]"
    mb_idx = data.find(b"/MediaBox")
    assert mb_idx >= 0, "No /MediaBox found in PDF"
    open_br = data.find(b"[", mb_idx)
    close_br = data.find(b"]", open_br)
    nums = data[open_br + 1: close_br].decode("ascii").split()
    llx, lly, urx, ury = (float(n) for n in nums)
    return page_count, urx - llx, ury - lly


class InteriorPDFTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.pdf_path = build_interior.build()

    def test_pdf_was_written(self) -> None:
        self.assertTrue(self.pdf_path.exists())
        self.assertGreater(self.pdf_path.stat().st_size, 10_000,
                           "interior PDF is suspiciously small")

    def test_pdf_has_32_pages(self) -> None:
        pages, _, _ = _read_pdf_pages_and_size(self.pdf_path)
        self.assertEqual(pages, 32,
                         "KDP target is 32 interior pages")

    def test_pdf_page_size_matches_kdp_bleed(self) -> None:
        _, w_pt, h_pt = _read_pdf_pages_and_size(self.pdf_path)
        # 8.75 x 8.75 in (full bleed) = 630 x 630 pt
        self.assertAlmostEqual(w_pt, PAGE_W, places=2)
        self.assertAlmostEqual(h_pt, PAGE_H, places=2)
        self.assertAlmostEqual(w_pt / INCH, 8.75, places=3)


class CoverPDFTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.pdf_path = build_cover.build()

    def test_pdf_was_written(self) -> None:
        self.assertTrue(self.pdf_path.exists())
        self.assertGreater(self.pdf_path.stat().st_size, 10_000)

    def test_cover_is_single_page(self) -> None:
        pages, _, _ = _read_pdf_pages_and_size(self.pdf_path)
        self.assertEqual(pages, 1, "Cover wrap is a single PDF page")

    def test_cover_dimensions(self) -> None:
        _, w_pt, h_pt = _read_pdf_pages_and_size(self.pdf_path)
        # Width: back 8.5 + spine 0.075 + front 8.5 + outside bleed 0.25
        # = 17.325 in = 1247.4 pt
        expected_w = 2 * TRIM_IN + SPINE_W_IN + 2 * (0.125)
        self.assertAlmostEqual(w_pt, expected_w * INCH, places=2)
        self.assertAlmostEqual(w_pt, COVER_W, places=2)
        # Height: 8.5 + 0.25 = 8.75 in = 630 pt
        self.assertAlmostEqual(h_pt, COVER_H, places=2)
        self.assertAlmostEqual(h_pt / INCH, 8.75, places=3)


class CharacterAssetTests(unittest.TestCase):
    """Pin: every Character in config.py has a real WebP on disk. Catches
    rename drift if the asset folder is reorganized."""

    def test_all_48_card_paths_exist(self) -> None:
        missing = [c.name for c in all_characters() if not c.card_path.exists()]
        self.assertEqual(missing, [],
                         f"Missing card art for: {missing}")

    def test_we_have_exactly_48_characters(self) -> None:
        chars = all_characters()
        self.assertEqual(len(chars), 48)
        self.assertEqual([c.num for c in chars], list(range(1, 49)))

    def test_pack_balance(self) -> None:
        chars = all_characters()
        packs: dict[str, int] = {}
        for ch in chars:
            packs[ch.pack] = packs.get(ch.pack, 0) + 1
        self.assertEqual(packs, {
            "Squishy Foods": 16,
            "Goo & Fidgets": 16,
            "Creepy-Cute Creatures": 16,
        })


if __name__ == "__main__":
    unittest.main(verbosity=2)

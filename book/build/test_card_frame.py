"""
Phase-2 visual-system tests.

What's pinned:
  - Every PALETTE entry is a valid 7-char hex code that parses to RGB.
  - PACK_BG_GRADIENT, RARITY_RING, SHADOW, GLOW have entries for every
    expected key (renaming a pack later would break Phase 3 layouts
    silently).
  - `paint_pack_background` produces an image of the requested size and
    actually changes pixel values from the canvas's prior state.
  - `draw_card_frame` produces an output where the rarity ring color is
    detectable — common != mythic at the border.
  - The 3 baked texture PNGs exist on disk after running bake_textures.

Tests are pure-Python (PIL only); no Flutter / ReportLab.
"""

from __future__ import annotations

import re
import sys
import unittest
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))

import bake_textures  # noqa: E402
import card_frame  # noqa: E402
from config import (  # noqa: E402
    GLOW,
    PACK_BG_GRADIENT,
    PACK_TINTS,
    PALETTE,
    RARITY_RING,
    SHADOW,
    TEXTURE,
    by_num,
)


HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")


class TokenIntegrityTests(unittest.TestCase):

    def test_palette_entries_are_valid_hex(self) -> None:
        for key, value in PALETTE.items():
            with self.subTest(token=key):
                self.assertRegex(value, HEX_RE)

    def test_pack_bg_gradient_has_three_packs(self) -> None:
        self.assertEqual(set(PACK_BG_GRADIENT.keys()),
                         {"Squishy Foods", "Goo & Fidgets",
                          "Creepy-Cute Creatures"})
        for pack, (top, bottom) in PACK_BG_GRADIENT.items():
            with self.subTest(pack=pack):
                self.assertRegex(top, HEX_RE)
                self.assertRegex(bottom, HEX_RE)

    def test_rarity_ring_has_four_tiers(self) -> None:
        self.assertEqual(set(RARITY_RING.keys()),
                         {"common", "rare", "epic", "mythic"})
        # Common: no glow, mythic: max stops
        self.assertIsNone(RARITY_RING["common"]["glow"])
        self.assertEqual(RARITY_RING["common"]["stops"], 0)
        self.assertEqual(RARITY_RING["mythic"]["stops"], 3)
        for tier in ("rare", "epic", "mythic"):
            with self.subTest(tier=tier):
                self.assertIsNotNone(RARITY_RING[tier]["glow"])
                self.assertGreater(RARITY_RING[tier]["stops"], 0)

    def test_shadow_and_glow_dicts_are_well_formed(self) -> None:
        for key, spec in SHADOW.items():
            with self.subTest(shadow=key):
                self.assertIn("dx", spec)
                self.assertIn("dy", spec)
                self.assertIn("blur", spec)
                self.assertIn("alpha", spec)
                self.assertGreater(spec["alpha"], 0)
                self.assertLessEqual(spec["alpha"], 1)
        for key, spec in GLOW.items():
            with self.subTest(glow=key):
                self.assertIn("radius", spec)
                self.assertIn("alpha", spec)
                self.assertGreater(spec["radius"], 0)


class TextureBakeTests(unittest.TestCase):
    """Baked textures must exist on disk after running the generator
    (Phase 2 ships them as committed assets so the layout pipeline
    can reference them directly, no on-the-fly generation)."""

    @classmethod
    def setUpClass(cls) -> None:
        bake_textures.bake_all()

    def test_all_three_textures_exist(self) -> None:
        for name, path in TEXTURE.items():
            with self.subTest(texture=name):
                self.assertTrue(path.exists(),
                                f"missing baked texture: {path}")

    def test_textures_are_1024_rgba(self) -> None:
        for name, path in TEXTURE.items():
            with self.subTest(texture=name):
                with Image.open(path) as im:
                    self.assertEqual(im.size, (1024, 1024))
                    self.assertEqual(im.mode, "RGBA")


class PackBackgroundTests(unittest.TestCase):

    def test_paint_pack_background_changes_pixels(self) -> None:
        canvas = Image.new("RGBA", (200, 200), (0, 0, 0, 255))
        before = canvas.getpixel((100, 100))
        card_frame.paint_pack_background(
            canvas, 0, 0, 200, 200, pack="Squishy Foods",
            with_texture=False,
        )
        after = canvas.getpixel((100, 100))
        self.assertNotEqual(before, after,
                            "background paint left center pixel unchanged")

    def test_paint_pack_background_all_three_packs(self) -> None:
        for pack in PACK_BG_GRADIENT:
            with self.subTest(pack=pack):
                canvas = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
                card_frame.paint_pack_background(
                    canvas, 0, 0, 100, 100, pack=pack,
                    with_texture=False,
                )
                # No exception means it composed successfully.

    def test_unknown_pack_raises(self) -> None:
        canvas = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        with self.assertRaises(ValueError):
            card_frame.paint_pack_background(
                canvas, 0, 0, 100, 100, pack="Bogus Pack",
            )


class CardFrameTests(unittest.TestCase):
    """Exercises draw_card_frame across all 4 rarity tiers using a
    real character from each pack."""

    def setUp(self) -> None:
        self.lookup = by_num()
        self.canvas_size = (400, 540)

    def _render(self, num: int) -> Image.Image:
        char = self.lookup[num]
        canvas = Image.new("RGBA", self.canvas_size, (0, 0, 0, 0))
        card_frame.draw_card_frame(
            canvas, char.card_path,
            20, 20, 360, 500,
            rarity=char.rarity,
            pack=char.pack,
        )
        return canvas

    def test_renders_each_rarity_tier(self) -> None:
        # 1=common, 11=rare, 13=epic, 16=mythic — one of each from
        # Squishy Foods.
        for num in (1, 11, 13, 16):
            with self.subTest(num=num, rarity=self.lookup[num].rarity):
                out = self._render(num)
                self.assertEqual(out.size, self.canvas_size)
                # Center of the canvas should have non-zero alpha
                # (card art) after rendering.
                _, _, _, a = out.getpixel(
                    (self.canvas_size[0] // 2, self.canvas_size[1] // 2))
                self.assertGreater(a, 0,
                                   "card center is fully transparent")

    def test_unknown_rarity_raises(self) -> None:
        canvas = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        with self.assertRaises(ValueError):
            card_frame.draw_card_frame(
                canvas, Path("nonexistent.png"),
                0, 0, 100, 100,
                rarity="legendary",  # not a real tier
                pack="Squishy Foods",
            )

    def test_ring_color_differs_between_common_and_mythic(self) -> None:
        """The whole point of the ring system: a 4-year-old should
        see common vs mythic at a glance. Border pixels should
        differ between the two."""
        common = self._render(1)   # Soft Dumpling
        mythic = self._render(16)  # Celestial Dumpling Core
        # Sample the top-edge midpoint where the ring is thickest.
        cx = self.canvas_size[0] // 2
        # Inside the panel rect at y=20, ring sits ~1-4 px down.
        common_px = common.getpixel((cx, 22))
        mythic_px = mythic.getpixel((cx, 22))
        self.assertNotEqual(
            common_px, mythic_px,
            f"ring pixels match: common={common_px} mythic={mythic_px}",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)

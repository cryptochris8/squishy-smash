"""
Shared layout constants + character data for the Squishy Smash KDP book pipeline.

KDP paperback target:
- Trim: 8.5 x 8.5 in
- Bleed: 0.125 in on all four sides -> page PDF is 8.75 x 8.75 in
- Safety: 0.375 in inside trim (text + key art must stay inside)
- Color paper, perfect-bound

Bleed strategy note:
The production brief recommends asymmetric bleed (8.625 x 8.75, no bleed at the
spine edge). KDP accepts that, but it requires alternating page widths inside
a single PDF, which is awkward. We use full-bleed 8.75 x 8.75 instead -- KDP
also accepts this and it lets every page be the same size. Trade-off: art that
touches the inside (spine) edge will be trimmed by ~1/8 in during binding, so
keep important content inside the safety inset on all sides.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[2]
CARDS_DIR = REPO_ROOT / "assets" / "cards" / "final_48"
FONT_PATH = REPO_ROOT / "website" / "public" / "fonts" / "Fredoka.ttf"
BRAND_ICON = REPO_ROOT / "assets" / "branding" / "squishy_smash_icon_bunny_v1.png"
OUT_DIR = Path(__file__).resolve().parent / "out"

# ---------------------------------------------------------------------------
# Page geometry (points; 1 inch = 72 pt)
# ---------------------------------------------------------------------------

INCH = 72.0

TRIM_IN = 8.5
BLEED_IN = 0.125
SAFETY_IN = 0.375

PAGE_W = (TRIM_IN + 2 * BLEED_IN) * INCH  # 8.75 in
PAGE_H = (TRIM_IN + 2 * BLEED_IN) * INCH  # 8.75 in
TRIM_W = TRIM_IN * INCH
TRIM_H = TRIM_IN * INCH
BLEED = BLEED_IN * INCH
SAFETY = SAFETY_IN * INCH  # inset from trim
SAFE_INSET = BLEED + SAFETY  # inset from bleed edge

# Cover wrap: back + spine + front, with bleed on top/bottom/outsides.
SPINE_PER_PAGE_COLOR = 0.002347  # KDP color paper formula (in/page)
INTERIOR_PAGES = 32
SPINE_W_IN = round(INTERIOR_PAGES * SPINE_PER_PAGE_COLOR, 4)  # ~0.075 in
COVER_W = (TRIM_IN + SPINE_W_IN + TRIM_IN + 2 * BLEED_IN) * INCH
COVER_H = PAGE_H

# KDP barcode safe zone on back cover: 2 x 1.2 in, 0.25 in from trim edges.
BARCODE_W = 2.0 * INCH
BARCODE_H = 1.2 * INCH
BARCODE_INSET = 0.25 * INCH

# ---------------------------------------------------------------------------
# Brand palette (matches in-app + website + static legal pages)
# ---------------------------------------------------------------------------

PALETTE = {
    "bg": "#120B17",
    "ink": "#1B1322",
    "pink": "#FF8FB8",
    "cream": "#FFD36E",
    "jelly_blue": "#7FE7FF",
    "lavender": "#C98BFF",
    "lime": "#B6FF5C",
    "white": "#FFFFFF",
    "soft_white": "#FFF6EE",
}

PACK_TINTS = {
    "Squishy Foods": PALETTE["lime"],
    "Goo & Fidgets": PALETTE["jelly_blue"],
    "Creepy-Cute Creatures": PALETTE["lavender"],
}

# ---------------------------------------------------------------------------
# Character data (canonical bios, lightly trimmed for layout fit)
# Source: book/squishy_smash_featured_character_bio_sheet_for_claude.md
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Character:
    num: int
    name: str
    pack: str
    intro: str
    traits: tuple[str, str]
    flavor: str
    rarity: str = "common"  # common | rare | epic | mythic

    @property
    def card_path(self) -> Path:
        # Filename pattern: 001_Soft_Dumpling.webp
        slug = self.name.replace(" ", "_").replace("-", "_")
        return CARDS_DIR / f"{self.num:03d}_{slug}.webp"


def _foods() -> list[Character]:
    return [
        Character(1, "Soft Dumpling", "Squishy Foods",
                  "A cozy little friend who loves gentle bouncing and warm, happy moments.",
                  ("Calm and comforting", "Puffy and playful"),
                  "Wherever Soft Dumpling goes, a soft puff of joy follows."),
        Character(2, "Jelly Bun", "Squishy Foods",
                  "Glossy, wiggly, and always ready to bounce into a sweet adventure.",
                  ("Cheerful and energetic", "Wobbly and fun"),
                  "One happy wobble can turn any day into dessert time."),
        Character(3, "Peach Mochi", "Squishy Foods",
                  "Dreamy, gentle, and full of soft peachy sparkle.",
                  ("Sweet and peaceful", "Soft as a cloud"),
                  "Peach Mochi floats through the world with a blush of gentle magic."),
        Character(4, "Syrup Cube", "Squishy Foods",
                  "Leaves a shiny trail wherever it slides, stretches, and splats.",
                  ("Sticky and silly", "Tiny but bold"),
                  "Even the smallest sweet can make a big splash."),
        Character(5, "Cream Puff", "Squishy Foods",
                  "Light, fluffy, and always bursting with swirly fun.",
                  ("Airy and bright", "Extra bouncy"),
                  "Every pop of Cream Puff feels like a whipped little celebration."),
        Character(6, "Rice Ball Squish", "Squishy Foods",
                  "Simple, squishy, and secretly one of the most satisfying friends around.",
                  ("Cozy and steady", "Soft with a dense bounce"),
                  "Rice Ball Squish proves that quiet little squishies can still shine."),
        Character(7, "Marshmallow Puff", "Squishy Foods",
                  "Stretches, springs, and bounces back with sugary delight.",
                  ("Fluffy and funny", "Extra stretchy"),
                  "One squish and Marshmallow Puff is ready to float right back up."),
        Character(8, "Pudding Pop", "Squishy Foods",
                  "Smooth, shiny, and impossible not to squish again.",
                  ("Silky and cheerful", "Wiggly and sweet"),
                  "Pudding Pop turns every wobble into a golden little giggle."),
        Character(9, "Strawberry Dumpling", "Squishy Foods",
                  "Bright, sweet, and bursting with berry sparkle.",
                  ("Juicy and joyful", "Colorful and lively"),
                  "Strawberry Dumpling bounces in with a rosy burst of fun.",
                  rarity="rare"),
        Character(10, "Rainbow Jelly Bun", "Squishy Foods",
                  "Sends colorful shimmer rippling through every bounce.",
                  ("Colorful and playful", "Sweet and surprising"),
                  "A single wobble from Rainbow Jelly Bun can light up the whole sky.",
                  rarity="rare"),
        Character(11, "Sparkle Mochi", "Squishy Foods",
                  "Glitters with every hop and twinkles with every puff.",
                  ("Shimmery and soft", "Gentle and bright"),
                  "Sparkle Mochi carries a little bit of glittery joy everywhere it goes.",
                  rarity="rare"),
        Character(12, "Golden Syrup Cube", "Squishy Foods",
                  "Shines like sweet treasure in the dessert world.",
                  ("Rich and radiant", "Sticky and glowing"),
                  "Some squishies sparkle like gold, and Golden Syrup Cube is one of them.",
                  rarity="epic"),
        Character(13, "Galaxy Dumpling", "Squishy Foods",
                  "Filled with tiny stars and endless squish-space wonder.",
                  ("Cosmic and curious", "Dreamy and brave"),
                  "When Galaxy Dumpling bounces, the stars seem to bounce too.",
                  rarity="epic"),
        Character(14, "Crystal Mochi", "Squishy Foods",
                  "Glows from the inside out with rare, prismatic light.",
                  ("Clear and magical", "Bright and delicate"),
                  "Crystal Mochi sparkles like a secret treasure made of dessert light.",
                  rarity="epic"),
        Character(15, "Neon Dessert Blob", "Squishy Foods",
                  "Pulses with glowing candy energy before every big splat.",
                  ("Electric and exciting", "Bright and bold"),
                  "Neon Dessert Blob turns sweet treats into a glowing show.",
                  rarity="epic"),
        Character(16, "Celestial Dumpling Core", "Squishy Foods",
                  "A legendary squishy said to hold the softest light in the snack universe.",
                  ("Mythic and radiant", "Powerful and kind"),
                  "Some say the stars learned to glow by watching Celestial Dumpling Core.",
                  rarity="mythic"),
    ]


def _goo() -> list[Character]:
    return [
        Character(17, "Goo Ball", "Goo & Fidgets",
                  "A classic glossy squishy that never bounces the same way twice.",
                  ("Stretchy and silly", "Smooth and shiny"),
                  "Every wobble from Goo Ball is a brand-new surprise."),
        Character(18, "Bubble Blob", "Goo & Fidgets",
                  "Loves popping shiny bubbles with every happy bounce.",
                  ("Round and cheerful", "Bouncy and playful"),
                  "Bubble Blob can turn one little hop into a whole burst of bubbles."),
        Character(19, "Stretch Cube", "Goo & Fidgets",
                  "Pulls, wobbles, and springs back into shape with elastic fun.",
                  ("Flexible and funny", "Snappy and bright"),
                  "No matter how far it stretches, Stretch Cube always bounces back smiling."),
        Character(20, "Soft Stress Orb", "Goo & Fidgets",
                  "A soothing friend made for perfect rhythmic squishes.",
                  ("Calm and steady", "Firm and comforting"),
                  "Soft Stress Orb makes every squeeze feel just right."),
        Character(21, "Jelly Pad", "Goo & Fidgets",
                  "Ripples from edge to edge with glossy gel motion.",
                  ("Smooth and wiggly", "Flat and fun"),
                  "Jelly Pad loves to turn every tap into a wave of wobble."),
        Character(22, "Sticky Pop Ball", "Goo & Fidgets",
                  "Small, clingy, and always ready for another splat.",
                  ("Tiny and lively", "Sticky and bold"),
                  "Sticky Pop Ball proves that little splashes can make big fun."),
        Character(23, "Wobble Drop", "Goo & Fidgets",
                  "Has the perfect glossy rebound and a super wiggly splash.",
                  ("Liquid and lively", "Glossy and fun"),
                  "Wobble Drop makes every bounce feel like a shiny little ripple."),
        Character(24, "Squish Capsule", "Goo & Fidgets",
                  "Rolls, pops, and bounces with smooth toy-like style.",
                  ("Curious and quick", "Tiny and energetic"),
                  "Squish Capsule always seems to be rolling toward its next surprise."),
        Character(25, "Glitter Goo Ball", "Goo & Fidgets",
                  "Flashes with sparkling flecks every time it bursts.",
                  ("Shiny and cheerful", "Stretchy and bright"),
                  "Glitter Goo Ball turns splats into sparkle shows.",
                  rarity="rare"),
        Character(26, "Shockwave Blob", "Goo & Fidgets",
                  "Sends satisfying rings of energy through the goo world.",
                  ("Powerful and playful", "Bouncy and bold"),
                  "When Shockwave Blob pops, the whole world seems to ripple.",
                  rarity="rare"),
        Character(27, "Frost Gel Cube", "Goo & Fidgets",
                  "Cracks into cool frosty splats with every icy bounce.",
                  ("Cool and crisp", "Chilly and bright"),
                  "Frost Gel Cube brings a refreshing wobble wherever it slides.",
                  rarity="rare"),
        Character(28, "Prism Stress Orb", "Goo & Fidgets",
                  "Shines with rainbow bands whenever it is gently pressed.",
                  ("Calm and colorful", "Bright and soothing"),
                  "Prism Stress Orb turns every squeeze into a tiny rainbow.",
                  rarity="rare"),
        Character(29, "Plasma Goo Ball", "Goo & Fidgets",
                  "Crackles with charged goo energy and brilliant electric splashes.",
                  ("Energized and fearless", "Bright and explosive"),
                  "Plasma Goo Ball lights up the goo world with every burst.",
                  rarity="epic"),
        Character(30, "Aurora Stretch Cube", "Goo & Fidgets",
                  "Shimmers with sky-colored ribbons as it twists and bounces.",
                  ("Elegant and elastic", "Glowing and rare"),
                  "Aurora Stretch Cube carries the colors of the sky in every stretch.",
                  rarity="epic"),
        Character(31, "Cosmic Jelly Pad", "Goo & Fidgets",
                  "Wobbles with tiny tides of space and orbiting sparkles.",
                  ("Dreamy and mysterious", "Smooth and magical"),
                  "Cosmic Jelly Pad feels like a little galaxy you can tap.",
                  rarity="epic"),
        Character(32, "Singularity Goo Core", "Goo & Fidgets",
                  "A legendary goo with impossible density and a pull all its own.",
                  ("Mythic and powerful", "Strange and dazzling"),
                  "Legends say even gravity likes to wobble around Singularity Goo Core.",
                  rarity="mythic"),
    ]


def _creatures() -> list[Character]:
    return [
        Character(33, "Blushy Bun Bunny", "Creepy-Cute Creatures",
                  "Sweet, rosy, and always ready to hop into a cuddle-filled adventure.",
                  ("Gentle and happy", "Hoppy and warm"),
                  "Tiny paws and rosy cheeks make Blushy Bun Bunny impossible not to love."),
        Character(34, "Squish Bat", "Creepy-Cute Creatures",
                  "Flutters through the sky with soft spooky-cute charm.",
                  ("Flappy and funny", "Light and lively"),
                  "Squish Bat is more cuddly than creepy and more silly than spooky."),
        Character(35, "Puff Ghost", "Creepy-Cute Creatures",
                  "Floats in on a swirl of mist and the cutest little cloud.",
                  ("Glowy and sweet", "Soft and floaty"),
                  "Puff Ghost can make even moonlight feel extra cozy."),
        Character(36, "Wobble Kitty", "Creepy-Cute Creatures",
                  "Wobbles first, thinks later, and charms everyone along the way.",
                  ("Curious and silly", "Round and playful"),
                  "Every little wobble from Wobble Kitty brings a spark of fun."),
        Character(37, "Tiny Blob Monster", "Creepy-Cute Creatures",
                  "Small, but packed with mischief and bounce.",
                  ("Trouble-making and cute", "Fast and funny"),
                  "Tiny Blob Monster loves turning tiny splats into giant laughs."),
        Character(38, "Soft Fang Critter", "Creepy-Cute Creatures",
                  "Tiny spooky fangs, but its squish is pure comfort.",
                  ("Brave and bouncy", "Cute and cozy"),
                  "Soft Fang Critter looks spooky for fun, not for fright."),
        Character(39, "Sleepy Slime Pet", "Creepy-Cute Creatures",
                  "Always drowsy, always adorable, always ready for a dreamy bounce.",
                  ("Sleepy and soft", "Gooey and calm"),
                  "Sleepy Slime Pet turns bedtime into squish time."),
        Character(40, "Round Eared Creature", "Creepy-Cute Creatures",
                  "Perks up its ears right before the perfect pop.",
                  ("Curious and bright", "Soft and springy"),
                  "Its round ears seem to hear every tiny sparkle in the air."),
        Character(41, "Star Eyed Bunny", "Creepy-Cute Creatures",
                  "Hops through the night with tiny wishes glowing in its eyes.",
                  ("Dreamy and magical", "Bright and hopeful"),
                  "Every landing from Star-Eyed Bunny feels like a wish come true.",
                  rarity="rare"),
        Character(42, "Moon Bat Blob", "Creepy-Cute Creatures",
                  "Glides on pale moonlight with soft nighttime sparkle.",
                  ("Gentle and mysterious", "Floaty and cool"),
                  "Moon Bat Blob loves the quiet glow of the night sky.",
                  rarity="rare"),
        Character(43, "Glow Ghost Puff", "Creepy-Cute Creatures",
                  "Shines brighter with every happy bounce.",
                  ("Radiant and sweet", "Glowy and light"),
                  "Glow Ghost Puff can brighten even the sleepiest corner of the world.",
                  rarity="rare"),
        Character(44, "Candy Fang Creature", "Creepy-Cute Creatures",
                  "Sugary chaos wrapped in a grin and tiny fangs.",
                  ("Mischievous and bright", "Sweet and wild"),
                  "Candy Fang Creature always brings a surprise -- and usually a sprinkle or two.",
                  rarity="rare"),
        Character(45, "Dream Eater Squish", "Creepy-Cute Creatures",
                  "Floats through sleepy sparkles and leaves perfect pops behind.",
                  ("Mythic and dreamy", "Soft and magical"),
                  "Dream Eater Squish turns bedtime dreams into glowing adventures.",
                  rarity="epic"),
        Character(46, "Arcane Wobble Kitty", "Creepy-Cute Creatures",
                  "Spins through the air with glowing runes and magical pawprints.",
                  ("Mystical and playful", "Elegant and bright"),
                  "Wherever Arcane Wobble Kitty wobbles, a little magic follows.",
                  rarity="epic"),
        Character(47, "Phantom Jelly Beast", "Creepy-Cute Creatures",
                  "Part creature, part jelly, all glowing mystery.",
                  ("Strange and spectacular", "Bold and magical"),
                  "Phantom Jelly Beast rushes through the shadows with a shining splash.",
                  rarity="epic"),
        Character(48, "Mythic Plush Familiar", "Creepy-Cute Creatures",
                  "A legendary guardian said to watch over every lost squishy.",
                  ("Protective and kind", "Mythic and radiant"),
                  "When hope feels far away, Mythic Plush Familiar is never far behind.",
                  rarity="mythic"),
    ]


def all_characters() -> list[Character]:
    return _foods() + _goo() + _creatures()


def by_num() -> dict[int, Character]:
    return {c.num: c for c in all_characters()}

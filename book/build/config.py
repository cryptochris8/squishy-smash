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
BRAND_ICON = REPO_ROOT / "branding" / "icon" / "squishy_smash_icon_bunny_v1.png"
OUT_DIR = Path(__file__).resolve().parent / "out"

# ---------------------------------------------------------------------------
# Phase-3 typography stack
# ---------------------------------------------------------------------------
# Three deliberate typographic roles per the elevation plan:
#   * display — wordmarks, character names, section titles. Fredoka.
#   * body    — narrator letter, bios, body prose. EB Garamond
#               (humanist serif, "this is a real book" lever).
#   * accent  — Squishkeeper italic flourishes, mythic flavor pulls,
#               hand-feel callouts. Caveat Brush (script).
#
# Variable fonts deliver multiple weights from a single file via
# their wght axis. Pillow's ImageFont.truetype reads them fine; the
# weight is selected via font_variant() at draw time.

BOOK_FONT_DIR = REPO_ROOT / "book" / "assets" / "fonts"
FONTS = {
    "display":          FONT_PATH,
    "body":             BOOK_FONT_DIR / "EBGaramond-Variable.ttf",
    "body_italic":      BOOK_FONT_DIR / "EBGaramond-Italic-Variable.ttf",
    "accent":           BOOK_FONT_DIR / "CaveatBrush-Regular.ttf",
}

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
    # Phase-1 base palette (matches in-app + website + screenshot pipe).
    "bg": "#120B17",
    "ink": "#1B1322",
    "pink": "#FF8FB8",
    "cream": "#FFD36E",
    "jelly_blue": "#7FE7FF",
    "lavender": "#C98BFF",
    "lime": "#B6FF5C",
    "white": "#FFFFFF",
    "soft_white": "#FFF6EE",

    # Phase-2 visual-system extensions (per book/ELEVATION_PLAN.md).
    # See ELEVATION_PLAN §"Visual system extension" for the role of
    # each token. Added here rather than scattered through layout
    # code so a future palette tweak is a one-file change.
    "deep_plum":    "#0A0610",   # darker than `bg` — vignette / spine
    "velvet":       "#2A1838",   # premium-page base under mythic frames
    "parchment":    "#FFF4DD",   # cream variant for body-type backgrounds
    "rose_dust":    "#F2B0CC",   # soft pink decorative rules
    "gold":         "#E8B860",   # mythic foil edge
    "gold_hi":      "#FFE8A6",   # mythic highlight glow
    "shadow_warm":  "#3A1A2E",   # warm shadow under foods/creatures cards
    "shadow_cool":  "#0F2536",   # cool shadow under goo cards
}

PACK_TINTS = {
    "Squishy Foods": PALETTE["lime"],
    "Goo & Fidgets": PALETTE["jelly_blue"],
    "Creepy-Cute Creatures": PALETTE["lavender"],
}

# (top, bottom) hex pairs for the per-pack background gradient.
# Phase 3 will use these to render the pack-portal + scene spreads
# (T5/T6 templates) so each pack reads as its own visual world.
PACK_BG_GRADIENT = {
    "Squishy Foods":          ("#1A0F1E", "#2B1A20"),  # warm plum -> cocoa
    "Goo & Fidgets":          ("#0F1726", "#0A1F2E"),  # midnight teal
    "Creepy-Cute Creatures":  ("#1A0F26", "#221033"),  # haunted lavender
}

# Rarity-ring spec for `draw_card_frame()`. Per ELEVATION_PLAN, the
# common tier is intentionally muted (no glow), rare/epic glow lightly,
# mythic gets a heavy gold halo. `stops` drives the bloom radius — 0
# means "no glow ring," 3 means "wide soft halo."
RARITY_RING = {
    "common":  {"edge": "#3A2D44", "glow": None,            "stops": 0},
    "rare":    {"edge": "#7FE7FF", "glow": "#7FE7FF",        "stops": 1},
    "epic":    {"edge": "#C98BFF", "glow": "#C98BFF",        "stops": 2},
    "mythic":  {"edge": "#E8B860", "glow": "#FFE8A6",        "stops": 3},
}

# Drop-shadow geometry for the card-frame compositor. Values are
# absolute pt at the canvas's native resolution; the renderer scales
# them down for thumbnails. Alpha is 0-1 float to match Pillow's
# putalpha API.
SHADOW = {
    "card_drop":    {"dx": 0,  "dy": 6,  "blur": 14, "alpha": 0.45},
    "card_rim":     {"dx": 0,  "dy": -1, "blur": 2,  "alpha": 0.35},
    "headline":     {"dx": 0,  "dy": 2,  "blur": 0,  "alpha": 0.60},
}

# Glow halo sizing for rare+ rarity rings.
GLOW = {
    "rare_halo":    {"radius": 22, "alpha": 0.30},
    "epic_halo":    {"radius": 30, "alpha": 0.40},
    "mythic_halo":  {"radius": 44, "alpha": 0.55},
}

# Filename map for the Phase-2 baked pack textures. See
# `book/build/bake_textures.py` for the generator.
TEXTURE_DIR = REPO_ROOT / "book" / "assets" / "textures"
TEXTURE = {
    "sprinkles":  TEXTURE_DIR / "sprinkles_foods.png",
    "bubbles":    TEXTURE_DIR / "bubbles_goo.png",
    "moondust":   TEXTURE_DIR / "moondust_creatures.png",
}

# Per-pack texture pointer used by the gradient renderer.
PACK_TEXTURE = {
    "Squishy Foods":          TEXTURE["sprinkles"],
    "Goo & Fidgets":          TEXTURE["bubbles"],
    "Creepy-Cute Creatures":  TEXTURE["moondust"],
}

# Phase-5c per-pack corner ornaments. PNG paths to the three baked
# 280x280 RGBA tiles in book/assets/ornaments/ — Foods sprinkle
# cluster, Goo concentric bubbles, Creatures crescent + stars.
# Page templates stamp these in top-left + bottom-right corners of
# pack-character pages so each pack reads as its own visual world
# at-a-glance. UI agent flagged as the single biggest "Scholastic"
# lever in the audit.
ORNAMENT_DIR = REPO_ROOT / "book" / "assets" / "ornaments"
PACK_ORNAMENT = {
    "Squishy Foods":          ORNAMENT_DIR / "foods_corner.png",
    "Goo & Fidgets":          ORNAMENT_DIR / "goo_corner.png",
    "Creepy-Cute Creatures":  ORNAMENT_DIR / "creatures_corner.png",
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

    # Phase-1 schema additions for the Squishkeeper field-guide voice.
    # Populated only for the 21 Featured characters; gallery cards leave
    # these as None and render as plain thumbnails on page 31.
    location: str | None = None       # e.g. "the Pudding Hills"
    signature_squish: str | None = None  # one-line "what it does" + sound
    pack_mate: str | None = None      # one named friend for the social graph
    keeper_says: str | None = None    # narrator-voice line (italic in layout)

    @property
    def card_path(self) -> Path:
        # Filename pattern: 001_Soft_Dumpling.webp
        slug = self.name.replace(" ", "_").replace("-", "_")
        return CARDS_DIR / f"{self.num:03d}_{slug}.webp"


# Phase 4: every character gets a real entry. The book grew from 32 to
# 46 pages so all 48 squishies appear with the full Squishkeeper
# field-guide schema (no more "27 in another book" framing).
#
# The previous Featured-21 constant is preserved as SOLO_NUMS so
# layout code can ask "does this char get a single-page hero or a
# 2-up T9 spread?" — the 5 most iconic per pack get solo treatment;
# the rest land in T9 duos. The 3 mythics get T10 finale pages
# regardless of this list.
SOLO_NUMS: tuple[int, ...] = (
    # Squishy Foods (5 solo): 4 originals + Rice Ball Squish
    1, 2, 3, 5, 6,
    # Goo & Fidgets (5 solo): 4 originals + Jelly Pad
    17, 18, 19, 20, 21,
    # Creepy-Cute Creatures (5 solo): 4 originals + Wobble Kitty
    33, 34, 35, 39, 36,
)

# Backwards-compat alias for code that still calls the old name —
# featured_characters() now returns all 48 since no one is excluded.
FEATURED_NUMS: tuple[int, ...] = tuple(range(1, 49))


def _foods() -> list[Character]:
    return [
        Character(1, "Soft Dumpling", "Squishy Foods",
                  "A cozy little friend who loves gentle bouncing and warm, happy moments.",
                  ("Calm and comforting", "Puffy and playful"),
                  "Wherever Soft Dumpling goes, a soft puff of joy follows.",
                  location="Dumpling Dell, just past sunrise.",
                  signature_squish="a slow, gentle puff-and-settle. *pmf.*",
                  pack_mate="Jelly Bun",
                  keeper_says="Round. Warm. Soft on top, soft underneath, soft all the way through."),
        Character(2, "Jelly Bun", "Squishy Foods",
                  "Glossy, wiggly, and always ready to bounce into a sweet adventure.",
                  ("Cheerful and energetic", "Wobbly and fun"),
                  "One happy wobble can turn any day into dessert time.",
                  location="the riverbank, near Syrup River.",
                  signature_squish="wobble in, wobble out. *wibble-wobble.*",
                  pack_mate="Soft Dumpling",
                  keeper_says="Have you met Jelly Bun yet? *Wibble.* Now you have."),
        Character(3, "Peach Mochi", "Squishy Foods",
                  "Dreamy, gentle, and full of soft peachy sparkle.",
                  ("Sweet and peaceful", "Soft as a cloud"),
                  "Peach Mochi floats through the world with a blush of gentle magic.",
                  location="the Mochi Meadows, where the grass is soft.",
                  signature_squish="a quiet pink press. *poof.*",
                  pack_mate="Cream Puff",
                  keeper_says="Give Peach Mochi a poke. See that little puff of pink? That is a sigh of joy."),
        Character(4, "Syrup Cube", "Squishy Foods",
                  "Leaves a shiny trail wherever it slides, stretches, and splats.",
                  ("Sticky and silly", "Tiny but bold"),
                  "Even the smallest sweet can make a big splash.",
                  location="the slow bend of Syrup River.",
                  signature_squish="a sticky slide and a tiny splat. *sssssplat.*",
                  pack_mate="Cream Puff",
                  keeper_says="Slide. Splat. Slide again. Syrup Cube doesn't waste a single shimmer."),
        Character(5, "Cream Puff", "Squishy Foods",
                  "Light, fluffy, and always bursting with swirly fun.",
                  ("Airy and bright", "Extra bouncy"),
                  "Every pop of Cream Puff feels like a whipped little celebration.",
                  location="the Sprinkle Cliffs, mid-afternoon.",
                  signature_squish="a swirl, a hop, a happy burst. *POOF!*",
                  pack_mate="Peach Mochi",
                  keeper_says="*POOF!* That was Cream Puff saying hello."),
        Character(6, "Rice Ball Squish", "Squishy Foods",
                  "Simple, squishy, and secretly one of the most satisfying friends around.",
                  ("Cozy and steady", "Soft with a dense bounce"),
                  "Rice Ball Squish proves that quiet little squishies can still shine.",
                  location="the cozy corner of Mochi Meadows.",
                  signature_squish="a dense, satisfying press. *thwump.*",
                  pack_mate="Pudding Pop",
                  keeper_says="Soft on the outside. Soft on the inside. Don't underestimate quiet."),
        Character(7, "Marshmallow Puff", "Squishy Foods",
                  "Stretches, springs, and bounces back with sugary delight.",
                  ("Fluffy and funny", "Extra stretchy"),
                  "One squish and Marshmallow Puff is ready to float right back up.",
                  location="high in the Sprinkle Cliffs.",
                  signature_squish="a stretchy stretch and a fluffy spring. *boing.*",
                  pack_mate="Cream Puff",
                  keeper_says="Press it down. Wait one second. Up it pops, just as fluffy."),
        Character(8, "Pudding Pop", "Squishy Foods",
                  "Smooth, shiny, and impossible not to squish again.",
                  ("Silky and cheerful", "Wiggly and sweet"),
                  "Pudding Pop turns every wobble into a golden little giggle.",
                  location="the warm shore of Syrup River.",
                  signature_squish="a shiny wobble that ends in a giggle. *bloop-hee.*",
                  pack_mate="Rice Ball Squish",
                  keeper_says="One squish leads to two. Two squishes lead to giggles. Pudding Pop never misses."),
        Character(9, "Strawberry Dumpling", "Squishy Foods",
                  "Bright, sweet, and bursting with berry sparkle.",
                  ("Juicy and joyful", "Colorful and lively"),
                  "Strawberry Dumpling bounces in with a rosy burst of fun.",
                  rarity="rare",
                  location="the strawberry patch beyond Dumpling Dell.",
                  signature_squish="a rosy burst with berry-sparkle bounce. *poppp.*",
                  pack_mate="Jelly Bun",
                  keeper_says="A pink burst, a bright bounce, a tiny shower of berry-sparkles."),
        Character(10, "Rainbow Jelly Bun", "Squishy Foods",
                  "Sends colorful shimmer rippling through every bounce.",
                  ("Colorful and playful", "Sweet and surprising"),
                  "A single wobble from Rainbow Jelly Bun can light up the whole sky.",
                  rarity="rare",
                  location="the prism gardens above Mochi Meadows.",
                  signature_squish="a rippling rainbow wobble. *wibble-shimmer.*",
                  pack_mate="Jelly Bun",
                  keeper_says="Watch one wobble. Watch the colors ripple. The whole sky lights up."),
        Character(11, "Sparkle Mochi", "Squishy Foods",
                  "Glitters with every hop and twinkles with every puff.",
                  ("Shimmery and soft", "Gentle and bright"),
                  "Sparkle Mochi carries a little bit of glittery joy everywhere it goes.",
                  rarity="rare",
                  location="dawn at the Sprinkle Cliffs.",
                  signature_squish="a glittery little jump. *tink-tink-tink.*",
                  pack_mate="Peach Mochi",
                  keeper_says="Tink. Tink. Sparkle Mochi leaves glitter where it hops, and the floor twinkles for a second."),
        Character(12, "Golden Syrup Cube", "Squishy Foods",
                  "Shines like sweet treasure in the dessert world.",
                  ("Rich and radiant", "Sticky and glowing"),
                  "Some squishies sparkle like gold, and Golden Syrup Cube is one of them.",
                  rarity="epic",
                  location="the deep gold pools at the heart of Syrup River.",
                  signature_squish="a slow, shining slide. *shhhhine.*",
                  pack_mate="Syrup Cube",
                  keeper_says="Catch the light just right and you'll see why we call it sweet treasure."),
        Character(13, "Galaxy Dumpling", "Squishy Foods",
                  "Filled with tiny stars and endless squish-space wonder.",
                  ("Cosmic and curious", "Dreamy and brave"),
                  "When Galaxy Dumpling bounces, the stars seem to bounce too.",
                  rarity="epic",
                  location="Mochi Meadows, after sundown.",
                  signature_squish="a slow cosmic puff. *whoosh.*",
                  pack_mate="Sparkle Mochi",
                  keeper_says="Have you ever bounced among stars? Galaxy Dumpling has. It does it every single night."),
        Character(14, "Crystal Mochi", "Squishy Foods",
                  "Glows from the inside out with rare, glassy light.",
                  ("Clear and bright", "Bright and delicate"),
                  "Crystal Mochi sparkles like a secret treasure made of dessert light.",
                  rarity="epic",
                  location="high crystal cliffs above the Sprinkle Cliffs.",
                  signature_squish="a clear, glassy press. *tinggggg.*",
                  pack_mate="Sparkle Mochi",
                  keeper_says="Hold one up to the lamp. The whole room turns into a rainbow."),
        Character(15, "Neon Dessert Blob", "Squishy Foods",
                  "Pulses with glowing candy energy before every big splat.",
                  ("Electric and exciting", "Bright and bold"),
                  "Neon Dessert Blob turns sweet treats into a glowing show.",
                  rarity="epic",
                  location="deep in the bright caverns under Dumpling Dell.",
                  signature_squish="a buzzing glow that ends in a neon splat. *zzzap-splat.*",
                  pack_mate="Galaxy Dumpling",
                  keeper_says="Get ready. The pulse is coming. The neon splat is loud and bright."),
        Character(16, "Celestial Dumpling Core", "Squishy Foods",
                  "A legendary squishy said to hold the softest light in the snack universe.",
                  ("Mythic and radiant", "Powerful and kind"),
                  "Some say the stars learned to glow by watching Celestial Dumpling Core.",
                  rarity="mythic",
                  location="above the Sprinkle Cliffs, where the clouds go gold.",
                  signature_squish="a hush, then a glow. *...*",
                  pack_mate="Galaxy Dumpling",
                  keeper_says="Long ago, before the stars knew how to glow, they watched a tiny dumpling shine in the dark. That is how they learned."),
    ]


def _goo() -> list[Character]:
    return [
        Character(17, "Goo Ball", "Goo & Fidgets",
                  "A classic glossy squishy that never bounces the same way twice.",
                  ("Stretchy and silly", "Smooth and shiny"),
                  "Every wobble from Goo Ball is a brand-new surprise.",
                  location="Bubble Bay, where the waves slow down.",
                  signature_squish="a glossy, splatty rebound. *sploink.*",
                  pack_mate="Stretch Cube",
                  keeper_says="*Sploink!* That is the official noise of Goo Ball saying hi."),
        Character(18, "Bubble Blob", "Goo & Fidgets",
                  "Loves popping shiny bubbles with every happy bounce.",
                  ("Round and cheerful", "Bouncy and playful"),
                  "Bubble Blob can turn one little hop into a whole burst of bubbles.",
                  location="Bubble Bay, near the lily pads.",
                  signature_squish="a hop and a pop. *bloop.*",
                  pack_mate="Goo Ball",
                  keeper_says="Watch the bubbles. Every hop pops a new one."),
        Character(19, "Stretch Cube", "Goo & Fidgets",
                  "Pulls, wobbles, and springs back into shape with elastic fun.",
                  ("Flexible and funny", "Snappy and bright"),
                  "No matter how far it stretches, Stretch Cube always bounces back smiling.",
                  location="Stretch Tide, exactly at low tide.",
                  signature_squish="a pull, a twang, a snap. *boing.*",
                  pack_mate="Goo Ball",
                  keeper_says="Stretch. Stretch some more. Snap right back. Stretch some more."),
        Character(20, "Soft Stress Orb", "Goo & Fidgets",
                  "A soothing friend made for slow, steady squishes.",
                  ("Calm and steady", "Firm and comforting"),
                  "Soft Stress Orb makes every squeeze feel just right.",
                  location="the quiet end of Stretch Tide.",
                  signature_squish="a slow, steady press. *one. two. three.*",
                  pack_mate="Stretch Cube",
                  keeper_says="Squeeze. Wait. Squeeze. Soft Stress Orb likes the slow steady kind."),
        Character(21, "Jelly Pad", "Goo & Fidgets",
                  "Ripples from edge to edge with glossy gel motion.",
                  ("Smooth and wiggly", "Flat and fun"),
                  "Jelly Pad loves to turn every tap into a wave of wobble.",
                  location="the wide flats of Stretch Tide.",
                  signature_squish="an edge-to-edge ripple. *wobbbble.*",
                  pack_mate="Stretch Cube",
                  keeper_says="Tap once. Watch the ripple cross the whole pad. Then tap again."),
        Character(22, "Sticky Pop Ball", "Goo & Fidgets",
                  "Small, clingy, and always ready for another splat.",
                  ("Tiny and lively", "Sticky and bold"),
                  "Sticky Pop Ball proves that little splashes can make big fun.",
                  location="the lily-pad coves of Bubble Bay.",
                  signature_squish="a clingy stretch and a sudden pop. *shtuck-pop.*",
                  pack_mate="Bubble Blob",
                  keeper_says="It clings. It pops. It clings again. Don't try to put it down."),
        Character(23, "Wobble Drop", "Goo & Fidgets",
                  "Has the perfect glossy rebound and a super wiggly splash.",
                  ("Liquid and lively", "Glossy and fun"),
                  "Wobble Drop makes every bounce feel like a shiny little ripple.",
                  location="the rain-pools of Plasma Shore.",
                  signature_squish="a glossy drop and a wiggle. *plip-wibble.*",
                  pack_mate="Bubble Blob",
                  keeper_says="A drop, a glossy bounce, a wiggle that won't quite stop."),
        Character(24, "Squish Capsule", "Goo & Fidgets",
                  "Rolls, pops, and bounces with smooth toy-like style.",
                  ("Curious and quick", "Tiny and energetic"),
                  "Squish Capsule always seems to be rolling toward its next surprise.",
                  location="the smooth tide-pools at the edge of Aurora Reef.",
                  signature_squish="a rolling pop. *tok-pop.*",
                  pack_mate="Wobble Drop",
                  keeper_says="Round. Smooth. Always rolling. Always one beat ahead of you."),
        Character(25, "Glitter Goo Ball", "Goo & Fidgets",
                  "Flashes with sparkling flecks every time it bursts.",
                  ("Shiny and cheerful", "Stretchy and bright"),
                  "Glitter Goo Ball turns splats into sparkle shows.",
                  rarity="rare",
                  location="Plasma Shore, just after sunset.",
                  signature_squish="a sparkly slow-motion splat. *shhhh-tink.*",
                  pack_mate="Goo Ball",
                  keeper_says="Have you ever splatted in slow motion? Glitter Goo Ball does. The flecks land last."),
        Character(26, "Shockwave Blob", "Goo & Fidgets",
                  "Sends satisfying rings of energy through the goo world.",
                  ("Powerful and playful", "Bouncy and bold"),
                  "When Shockwave Blob pops, the whole world seems to ripple.",
                  rarity="rare",
                  location="the broad center of Stretch Tide.",
                  signature_squish="a heavy pop with rings going wide. *whoom.*",
                  pack_mate="Bubble Blob",
                  keeper_says="Stand back. The ring goes wide. The ripple keeps going."),
        Character(27, "Frost Gel Cube", "Goo & Fidgets",
                  "Cracks into cool frosty splats with every icy bounce.",
                  ("Cool and crisp", "Chilly and bright"),
                  "Frost Gel Cube brings a refreshing wobble wherever it slides.",
                  rarity="rare",
                  location="the icy edges of Aurora Reef.",
                  signature_squish="a cool, crisp splat. *crrrk.*",
                  pack_mate="Stretch Cube",
                  keeper_says="Touch it. Cool. Touch it again. Even cooler."),
        Character(28, "Prism Stress Orb", "Goo & Fidgets",
                  "Shines with rainbow bands whenever it is gently pressed.",
                  ("Calm and colorful", "Bright and soothing"),
                  "Prism Stress Orb turns every squeeze into a tiny rainbow.",
                  rarity="rare",
                  location="the prism shores of Aurora Reef.",
                  signature_squish="a soft press that paints a rainbow. *hmmm.*",
                  pack_mate="Soft Stress Orb",
                  keeper_says="Squeeze once. A rainbow rolls across. The whole orb shines for a moment."),
        Character(29, "Plasma Goo Ball", "Goo & Fidgets",
                  "Crackles with charged goo energy and brilliant electric splashes.",
                  ("Energized and fearless", "Bright and explosive"),
                  "Plasma Goo Ball lights up the goo world with every burst.",
                  rarity="epic",
                  location="the storm-charged depths of Plasma Shore.",
                  signature_squish="a crackling burst with bright sparks. *krrrk-zap.*",
                  pack_mate="Goo Ball",
                  keeper_says="Listen. The crackle comes first. Then the splash. Then the glow."),
        Character(30, "Aurora Stretch Cube", "Goo & Fidgets",
                  "Shimmers with sky-colored ribbons as it twists and bounces.",
                  ("Elegant and elastic", "Glowing and rare"),
                  "Aurora Stretch Cube carries the colors of the sky in every stretch.",
                  rarity="epic",
                  location="Aurora Reef, when the sky turns green.",
                  signature_squish="a sky-colored stretch. *shimmer-pull.*",
                  pack_mate="Stretch Cube",
                  keeper_says="*Shimmer-pull.* That is the only word for what Aurora Stretch Cube does."),
        Character(31, "Cosmic Jelly Pad", "Goo & Fidgets",
                  "Wobbles with tiny tides of space and orbiting sparkles.",
                  ("Dreamy and mysterious", "Smooth and magical"),
                  "Cosmic Jelly Pad feels like a little galaxy you can tap.",
                  rarity="epic",
                  location="the deep tide pools beneath Aurora Reef.",
                  signature_squish="a slow cosmic ripple. *whoosh-wobble.*",
                  pack_mate="Jelly Pad",
                  keeper_says="Tap it gently. The little stars wobble too. The whole pad is a sky."),
        Character(32, "Singularity Goo Core", "Goo & Fidgets",
                  "A legendary goo with impossible density and a pull all its own.",
                  ("Mythic and powerful", "Strange and dazzling"),
                  "Legends say even gravity likes to wobble around Singularity Goo Core.",
                  rarity="mythic",
                  location="the deepest tide pool past Aurora Reef.",
                  signature_squish="a hush. then a pull. *thummm.*",
                  pack_mate="Aurora Stretch Cube",
                  keeper_says="So heavy the air bends. So strange that even gravity slows down to look."),
    ]


def _creatures() -> list[Character]:
    return [
        Character(33, "Blushy Bun Bunny", "Creepy-Cute Creatures",
                  "Sweet, rosy, and always ready to hop into a cuddle-filled adventure.",
                  ("Gentle and happy", "Hoppy and warm"),
                  "Tiny paws and rosy cheeks make Blushy Bun Bunny impossible not to love.",
                  location="Cuddle Glade, between two tall flowers.",
                  signature_squish="a tiny hop and a softer landing. *thup.*",
                  pack_mate="Puff Ghost",
                  keeper_says="Look closer. Those rosy cheeks get rosier when you say hello."),
        Character(34, "Squish Bat", "Creepy-Cute Creatures",
                  "Flutters through the sky with soft spooky-cute charm.",
                  ("Flappy and funny", "Light and lively"),
                  "Squish Bat is more cuddly than creepy and more silly than spooky.",
                  location="Crescent Cave, late evening.",
                  signature_squish="flap, flap, flop. *fwip.*",
                  pack_mate="Puff Ghost",
                  keeper_says="Have you ever flapped? Just two little wings, very gentle. Now you are a Squish Bat."),
        Character(35, "Puff Ghost", "Creepy-Cute Creatures",
                  "Floats in on a swirl of mist and the cutest little cloud.",
                  ("Glowy and sweet", "Soft and floaty"),
                  "Puff Ghost can make even moonlight feel extra cozy.",
                  location="Whisper Woods, around midnight.",
                  signature_squish="a swirl of mist, then a soft poof. *whisper-poof.*",
                  pack_mate="Blushy Bun Bunny",
                  keeper_says="*Boo-boo-boop!* Puff Ghost is more cloud than spook."),
        Character(36, "Wobble Kitty", "Creepy-Cute Creatures",
                  "Wobbles first, thinks later, and charms everyone along the way.",
                  ("Curious and silly", "Round and playful"),
                  "Every little wobble from Wobble Kitty brings a spark of fun.",
                  location="the spongy moss of Cuddle Glade.",
                  signature_squish="a tilt, a tip, a soft landing. *plonk.*",
                  pack_mate="Sleepy Slime Pet",
                  keeper_says="It wobbles before it stands. It charms before it knows it. Wobble Kitty is mostly tilt."),
        Character(37, "Tiny Blob Monster", "Creepy-Cute Creatures",
                  "Small, but packed with mischief and bounce.",
                  ("Trouble-making and cute", "Fast and funny"),
                  "Tiny Blob Monster loves turning tiny splats into giant laughs.",
                  location="the hidden burrows under Whisper Woods.",
                  signature_squish="a tiny splat and a huge giggle. *blop-haha.*",
                  pack_mate="Soft Fang Critter",
                  keeper_says="It is small. The splat is loud. The laugh is louder."),
        Character(38, "Soft Fang Critter", "Creepy-Cute Creatures",
                  "Tiny spooky fangs, but its squish is pure comfort.",
                  ("Brave and bouncy", "Cute and cozy"),
                  "Soft Fang Critter looks spooky for fun, not for fright.",
                  location="the cozy hollows of Whisper Woods.",
                  signature_squish="a tiny growl and a softer cuddle. *grrrr-thump.*",
                  pack_mate="Tiny Blob Monster",
                  keeper_says="Look at the little fangs. Now look at the cuddle. The fangs are pretend."),
        Character(39, "Sleepy Slime Pet", "Creepy-Cute Creatures",
                  "Always drowsy, always adorable, always ready for a dreamy bounce.",
                  ("Sleepy and soft", "Gooey and calm"),
                  "Sleepy Slime Pet turns bedtime into squish time.",
                  location="Cuddle Glade, every single nap.",
                  signature_squish="a slow, gooey settle. *gloop.*",
                  pack_mate="Blushy Bun Bunny",
                  keeper_says="Sleepy. Sleepy. Slimy. Sleepy. That is the whole story."),
        Character(40, "Round Eared Creature", "Creepy-Cute Creatures",
                  "Perks up its ears right before the perfect pop.",
                  ("Curious and bright", "Soft and springy"),
                  "Its round ears seem to hear every tiny sparkle in the air.",
                  location="the listening tree of Whisper Woods.",
                  signature_squish="a perked-up wiggle and a soft pop. *flick-pop.*",
                  pack_mate="Wobble Kitty",
                  keeper_says="Watch the ears. They hear the sparkle before you do. Then comes the pop."),
        Character(41, "Star-Eyed Bunny", "Creepy-Cute Creatures",
                  "Hops through the night with tiny wishes glowing in its eyes.",
                  ("Dreamy and magical", "Bright and hopeful"),
                  "Every landing from Star-Eyed Bunny feels like a wish come true.",
                  rarity="rare",
                  location="Star Pond, during a full moon.",
                  signature_squish="a leap, a sparkle, a soft landing. *plink.*",
                  pack_mate="Blushy Bun Bunny",
                  keeper_says="Hop. Wish. Hop again. Star-Eyed Bunny carries a tiny wish in each eye."),
        Character(42, "Moon Bat Blob", "Creepy-Cute Creatures",
                  "Glides on pale moonlight with soft nighttime sparkle.",
                  ("Gentle and mysterious", "Floaty and cool"),
                  "Moon Bat Blob loves the quiet glow of the night sky.",
                  rarity="rare",
                  location="the high ledges above Crescent Cave.",
                  signature_squish="a slow glide and a softer landing. *fwoom-soft.*",
                  pack_mate="Squish Bat",
                  keeper_says="Two pale wings. One small glow. Moon Bat Blob always finds the moon."),
        Character(43, "Glow Ghost Puff", "Creepy-Cute Creatures",
                  "Shines brighter with every happy bounce.",
                  ("Radiant and sweet", "Glowy and light"),
                  "Glow Ghost Puff can brighten even the sleepiest corner of the world.",
                  rarity="rare",
                  location="Whisper Woods, where the dark is darkest.",
                  signature_squish="a gentle bloom of light. *hmmm-shine.*",
                  pack_mate="Puff Ghost",
                  keeper_says="Watch the dark corner. Now watch it glow. Glow Ghost Puff just walked in."),
        Character(44, "Candy Fang Creature", "Creepy-Cute Creatures",
                  "Sugary chaos wrapped in a grin and tiny fangs.",
                  ("Mischievous and bright", "Sweet and wild"),
                  "Candy Fang Creature always brings a surprise. Usually a sprinkle or two.",
                  rarity="rare",
                  location="the bramble paths between Dumpling Dell and Whisper Woods.",
                  signature_squish="a sugary chomp and a sprinkle scatter. *crunch-poof.*",
                  pack_mate="Soft Fang Critter",
                  keeper_says="Tiny fangs. Sugar grin. The fangs? Also candy."),
        Character(45, "Dream Eater Squish", "Creepy-Cute Creatures",
                  "Floats through sleepy sparkles and leaves perfect pops behind.",
                  ("Mythic and dreamy", "Soft and magical"),
                  "Dream Eater Squish turns bedtime dreams into glowing adventures.",
                  rarity="epic",
                  location="the dream-mist of Star Pond.",
                  signature_squish="a sleepy float and a glowing pop. *hmmm-pop.*",
                  pack_mate="Sleepy Slime Pet",
                  keeper_says="Close your eyes. The sparkle finds you. The pop is always gentle."),
        Character(46, "Arcane Wobble Kitty", "Creepy-Cute Creatures",
                  "Spins through the air with glowing runes and magical pawprints.",
                  ("Mystical and playful", "Elegant and bright"),
                  "Wherever Arcane Wobble Kitty wobbles, a little magic follows.",
                  rarity="epic",
                  location="the rune circles of Cuddle Glade at midnight.",
                  signature_squish="a spin, a glow, a soft wobble. *swirl-glow.*",
                  pack_mate="Wobble Kitty",
                  keeper_says="Watch the pawprints. Watch the runes light up. Watch the magic happen."),
        Character(47, "Phantom Jelly Beast", "Creepy-Cute Creatures",
                  "Part creature, part jelly, all glowing mystery.",
                  ("Strange and spectacular", "Bold and magical"),
                  "Phantom Jelly Beast rushes through the shadows with a shining splash.",
                  rarity="epic",
                  location="the thick fog of Crescent Cave.",
                  signature_squish="a rushing glow and a shining splash. *whoooooosh.*",
                  pack_mate="Glow Ghost Puff",
                  keeper_says="Half here. Half not. Phantom Jelly Beast is mostly a glow that runs."),
        Character(48, "Mythic Plush Familiar", "Creepy-Cute Creatures",
                  "A legendary guardian said to watch over every lost squishy.",
                  ("Protective and kind", "Mythic and radiant"),
                  "When hope feels far away, Mythic Plush Familiar is never far behind.",
                  rarity="mythic",
                  location="wherever a squishy gets lost.",
                  signature_squish="a soft pawprint, then another. *...*",
                  pack_mate="Glow Ghost Puff",
                  keeper_says="When a squishy gets lost, a soft pawprint shows up in the dust. Then another. Then another. Someone is always coming back for them."),
    ]


def all_characters() -> list[Character]:
    return _foods() + _goo() + _creatures()


def by_num() -> dict[int, Character]:
    return {c.num: c for c in all_characters()}


def featured_characters() -> list[Character]:
    """All 48 characters (Phase 4: every character is featured)."""
    lookup = by_num()
    return [lookup[n] for n in FEATURED_NUMS]


def solo_characters() -> list[Character]:
    """The 15 characters (5 per pack) that get full-page hero T8
    treatment instead of a T9 2-up spread."""
    lookup = by_num()
    return [lookup[n] for n in SOLO_NUMS]


def gallery_characters() -> list[Character]:
    """No-op in Phase 4 — every character is featured. Kept for
    backwards-compat with existing tests; returns an empty list."""
    return []

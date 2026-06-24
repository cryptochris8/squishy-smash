"""Book 2 per-spread layout data structure.

Mirrors book/manuscript/book2_layout_brief.md (the audit doc).
Coordinates are in 1584x672 working-spread space; the pipeline scales
+ clamps them to the print-safe area at render time.
"""

# Techniques
NEG = "negative_space"      # (a) — type floats directly on painted negative space
WASH = "wash_panel"         # (b) — palette-keyed scumbled wash panel under type
REVERSE = "reverse_out"     # (c) — cream type on confirmed deep-value zone
TRIPTYCH = "triptych_bottom"  # 3 parallel panels across the spread bottom
DUAL_WASH = "dual_wash_panel"  # WASH technique but with one box+content per page

# Wash panel feathering (px in working coords; scales 3.9x at print res)
WASH_FEATHER_WORK = 7

SPREADS = {
    1: {
        "title": "Three Places at Peace",
        "zone": "L",
        "box": (72, 60, 440, 360),
        "technique": WASH,
        "text_color": "#4A2E1E",
        "wash_color": "#FBEEDB",
        "wash_opacity": 0.84,
        "max_x": 520,  # safety: don't intrude past Sparkle rays anchor
        "notes": "Sparkle rays land at (790, 130) — keep clear.",
    },
    2: {
        "title": "The Flicker",
        "zone": "L",
        "box": (90, 380, 430, 250),
        "technique": NEG,
        "text_color": "#4B3E5C",
        "notes": "Lower-left soft peach wash; cleanest negative space in book.",
    },
    3: {
        "title": "Three Look Up",
        "zone": "BOTH",
        "technique": DUAL_WASH,
        "verso_box": (60, 60, 470, 250),    # upper-left over peach Pudding sky
        "recto_box": (1064, 163, 460, 200), # mid recto sky, clear gap above Bun's head; reveals most of moon
        "wash_color": "#F6EBD8",
        "wash_opacity": 0.86,
        "verso_text_color": "#5A3322",      # Pudding-warm brown
        "recto_text_color": "#3A2F58",      # Moonlit violet
        "notes": "Verso = three 'looked up' lines (collective event). Recto = closing thesis (reflection). Auto-fit panels.",
    },
    4: {
        "title": "At the Border",
        "zone": "L",
        "box": (60, 80, 440, 280),
        "technique": WASH,
        "text_color": "#5B2F1C",
        "wash_color": "#F9EAD2",
        "wash_opacity": 0.82,
        "notes": "Italic Sploink / Pmf land at end above syrup-river seam.",
    },
    5: {
        "title": "Three",
        "zone": "BOTH",
        "technique": DUAL_WASH,
        "verso_box": (60, 470, 470, 180),   # bottom-left, below Soft Dumpling's feet
        "recto_box": (1064, 470, 460, 180), # bottom-right, below Bun's feet
        "wash_color": "#F7ECD8",
        "wash_opacity": 0.84,
        "verso_text_color": "#5A2E1A",      # Pudding-warm brown (verso = Bun arrival)
        "recto_text_color": "#3D2A4A",      # cool plum (recto = dialogue + closing thesis)
        "notes": "Split at dialogue break. Verso = Bun's arrival + Thup-thup. Recto = her dialogue + load-bearing closing thesis.",
    },
    6: {
        "title": "Into Pudding Hills",
        "zone": "BOTH",
        "technique": DUAL_WASH,
        "verso_box": (60, 440, 470, 220),   # bottom-left, below trio's feet
        "recto_box": (1064, 380, 460, 280), # lower-right, below Sparkle Mochi; needs room for chant
        "wash_color": "#FAE9CD",
        "wash_opacity": 0.82,
        "verso_text_color": "#5C2E18",
        "recto_text_color": "#5C2E18",
        "notes": "Split at mochi dialogue. Verso = narrative setup. Recto = mochi dialogue + Pmf chant (inline italic).",
    },
    7: {
        "title": "The First Shard",
        "zone": "BOTH",
        "technique": DUAL_WASH,
        "verso_box": (60, 440, 470, 220),   # bottom-left, below the Galaxy Dumpling, over horizon
        "recto_box": (1075, 75, 455, 200),  # REGEN: trio now lower-right; text -> top-right clear sky, above their faces
        "wash_color": "#F8E8CC",
        "wash_opacity": 0.86,               # higher opacity to mask busy apple/grass detail
        "verso_text_color": "#4A2A1A",      # deep warm brown
        "recto_text_color": "#4A2A1A",
        "notes": "Split at sky-dumpling reveal. Original REVERSE failed because verso-L sits over the apple orchard, not the Galaxy Dumpling deep-value zone.",
    },
    8: {
        "title": "Into Goo Coast",
        "zone": "L",
        "box": (60, 325, 460, 280),  # bottom-left of verso, below Glitter Goo cameo, over goo water/foam (raised so chant lands inside safety)
        "technique": WASH,
        "text_color": "#1F4655",
        "wash_color": "#F2EBDA",
        "wash_opacity": 0.86,        # higher to mask foam/bubble detail
        "chant": "Pmf, Sploink",
        "chant_size_pt": 18,
        "chant_extra_above_pt": 6,
        "notes": "Moved verso bottom-left so trio on recto is unblocked. Chant rendered after narrative.",
    },
    9: {
        "title": "The Second Shard",
        "zone": "BOTH",
        "technique": DUAL_WASH,
        "verso_box": (60, 470, 470, 180),   # bottom-left, below bouncing trio, over water/bubbles
        "recto_box": (1064, 470, 460, 180), # bottom-right, below Bun, over water (Aurora Cube edge masked)
        "wash_color": "#F8EAD0",
        "wash_opacity": 0.86,               # higher to mask cube/water detail
        "verso_text_color": "#2A4060",
        "recto_text_color": "#2A4060",
        "notes": "Split at the cube reveal. Verso = trio bouncing (action). Recto = shard rises + Aurora Cube reveal.",
    },
    10: {
        "title": "Into Moonlit Hollow",
        "zone": "BOTH",
        "technique": DUAL_WASH,
        "verso_box": (60, 494, 470, 220),    # bottom-left; y picked so verso bottom aligns with recto bottom
        "recto_box": (1064, 380, 460, 280),  # bottom-right, taller to fit cameo dialogue + chant
        "wash_color": "#F4E8D2",
        "wash_opacity": 0.86,                # masks busy mushroom/moss foreground
        "verso_text_color": "#3A2F58",       # Moonlit violet
        "recto_text_color": "#3A2F58",
        "notes": "Split at cameo introduction. Verso = entering Moonlit. Recto = mushrooms + cameo dialogue + chant (inline italic, no 22pt escalation).",
    },
    11: {
        "title": "The Deepest Grove",
        "zone": "L",
        "box": (70, 372, 430, 250),  # REGEN: ghost now occupies upper-left; text -> dark lower-left forest floor
        "technique": REVERSE,
        "text_color": "#F4E6C6",
        "almost_leading_pt": 27,  # +1pt for the repeated 'almost' lines
        "notes": "REGEN comp: ghost upper-left, trio lower-right. Cream type on the deep-value lower-left forest floor, clear of the ghost.",
    },
    12: {
        "title": "Everybody Squish",
        "zone": "R",
        "box": (1015, 360, 505, 240),  # REGEN: hug now fills the left; text -> open sunburst on the right
        "technique": WASH,
        "text_color": "#2A1A38",
        "wash_color": "#F6E9CB",
        "wash_opacity": 0.84,  # slightly higher to read over the bright burst
        "chant": "PMF! SPLOINK! THUP!",
        "chant_size_pt": 28,
        "chant_uses_black_italic": True,  # Bookmania Black Italic ALL CAPS
        "pact_line": True,  # 'Every pop is a hello. Every hello comes back.' closes the block
        "pact_extra_above_pt": 8,
        "notes": "REGEN comp: 3-way hug on the left, radiant burst on the right. Text on the open right side, clear of the hug.",
    },
    13: {
        "title": "The Three Cores",
        "zone": "L",
        "box": (60, 369, 460, 220),  # mirrored to verso side; raised so closing line lands inside safety
        "technique": WASH,
        "text_color": "#3A2A18",
        "wash_color": "#F7EAD0",
        "wash_opacity": 0.84,
        "cores_naming_extra_above_pt": 6,  # 'Celestial... Singularity... Mythic...' gets ceremonial leading
        "notes": "Verso bottom-left, under Soft Dumpling — more room than original R placement.",
    },
    14: {
        "title": "The Sparkle, Brighter",
        "zone": "L",
        "box": (80, 225, 440, 200),
        "technique": NEG,
        "text_color": "#6A3A1A",
        "notes": "SD silhouette at x=180-280; type above her. Keep Sparkle rays visually heroic.",
    },
    15: {
        "title": "Going Home",
        "zone": "TRIPTYCH",
        "technique": TRIPTYCH,
        "panels": [
            {"box": (40, 550, 460, 100), "text_color": "#5A3322"},
            {"box": (562, 550, 460, 100), "text_color": "#1F4A55"},
            {"box": (1084, 550, 460, 100), "text_color": "#3A2F58"},
        ],
        "wash_color": "#F6EBD8",
        "wash_opacity": 0.86,
        "notes": "Mirror of S3 layout for parallel closure. Panels y >= 550 clears glow each character carries.",
    },
    16: {
        "title": "Three Homecomings",
        "zone": "R",
        "box": (1084, 480, 460, 160),
        "technique": WASH,
        "text_color": "#3A2F58",
        "wash_color": "#F4ECD8",
        "wash_opacity": 0.86,
        "notes": "Three 'Each home...' sentences set as three parallel lines.",
    },
    17: {
        "title": "Three Borders, Touching",
        "zone": "L",
        "box": (90, 452, 420, 200),
        "technique": WASH,
        "text_color": "#6A2D1A",
        "wash_color": "#F9EBCD",
        "wash_opacity": 0.80,
        "max_y": 620,  # clears cherry-pudding at (40, 540-650)
        "notes": "Three sentences with clear paragraph breaks for rhythm.",
    },
    18: {
        "title": "The Close",
        "zone": "R",
        "box": (1090, 180, 440, 220),
        "technique": NEG,
        "text_color": "#7A3A18",
        "squishkeeper_leading_pt": 28,  # +2pt for italic close
        "notes": "First sentence Bookmania Regular; italic Squishkeeper close in Bookmania Italic with 28pt leading. Text-block top y=280 BELOW Sparkle star at y=165.",
    },
}


def get(spread_num: int) -> dict:
    return SPREADS[spread_num]

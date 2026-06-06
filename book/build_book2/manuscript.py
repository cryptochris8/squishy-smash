"""Per-spread prose text for Book 2.

Mirrors book/manuscript/book2_manuscript_draft.md. Italic spans marked with
*asterisks* in the source manuscript are represented here as (text, italic)
tuples per "run" — the typesetting pipeline reads runs and switches font
between Bookmania Regular and Bookmania Italic.

Special structures:
- Triptychs (S3, S15) have per-panel text + a closing line
- Chant spreads (S6, S8, S10) have the chant as a separate trailing run
- S12 is the climax: very short body + chant + Pact line
- S18 has the Squishkeeper italic close as a separate trailing run
"""

# A "run" is (text, italic_bool). Body type renders runs as a single
# inline-flow paragraph with font swapping at italic boundaries.
# A "para" is a list of runs; spreads can have multiple paragraphs.

SPREADS = {
    1: {
        "paras": [[
            ("Three places had wobbled themselves into being, one for each first feeling. ", False),
            ("Pudding Hills, where comfort spilled warm. Goo Coast, where surprise spilled glossy. Moonlit Hollow, where the brave-cuddle spilled quiet. ", False),
            ("Above them all, the Sparkle held. Small and bright. The way being seen is always bright.", False),
        ]],
    },
    2: {
        "paras": [[
            ("And then. The Sparkle did something it had never done. It flickered. It wobbled. It split, very gently, into three. ", False),
            ("One shard drifted toward Pudding Hills. One drifted toward Goo Coast. One drifted toward Moonlit Hollow. ", False),
            ("The three places, for the first time, felt a little quieter.", False),
        ]],
    },
    3: {
        "verso_paras": [[
            ("In Pudding Hills, Soft Dumpling looked up. In Goo Coast, Goo Ball looked up. In Moonlit Hollow, Blushy Bun Bunny looked up.", False),
        ]],
        "recto_paras": [[
            ("None of them had ever left home before. But each of them, very quietly, decided it was time.", False),
        ]],
    },
    4: {
        "paras": [[
            ("Soft Dumpling reached the edge of the Pudding Hills and stopped. The grass was different here. Greener. Glossier. ", False),
            ("Just past where the syrup river thinned to a trickle, somebody glossy was waiting. ", False),
            ("Sploink", True), (", said Goo Ball, by way of hello. Soft Dumpling tilted. ", False),
            ("Pmf", True), (", she answered, which is dumpling for ", False),
            ("hello back", True), (".", False),
        ]],
    },
    5: {
        "verso_paras": [[
            ("A third sound came from behind them. ", False),
            ("Thup, thup", True), (". Blushy Bun Bunny hopped out from somewhere between the two worlds, cheeks rosier than usual.", False),
        ]],
        "recto_paras": [[
            ("\"Oh good,\" said the bunny. \"I had a feeling you would find each other.\" ", False),
            ("And the three of them, three different feelings standing on a boundary nobody had ever crossed, very gently started walking.", False),
        ]],
    },
    6: {
        "verso_paras": [[
            ("They walked through Pudding Hills first. Soft Dumpling led the way, because Pudding Hills was the place she knew. Past the cream-bowl hills. Past the syrup river. Past a small mochi that waved one shimmery wave and pointed quietly toward the orchard.", False),
        ]],
        "recto_paras": [
            [("\"The shard fell that way,\" said the shimmery mochi. \"It is bigger than it looks.\" So they walked deeper.", False)],
            [("Pmf", True), (", said the soft ground under Soft Dumpling. ", False),
             ("Pmf", True), (", said the syrup-warm air. The sound of Pudding Hills walked along with them.", False)],
        ],
    },
    7: {
        "verso_paras": [[
            ("And it was. The shard rested in a hush at the orchard's edge, half-glowing. Above it loomed a dumpling the size of a sky, gentle and enormous, full of small quiet stars.", False),
        ]],
        "recto_paras": [[
            ("\"I will move,\" said the sky-dumpling, in a voice like a sky, \"when the three of you ask together.\" Soft Dumpling asked. Goo Ball asked. Blushy Bun Bunny asked. The sky-dumpling smiled and stepped aside.", False),
        ]],
    },
    8: {
        "paras": [[
            ("Next they crossed into Goo Coast. Now it was Goo Ball who led, because Goo Coast was the place he knew. ", False),
            ("Past the bubble-tide. Past the glossy shore. Past a goo who shimmered like an opal and pointed seaward. ", False),
            ("\"The shard fell out there,\" said the opal goo. \"You will have to bounce for it.\" ", False),
        ]],
        "chant_runs": [
            ("Pmf", True), (", said the dumpling behind them. ", False),
            ("Sploink", True), (", said the goo-tide ahead. Now they carried two sounds.", False),
        ],
    },
    9: {
        "verso_paras": [[
            ("They bounced for it. Soft Dumpling bounced first, which was a surprise to everyone, including Soft Dumpling. Goo Ball bounced second, naturally. Blushy Bun Bunny bounced last and the highest.", False),
        ]],
        "recto_paras": [[
            ("The shard rose to meet them, glossy and bright, and a cube the color of dawn, who had been watching from the deep, let it go with a slow nod.", False),
        ]],
    },
    10: {
        "verso_paras": [[
            ("Last, they crossed into Moonlit Hollow. Now Blushy Bun Bunny led, because Moonlit Hollow was the place she knew. The light was different here. Soft, slow, not afraid of itself.", False),
        ]],
        "recto_paras": [
            [("They went past the silver mushrooms. Past a bunny whose eyes were stars, who turned all her stars on them at once. \"The shard is in the deepest grove,\" said the bunny with stars in her eyes. \"It is dimming the fastest.\"", False)],
            [("Pmf. Sploink. Thup.", True),
             (" They carried three sounds now, and one quiet shard between them.", False)],
        ],
    },
    11: {
        "paras": [[
            ("The deepest grove was darker than dark. ", False),
            ("The third shard waited there, almost flickered out, almost too quiet to find. ", False),
            ("A puff loomed over it, a feeling shaped like a friendly haunting, and said nothing at all. ", False),
            ("The trio stood very still. The shard was small. The Sparkle, what was left of it, trembled.", False),
        ]],
    },
    12: {
        "paras": [[
            ("Then Blushy Bun Bunny did something brave. ", False),
            ("She squeezed Soft Dumpling. ", False),
            ("She squeezed Goo Ball. ", False),
            ("She squeezed herself. ", False),
            ("\"EVERYBODY SQUISH!\" she shouted, and they did. ", False),
            ("Three pops at once. The three sounds became one.", False),
        ]],
        "chant_runs": [
            ("PMF! SPLOINK! THUP!", True),
        ],
        "pact_runs": [
            ("Every pop is a hello. Every hello comes back.", True),
        ],
    },
    13: {
        "paras": [[
            ("And the dark grove was suddenly not dark. ", False),
            ("The three shards rose, glossy and warm and brave at once, and touched. ", False),
            ("Above them, slow and enormous, the three Cores arrived. ", False),
            ("Celestial Dumpling Core. Singularity Goo Core. Mythic Plush Familiar. ", False),
            ("They bowed to the trio who had done what no Core could have done.", False),
        ]],
    },
    14: {
        "paras": [[
            ("The Sparkle came back. Not the same Sparkle, exactly. ", False),
            ("A little bigger, a little warmer. ", False),
            ("Brighter than it had ever been, because three first feelings had remembered each other.", False),
        ]],
    },
    15: {
        "panel_paras": [
            [[("Soft Dumpling carried a little bit of the light home to Pudding Hills.", False)]],
            [[("Goo Ball carried a little bit of the light home to Goo Coast.", False)]],
            [[("Blushy Bun Bunny carried a little bit of the light home to Moonlit Hollow.", False)]],
        ],
    },
    16: {
        "paras": [[
            ("Each home was waiting. Each home had been quieter without them. ", False),
            ("Each home, when they returned, made a sound a pack only makes once.", False),
        ]],
    },
    17: {
        "paras": [[
            ("And for the first time, three places that had never visited each other began to. ", False),
            ("Soft Dumpling visits Goo Coast on Sundays. ", False),
            ("Goo Ball has tried Moonlit Hollow's quiet. ", False),
            ("Blushy Bun Bunny is teaching the Pudding Hills how to hop.", False),
        ]],
    },
    18: {
        "paras": [[
            ("The Sparkle is the light that comes from being found.", False),
        ]],
        "squishkeeper_close": [
            ("I have been there for every wobble. And tomorrow, another wobble. They always come back.", True),
        ],
    },
}


def get(spread_num: int) -> dict:
    return SPREADS[spread_num]

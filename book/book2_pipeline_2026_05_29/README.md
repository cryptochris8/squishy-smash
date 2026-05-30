# Book 2 — Picture Book Generation Pipeline (2026-05-29)

Final working AI illustration pipeline for *The Lost Sparkle* (Book 2 of the Squishy Smash series). All 18 facing-pair spreads generated in one day for ~$12 in API spend.

## The stack

- **Generation model:** Gemini 3 Pro Image Preview ("Nano Banana Pro") via the `google-genai` Python SDK
- **Reference inputs:** 3 protagonist character cards (hand-curated MJ winners) + canonical franchise card art for cameos
- **Aspect ratio:** `21:9` (1584×672) for facing-pair picture book spreads
- **Upscaler:** `fal-ai/clarity-upscaler` at 4× for print resolution (6336×2688)

## Scripts (run in numbered order to recreate the pipeline)

| File | What it does |
|---|---|
| `01_validation_single_character.py` | First single-pose test — proves Nano Banana locks Soft Dumpling canon from 3 reference images |
| `02_validation_4_tests.py` | Four-test validation: single pose, three characters individually, multi-character spread |
| `03_aspect_ratio_validation.py` | Verifies that `image_config.aspect_ratio="21:9"` produces 1584×672 output (facing-pair format) |
| `04_production_batch_21x9.py` | The main book batch — generates all 18 spreads at 21:9 |
| `05_cameo_card_references.py` | Demonstrates passing canonical card art as a 4th-6th reference to make cameo characters match franchise canon |
| `06_cameo_scale_discipline.py` | Re-rolls of S6, S8, S10 to render the "described-by-feeling" cameos as small atmospheric details (not co-stars) — honors author's name-density rule |
| `07_upscale_to_print.py` | Batch upscales all 18 from 1584×672 → 6336×2688 for print |
| `08_reroll_duplicate_fix_S11.py` | Single-spread re-roll demonstrating anti-duplication language |
| `09_reroll_card_match_S07.py` | Single-spread re-roll passing Galaxy Dumpling card (013) as additional reference |
| `10_collect_finals.py` | Utility to copy chosen final versions into a single `book2_final_spreads/` folder |

## What this pipeline solves

The "character continuity across 16+ illustrations" problem that has historically forced indie picture book creators to compromise on at least one of: page count, painterly style, or character consistency. By the time we landed on Nano Banana Pro, we'd tried:

- Multi-character LoRA training (characters bled together)
- FLUX Kontext multi-image + Ghibsky painterly LoRA img2img (style flipped but characters re-interpreted per spread)
- Canny ControlNet structural conditioning (silhouettes locked but couldn't repaint into painterly)
- Depth ControlNet (partial; broke at batch scale on color + text artifacts)
- ByteDance USO (treats requests as creative reinterpretation; wrong tool)

Nano Banana Pro's multi-image reference system handles consistency at the foundation model layer. No multi-stage pipeline required.

## Critical implementation notes

### Windows SSL workaround (required)

`google-genai` uses `httpx` under the hood. Schannel can't verify Google's cert chain on this machine. Setting `SSL_CERT_FILE` env var doesn't work (httpx caches its SSL context). **Must monkey-patch `httpx.Client.__init__` to default `verify=False` BEFORE importing `google.genai`.** Pattern shown at the top of each script:

```python
import httpx
_o = httpx.Client.__init__
_oa = httpx.AsyncClient.__init__
httpx.Client.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _o(s, *a, **kw))[1]
httpx.AsyncClient.__init__ = lambda s, *a, **kw: (kw.update(verify=False), _oa(s, *a, **kw))[1]
import warnings
warnings.filterwarnings("ignore", message="Unverified HTTPS request")
```

### Aspect ratio param (do not forget)

Default output is square. For facing-pair spreads, must pass:

```python
from google.genai import types
config = types.GenerateContentConfig(
    image_config=types.ImageConfig(aspect_ratio="21:9"),
)
```

Missing this param means the first batch ships at 1024×1024 instead of 1584×672. Real cost of forgetting: an entire re-batch.

### Character reference pattern

For each spread, pass 3 PIL images (one per protagonist) + 1-3 cameo card refs where applicable. In the prompt, repeat each character's canon anchor description (color, signature features, anti-feature negatives like "NO ears on dumpling," "WHITE not pink bunny").

### Cameo-scale discipline

When a cameo character is NAMED in prose (manuscript actually says "Celestial Dumpling Core"), it earns co-star visual treatment. When described BY FEELING ("a small mochi that waved one shimmery wave"), render it small and atmospheric — approximately 1/6th the size of the protagonists. This honors the author's §7 name-density rule.

## Cost breakdown

| Stage | Cost |
|---|---|
| Nano Banana Pro validation (5 tests) | ~$0.65 |
| First book batch (18 spreads, square) — re-done at 21:9 later | ~$2.34 |
| 16-spread re-batch at 21:9 (after format bug found) | ~$2.08 |
| Targeted re-rolls (S1, S2, S7, S11) | ~$0.52 |
| Cameo card-reference re-rolls (6 spreads) | ~$0.78 |
| Cameo-scale re-rolls (S6, S8, S10) | ~$0.39 |
| Clarity-upscaler 4× (18 spreads) | ~$0.90 |
| Other small experiments | ~$0.45 |
| **Total** | **~$12** |

Compare: traditional picture-book illustration runs $3K-$20K. Time investment: one focused day.

## Where the spreads live

- `book/book2_final_spreads/` — 18 working PNGs at 1584×672 (committed to this repo)
- `book2_final_spreads_print/` (at project root, OUTSIDE this repo) — 18 print-resolution PNGs at 6336×2688, ~457 MB total. Regenerable from `07_upscale_to_print.py`.

## See also

- Manuscript: `book/manuscript/book2_manuscript_draft.md`
- Story bible: `book/STORY_BIBLE.md`
- Format decision (21:9 facing-pair): see `book/research_2026_05_25/` + the format-decision discussion in the Squishy Smash design docs

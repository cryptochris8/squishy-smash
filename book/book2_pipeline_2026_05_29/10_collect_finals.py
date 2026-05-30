"""Copy all 18 final spread PNGs into a single clean folder with simple names.

After this runs, `book2_final_spreads/` has:
  spread_01.png ... spread_18.png

That's the canonical "final cut" — no more navigating multiple versions.
"""
import shutil
from pathlib import Path

PROJ = Path(r"C:\Users\chris\Squishy-smash")
BATCH = PROJ / "_tmp_spreads_batch_v2"
P1 = PROJ / "_tmp_pipeline_a_test"
VAL2 = PROJ / "_tmp_validation_v2"
OUT = PROJ / "book2_final_spreads"
OUT.mkdir(exist_ok=True)

# Final file per spread, as locked in memory
FINALS = {
    1:  BATCH / "spread_01_lavender_grove_edited.png",
    2:  BATCH / "spread_02_the_flicker_pass2_painterly.png",
    3:  BATCH / "spread_03_three_look_up_v2_pass2_painterly.png",
    4:  BATCH / "spread_04_at_the_border_signature_edited.png",
    5:  BATCH / "spread_05_three_v2_pass2_painterly.png",
    6:  BATCH / "spread_06_pipeline_a_edited.png",
    7:  BATCH / "spread_07_the_first_shard_pass2_painterly.png",
    8:  BATCH / "spread_08_into_goo_coast_signature_edited.png",
    9:  BATCH / "spread_09_the_second_shard_v3_edited.png",
    10: BATCH / "spread_10_into_moonlit_hollow_pass2_painterly.png",
    11: BATCH / "spread_11_the_deepest_grove_pass2_painterly.png",
    12: BATCH / "spread_12_burst_amplified_edited.png",
    13: BATCH / "spread_13_the_three_cores_v2_pass2_painterly.png",
    14: BATCH / "spread_14_sparkle_brighter_add_silhouette_edited.png",
    15: BATCH / "spread_15_going_home_v2_pass2_painterly.png",
    16: BATCH / "spread_16_no_churches_edited.png",
    17: VAL2  / "spread_17_resolution_pass2_painterly.png",
    18: BATCH / "spread_18_the_close_pass2_painterly.png",
}

print(f">>> Collecting 18 finals into {OUT}")
missing = []
for n, src in FINALS.items():
    if not src.exists():
        print(f"  !! S{n:02d}: MISSING {src}")
        missing.append(n)
        continue
    dst = OUT / f"spread_{n:02d}.png"
    shutil.copy2(src, dst)
    src_label = src.parent.name + "/" + src.name
    print(f"  S{n:02d}: {src_label}  ->  spread_{n:02d}.png")

if missing:
    print(f"\n!! Missing files for spreads: {missing}")
else:
    print(f"\n>>> All 18 collected into {OUT}")
print(f">>> Open the folder in Explorer or Procreate's import dialog.")

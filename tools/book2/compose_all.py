"""Render every Book #2 spread spec under book/spread_specs/ in one pass."""
import glob, os, subprocess, sys

SQ = r"C:\Users\chris\Squishy-smash\squishy_smash"
SPECS_DIR = os.path.join(SQ, "book", "spread_specs")
COMPOSER = os.path.join(SQ, "tools", "book2", "compose_spread.py")

specs = sorted(glob.glob(os.path.join(SPECS_DIR, "*.toml")))
print(f"Rendering {len(specs)} spec(s)...\n")
failed = []
for spec in specs:
    name = os.path.basename(spec)
    print(f">>> {name}")
    r = subprocess.run(["python3", COMPOSER, spec], cwd=SQ,
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    if r.returncode != 0:
        failed.append(name)
        print(f"  FAILED:\n{r.stdout[-800:]}\n{r.stderr[-1500:]}")
    else:
        # echo just the output line
        for line in r.stdout.strip().splitlines():
            if "->" in line:
                print(f"  {line.strip()}")

if failed:
    print(f"\nFAILED ({len(failed)}): {failed}")
    sys.exit(1)
print(f"\nALL {len(specs)} SPREADS RENDERED")

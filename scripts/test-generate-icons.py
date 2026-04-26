"""Verifies generate-icons.py produced all expected outputs with correct properties."""
from pathlib import Path
from PIL import Image
import sys

ROOT = Path(__file__).resolve().parent.parent

EXPECTED = {
    "og-card.png":      {"size": (1200, 630), "mode_in": ("RGB", "RGBA")},
    "favicon-32.png":   {"size": (32, 32),    "mode_in": ("RGBA",)},
    "favicon-180.png":  {"size": (180, 180),  "mode_in": ("RGBA",)},
    "favicon-192.png":  {"size": (192, 192),  "mode_in": ("RGBA",)},
    "favicon-512.png":  {"size": (512, 512),  "mode_in": ("RGBA",)},
}

failures = []

for name, spec in EXPECTED.items():
    p = ROOT / name
    if not p.exists():
        failures.append(f"{name}: missing")
        continue
    im = Image.open(p)
    if im.size != spec["size"]:
        failures.append(f"{name}: size {im.size}, expected {spec['size']}")
    if im.mode not in spec["mode_in"]:
        failures.append(f"{name}: mode {im.mode}, expected one of {spec['mode_in']}")

# favicon.ico exists and contains at least one frame
ico = ROOT / "favicon.ico"
if not ico.exists():
    failures.append("favicon.ico: missing")
else:
    im = Image.open(ico)
    # Pillow's IcoImagePlugin exposes the full frame inventory via info["sizes"];
    # seek() only walks the "best" frame in recent Pillow, so we check info["sizes"]
    # plus a seek-based fallback for older versions.
    sizes = set(im.info.get("sizes") or [])
    try:
        i = 0
        while True:
            im.seek(i)
            sizes.add(im.size)
            i += 1
    except EOFError:
        pass
    if (32, 32) not in sizes:
        failures.append(f"favicon.ico: no 32x32 frame found (got {sorted(sizes)})")

# Favicons must have transparent pixels (alpha keying worked)
for name in ("favicon-32.png", "favicon-512.png"):
    p = ROOT / name
    if p.exists():
        im = Image.open(p).convert("RGBA")
        alphas = im.getchannel("A").getextrema()
        if alphas[0] != 0:
            failures.append(f"{name}: no transparent pixels (min alpha {alphas[0]}); alpha keying broken")

# OG card must contain non-white content (i.e. the hero is actually embedded, not a blank canvas)
ogc = ROOT / "og-card.png"
if ogc.exists():
    im = Image.open(ogc).convert("RGB")
    extrema = im.getextrema()
    if all(lo == 255 for lo, _ in extrema):
        failures.append("og-card.png: appears entirely white (hero image not embedded)")

if failures:
    print("FAIL:")
    for f in failures:
        print(f"  - {f}")
    sys.exit(1)
print("PASS: all icon outputs valid")

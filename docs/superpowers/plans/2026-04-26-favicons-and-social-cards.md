# Favicons and Social Cards Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder text favicon (`TC` on dark square) and old OG cards with graffiti-flower favicons (cropped from `assets/phone_bouquet.png`) and a treehouse social card (from `assets/tech_birdhouse.png`), wired into all six public-facing HTML pages.

**Architecture:** A single Pillow-based Python script (`scripts/generate-icons.py`) reads the two source PNGs from `assets/` and writes seven derived files (one OG card + six favicon sizes/formats) to the project root. Six HTML files get an identical `<head>` swap, with one variation for two pages that lack a `twitter:image` tag. Old assets are deleted after a grep verifies no remaining references.

**Tech Stack:** Python 3 + Pillow (already available locally), plain HTML edits, git.

**Spec:** [docs/superpowers/specs/2026-04-26-favicons-and-social-cards-design.md](../specs/2026-04-26-favicons-and-social-cards-design.md)

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `scripts/generate-icons.py` | Create | One-shot generator for OG card + favicon set |
| `og-card.png` | Create (output) | 1200×630 OG/Twitter card, hero on white |
| `favicon-32.png` | Create (output) | 32×32 modern browser tab icon |
| `favicon-180.png` | Create (output) | 180×180 apple-touch-icon |
| `favicon-192.png` | Create (output) | 192×192 Android home screen / PWA |
| `favicon-512.png` | Create (output) | 512×512 Android splash / PWA |
| `favicon.ico` | Create (output) | Multi-size ICO (16+32+48) for legacy |
| `index.html` | Modify | `<head>` favicon + OG image refs |
| `calendar.html` | Modify | `<head>` favicon + OG image refs (insert `twitter:image`) |
| `projects.html` | Modify | `<head>` favicon + OG image refs |
| `ideas.html` | Modify | `<head>` favicon + OG image refs |
| `members.html` | Modify | `<head>` favicon + OG image refs (insert `twitter:image`) |
| `ethics.html` | Modify | `<head>` favicon + OG image refs |
| `favicon.svg` | Delete | Old TC text icon, no longer referenced |
| `og-image.png` | Delete | Old OG card, no longer referenced |
| `og-vault.png` | Delete | Old ideas-page OG card, no longer referenced |

---

## Chunk 1: Generation Script

### Task 1: Build `scripts/generate-icons.py`

**Files:**
- Create: `scripts/generate-icons.py`
- Reads: `assets/phone_bouquet.png`, `assets/tech_birdhouse.png`
- Writes: `og-card.png`, `favicon.ico`, `favicon-32.png`, `favicon-180.png`, `favicon-192.png`, `favicon-512.png`

- [ ] **Step 1: Write the failing test (a one-shot verification script)**

Create `scripts/test-generate-icons.py`:

```python
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
    sizes = []
    try:
        i = 0
        while True:
            im.seek(i)
            sizes.append(im.size)
            i += 1
    except EOFError:
        pass
    if not any(s == (32, 32) for s in sizes):
        failures.append(f"favicon.ico: no 32x32 frame found (got {sizes})")

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 scripts/test-generate-icons.py`
Expected: FAIL — none of the output files exist yet.

- [ ] **Step 3: Implement `scripts/generate-icons.py`**

Create `scripts/generate-icons.py`:

```python
"""
Generate site icon set: OG social card + favicons.

Usage:  python3 scripts/generate-icons.py    (run from repo root)

Reads:
  - assets/phone_bouquet.png  (favicon source — bouquet cropped tightly)
  - assets/tech_birdhouse.png (OG card source — full hero image)

Writes (to repo root):
  - og-card.png       1200x630   social card
  - favicon-32.png    32x32
  - favicon-180.png   180x180    apple-touch-icon
  - favicon-192.png   192x192    android
  - favicon-512.png   512x512    android / pwa
  - favicon.ico       16+32+48   legacy multi-size ico

Idempotent — overwrites prior outputs.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"

# Tunable favicon crop bounds, in pixels, against the 1024x1024 phone_bouquet source.
# Tightens onto the bouquet (upper-center of the source image), excluding the phone
# and the figure. Adjust if the crop feels off.
BOUQUET_CROP = (100, 20, 760, 680)  # (left, upper, right, lower) — 660x660 square

# Threshold for converting near-white pixels to transparent in the favicon.
# 245 leaves a thin off-white halo intact (avoids speckle on petal edges); raise toward
# 255 for cleaner edges if the colorful interior reads well at 16px.
WHITE_THRESHOLD = 245

OG_CANVAS = (1200, 630)
HERO_HEIGHT = 590  # leaves 20px top/bottom padding on the 630-tall canvas

FAVICON_SIZES = [32, 180, 192, 512]
ICO_SIZES = [(16, 16), (32, 32), (48, 48)]


def alpha_key_white(im: Image.Image, threshold: int) -> Image.Image:
    """Convert near-white pixels to fully transparent. Returns RGBA."""
    im = im.convert("RGBA")
    pixels = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (r, g, b, 0)
    return im


def build_favicon_master() -> Image.Image:
    """Crop the bouquet, alpha-key white, return as RGBA at native crop size."""
    src = Image.open(ASSETS / "phone_bouquet.png").convert("RGB")
    cropped = src.crop(BOUQUET_CROP)
    return alpha_key_white(cropped, WHITE_THRESHOLD)


def build_og_card() -> Image.Image:
    """Hero centered on a 1200x630 white canvas."""
    canvas = Image.new("RGB", OG_CANVAS, (255, 255, 255))
    hero = Image.open(ASSETS / "tech_birdhouse.png").convert("RGBA")
    # Scale proportionally to HERO_HEIGHT
    scale = HERO_HEIGHT / hero.height
    new_w = int(round(hero.width * scale))
    new_h = HERO_HEIGHT
    hero_resized = hero.resize((new_w, new_h), Image.LANCZOS)
    x = (OG_CANVAS[0] - new_w) // 2
    y = (OG_CANVAS[1] - new_h) // 2
    canvas.paste(hero_resized, (x, y), hero_resized)
    return canvas


def main() -> None:
    favicon_master = build_favicon_master()
    for size in FAVICON_SIZES:
        out = favicon_master.resize((size, size), Image.LANCZOS)
        out.save(ROOT / f"favicon-{size}.png", "PNG")
        print(f"wrote favicon-{size}.png")

    favicon_master.save(ROOT / "favicon.ico", sizes=ICO_SIZES)
    print(f"wrote favicon.ico ({ICO_SIZES})")

    og = build_og_card()
    og.save(ROOT / "og-card.png", "PNG", optimize=True)
    print("wrote og-card.png")


if __name__ == "__main__":
    main()
```

- [ ] **Step 4: Run the script**

Run: `python3 scripts/generate-icons.py`
Expected output: six "wrote ..." lines, no errors.

- [ ] **Step 5: Run test to verify it passes**

Run: `python3 scripts/test-generate-icons.py`
Expected: `PASS: all icon outputs valid`

- [ ] **Step 6: Visual sanity check**

Open the four key outputs in Preview / VS Code:
- `favicon-32.png` — should look like a tiny multicolor flower cluster on transparent bg.
- `favicon-512.png` — same, larger.
- `favicon.ico` — should display as the same flowers.
- `og-card.png` — the girl-on-ladder hero centered on a wide white canvas.

If the favicon crop feels off (too much phone visible, or bouquet cut at edge), tune `BOUQUET_CROP` in `scripts/generate-icons.py` and rerun. The output is the only thing that matters; iterate freely.

- [ ] **Step 7: Commit**

```bash
git add scripts/generate-icons.py scripts/test-generate-icons.py \
        og-card.png favicon-32.png favicon-180.png favicon-192.png \
        favicon-512.png favicon.ico
git commit -m "add favicon generator + new icon assets"
```

---

## Chunk 2: HTML Updates

### Task 2: Wire up `index.html`

**Files:**
- Modify: `index.html` (lines 8–9 favicon + apple-touch-icon, lines 14 + 19 OG/Twitter image refs)

- [ ] **Step 1: Replace favicon + apple-touch-icon block**

In `index.html`, find:

```html
  <link rel="icon" href="favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="og-image.png">
```

Replace with:

```html
  <link rel="icon" type="image/x-icon" href="/favicon.ico">
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
  <link rel="icon" type="image/png" sizes="192x192" href="/favicon-192.png">
  <link rel="icon" type="image/png" sizes="512x512" href="/favicon-512.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/favicon-180.png">
```

- [ ] **Step 2: Update `og:image` and `twitter:image`**

Find:
```html
  <meta property="og:image" content="https://creationship.vercel.app/og-image.png">
```
Replace with:
```html
  <meta property="og:image" content="https://creationship.vercel.app/og-card.png">
```

Find:
```html
  <meta name="twitter:image" content="https://creationship.vercel.app/og-image.png">
```
Replace with:
```html
  <meta name="twitter:image" content="https://creationship.vercel.app/og-card.png">
```

- [ ] **Step 3: Verify**

Run: `grep -nE "favicon\.svg|og-image\.png|og-vault\.png" index.html`
Expected: no matches.

Run: `grep -nE "favicon\.ico|favicon-32|favicon-180|favicon-192|favicon-512|og-card" index.html`
Expected: 7 matches (1 ico + 4 favicon sizes + apple-touch + og:image + twitter:image = 7).

### Task 3: Wire up `projects.html` and `ethics.html`

Both pages have the same `<head>` shape as `index.html` (both `og:image` and `twitter:image` already present, both pointing at `og-image.png`). Run the same three find/replaces from Task 2 against each.

**Files:**
- Modify: `projects.html`, `ethics.html`

- [ ] **Step 1: Apply Task 2 Steps 1–2 verbatim to each file**

For each of `projects.html` and `ethics.html`:
- Replace the favicon + apple-touch-icon block (Task 2 Step 1).
- Replace `og:image` with `og-card.png` URL (Task 2 Step 2, first replacement).
- Replace `twitter:image` with `og-card.png` URL (Task 2 Step 2, second replacement).

- [ ] **Step 2: Verify each file**

```bash
grep -nE "favicon\.svg|og-image\.png|og-vault\.png" projects.html ethics.html
```
Expected: no matches.

```bash
grep -nE "favicon\.ico|favicon-32|favicon-180|favicon-192|favicon-512|og-card" projects.html ethics.html
```
Expected: 7 matches per file (14 total).

### Task 3b: Wire up `ideas.html` (uses `og-vault.png`, not `og-image.png`)

`ideas.html` references `og-vault.png` in three places (the apple-touch-icon, `og:image`, and `twitter:image`). The find strings differ from Task 2 — use the explicit ones below.

**Files:**
- Modify: `ideas.html`

- [ ] **Step 1: Replace favicon + apple-touch-icon block**

Find:
```html
  <link rel="icon" href="favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="og-vault.png">
```

Replace with:
```html
  <link rel="icon" type="image/x-icon" href="/favicon.ico">
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
  <link rel="icon" type="image/png" sizes="192x192" href="/favicon-192.png">
  <link rel="icon" type="image/png" sizes="512x512" href="/favicon-512.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/favicon-180.png">
```

- [ ] **Step 2: Update `og:image`**

Find:
```html
  <meta property="og:image" content="https://creationship.vercel.app/og-vault.png">
```
Replace with:
```html
  <meta property="og:image" content="https://creationship.vercel.app/og-card.png">
```

- [ ] **Step 3: Update `twitter:image`**

Find:
```html
  <meta name="twitter:image" content="https://creationship.vercel.app/og-vault.png">
```
Replace with:
```html
  <meta name="twitter:image" content="https://creationship.vercel.app/og-card.png">
```

- [ ] **Step 4: Verify**

```bash
grep -nE "favicon\.svg|og-image\.png|og-vault\.png" ideas.html
```
Expected: no matches.

```bash
grep -nE "favicon\.ico|favicon-32|favicon-180|favicon-192|favicon-512|og-card" ideas.html
```
Expected: 7 matches.

### Task 4: Wire up `calendar.html` and `members.html` (special case)

These two pages have `og:image` but **no** `twitter:` tags at all (no `twitter:card`, no `twitter:image`). The favicon block is replaced the same way as Task 2, but a complete two-line Twitter block must be **inserted** after the `og:image` line. Without `twitter:card`, Twitter renders only a small thumbnail; we want the large card. `twitter:title` and `twitter:description` are skipped because Twitter falls back to `og:title` / `og:description` automatically.

**Files:**
- Modify: `calendar.html`, `members.html`

- [ ] **Step 1: Replace favicon + apple-touch-icon block (same as Task 2 Step 1)**

- [ ] **Step 2: Update `og:image` and insert Twitter block in one edit**

Find:
```html
  <meta property="og:image" content="https://creationship.vercel.app/og-image.png">
```
Replace with:
```html
  <meta property="og:image" content="https://creationship.vercel.app/og-card.png">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:image" content="https://creationship.vercel.app/og-card.png">
```

- [ ] **Step 3: Verify each file**

```bash
grep -nE "favicon\.svg|og-image\.png|og-vault\.png" calendar.html members.html
```
Expected: no matches.

```bash
grep -nE "favicon\.ico|favicon-32|favicon-180|favicon-192|favicon-512|og-card" calendar.html members.html
```
Expected: 7 matches per file (14 total — 5 favicon links + og:image + twitter:image).

```bash
grep -nE "twitter:card" calendar.html members.html
```
Expected: 1 match per file.

- [ ] **Step 4: Commit (after all six pages updated)**

```bash
git add index.html calendar.html projects.html ideas.html members.html ethics.html
git commit -m "switch to new favicons + og-card across all public pages"
```

---

## Chunk 3: Cleanup

### Task 5: Verify no stray references and delete old assets

**Files:**
- Delete: `favicon.svg`, `og-image.png`, `og-vault.png`

- [ ] **Step 1: Repo-wide grep for old asset names**

Run from repo root:
```bash
git grep -nE "favicon\.svg|og-image\.png|og-vault\.png" -- ':!docs/' ':!WhatsApp Chat*'
```
Expected: no matches.

If matches surface in unexpected places (e.g., `README.md`, scripts, or markdown docs), update or remove them before proceeding.

- [ ] **Step 2: Delete old assets**

```bash
git rm favicon.svg og-image.png og-vault.png
```

- [ ] **Step 3: Final verify**

```bash
ls favicon.svg og-image.png og-vault.png 2>&1
```
Expected: three "No such file or directory" errors.

```bash
ls og-card.png favicon.ico favicon-32.png favicon-180.png favicon-192.png favicon-512.png
```
Expected: all six files listed.

- [ ] **Step 4: Commit cleanup**

```bash
git commit -m "remove old favicon.svg + og-image.png + og-vault.png"
```

---

## Final Verification

- [ ] **Step 1: Open index.html in a browser and confirm tab favicon is the colorful flower cluster** (not a black square with TC).

- [ ] **Step 2: Preview the OG card** — paste the deployed URL into [opengraph.xyz](https://www.opengraph.xyz) (after pushing to Vercel) or open `og-card.png` directly. Confirm it shows the girl-with-treehouse hero centered on white.

- [ ] **Step 3: Spot-check tab favicon on at least 3 of the 6 pages** — open `index.html`, `calendar.html`, `ideas.html` in tabs and confirm all three show the new flower icon.

- [ ] **Step 4: Done.** Push when ready.

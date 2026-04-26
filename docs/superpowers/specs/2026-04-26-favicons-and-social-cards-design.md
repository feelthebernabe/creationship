# Favicons and Social Cards — Design

**Date:** 2026-04-26
**Status:** Approved by user
**Scope:** Static site at `/` (creationship.vercel.app)

## Goal

Replace the placeholder text-based favicon (`TC` on dark square) and the older OG cards (`og-image.png`, `og-vault.png`) with assets derived from the site's existing graffiti-style art:

- **Favicons** sourced from the colorful flower bouquet in `assets/phone_bouquet.png`.
- **Social card** (Open Graph + Twitter) sourced from the hero image `assets/tech_birdhouse.png` (girl building a birdhouse / treehouse out of an old CRT monitor).

## Source Images (already in repo)

- `assets/phone_bouquet.png` — graffiti-style explosion of multicolor flowers above a phone, white background. The flower bouquet portion is cropped out for the favicon.
- `assets/tech_birdhouse.png` — square (~768×768) hero image of a girl on a ladder mounting a CRT monitor (containing a pigeon nest) in a tree. White background. Already used as the home-page hero in `index.html`.

## Output Artifacts

All written to project root (alongside existing `assets/`, `styles.css`, etc.):

| File | Size | Purpose |
|---|---|---|
| `og-card.png` | 1200×630 | Open Graph + Twitter card, used site-wide |
| `favicon.ico` | multi-size 16+32+48 | Legacy browser fallback |
| `favicon-32.png` | 32×32 | Modern browser tab |
| `favicon-180.png` | 180×180 | iOS apple-touch-icon |
| `favicon-192.png` | 192×192 | Android home-screen / PWA |
| `favicon-512.png` | 512×512 | Android splash / PWA |
| `scripts/generate-icons.py` | — | Re-runnable Pillow script that produces all of the above |

**Generation script interface:** `python3 scripts/generate-icons.py` from repo root. No CLI args. Reads from `assets/phone_bouquet.png` and `assets/tech_birdhouse.png`; writes to project root. Idempotent (overwrites prior outputs). Requires Pillow (already available on the dev machine; no new install needed).

### OG card composition

- Canvas: 1200 × 630, filled with `#ffffff` (matches site `--bg`).
- Hero image (`tech_birdhouse.png`) scaled proportionally so its height = 590px (20px vertical padding top and bottom).
- Centered horizontally on the canvas. Result: square art floats on a white field with cinematic side-letterboxing.
- No text overlay. Title and description are conveyed by the page-level `og:title` / `og:description` meta tags (which platforms render alongside the card).

### Favicon composition

- Source: a tight square crop of the densest part of the bouquet in `phone_bouquet.png` (approximately the upper-center of the bouquet — see `scripts/generate-icons.py` for exact bounding box, tunable on rerun).
- Background: alpha-keyed — pixels with R, G, B all ≥ 245 are converted to fully transparent. This makes the colorful flowers float cleanly on both light and dark browser tab strips. Faint anti-aliasing speckle at 16×16 is acceptable; the colorful interior is what reads at small sizes.
- Resampled to each target size with Lanczos.

## HTML Changes

Six pages, identical `<head>` edits (admin.html intentionally skipped — internal page, not shared publicly):

1. `index.html`
2. `calendar.html`
3. `projects.html`
4. `ideas.html`
5. `members.html`
6. `ethics.html`

### Per-page edit

**Remove:**

```html
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="og-image.png">  <!-- or og-vault.png on ideas.html -->
```

**Insert in same location:**

```html
<link rel="icon" type="image/x-icon" href="/favicon.ico">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
<link rel="icon" type="image/png" sizes="192x192" href="/favicon-192.png">
<link rel="icon" type="image/png" sizes="512x512" href="/favicon-512.png">
<link rel="apple-touch-icon" sizes="180x180" href="/favicon-180.png">
```

**Update OG/Twitter image refs:**

```html
<meta property="og:image" content="https://creationship.vercel.app/og-card.png">
<meta name="twitter:image" content="https://creationship.vercel.app/og-card.png">
```

Note: `calendar.html` and `members.html` currently have `og:image` but **no `twitter:` tags at all** (no `twitter:card`, no `twitter:image`, etc.). For those two pages, insert a minimal two-line Twitter block (`twitter:card` + `twitter:image`) directly after `og:image`. `twitter:title` and `twitter:description` are skipped — Twitter falls back to `og:title` / `og:description` when those aren't set. Without `twitter:card`, Twitter would render only a small thumbnail rather than the large card; that's why the card tag is included even though it wasn't on those pages before. The other four pages already have a full Twitter block — just update `twitter:image` in place there.

(Page titles, descriptions, and other OG tags are unchanged.)

### Cleanup

After all pages are switched over and verified locally:

1. Run `git grep -nE "favicon\.svg|og-image\.png|og-vault\.png"` from the repo root and confirm zero matches outside the spec doc and the WhatsApp export folder. Catches stray references in scripts, READMEs, or markdown beyond the six HTML pages.
2. Delete:
   - `favicon.svg` (placeholder TC text icon, no longer referenced)
   - `og-image.png` (old social card, no longer referenced — confirmed by user that no shared links rely on it)
   - `og-vault.png` (old ideas-page social card, no longer referenced)

## Verification

1. Open each updated HTML file locally; confirm browser tab shows the new flower favicon.
2. Run [opengraph.xyz](https://www.opengraph.xyz/) or local link unfurl preview against each page; confirm the new OG card renders.
3. View source on each updated page; confirm:
   - No reference to `favicon.svg`, `og-image.png`, or `og-vault.png` remains.
   - All five new icon `<link>` tags present.
   - Both `og:image` and `twitter:image` point at `og-card.png`.

## Decisions Made (with rationale)

- **Transparent favicon background** rather than white square. Looks better in dark mode tab strips (Safari, Chrome dark theme); the alternative would look like a sticker. Edge speckle at 16×16 is acceptable.
- **No SVG favicon.** The source PNG has graffiti-paint texture that won't survive vectorization. The PNG/ICO set covers every modern and legacy browser.
- **One OG card site-wide** (not per-page custom cards). Kept simple; per-page distinction comes from `og:title` / `og:description`.
- **Skip admin.html.** Internal admin page, not shared, doesn't need branded social previews.
- **Keep page-level OG titles and descriptions unchanged.** Only image references move.

## Out of Scope

- Generating PWA manifest (`site.webmanifest`) — not currently in use; can be added later if PWA install is desired.
- Theme-color meta tag — separate concern.
- Per-page distinct OG cards (e.g., a different card for `ideas.html`).
- Vectorizing the favicon to SVG.

# Mobile Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Voice-first mobile redesign of the Church of Creationship site — replace the patchy 4853-line `styles.css` with a coherent ≤1500-line mobile-first stylesheet that treats illustrations as the spine of the mobile experience, while preserving the site's hand-tuned anti-corporate character.

**Architecture:** Mobile-first responsive layer with three `min-width` breakpoints (640 / 960 / 1280). Single column below 960px. Wrap-cleanly text nav (no tabs, no hamburger, no icons). Full-bleed illustrations on phone in source order. Built alongside the existing CSS as `styles.new.css`, then migrated via per-page `<link>` flips (strangler-fig pattern), then cutover.

**Tech Stack:** Hand-written HTML, CSS, vanilla JS. Supabase JS client. Vercel deployment. No build pipeline, no framework, no test runner. Verification is real-browser visual checking at three viewports (375 / 768 / 1280).

**Spec:** [`docs/superpowers/specs/2026-04-27-mobile-redesign-design.md`](../specs/2026-04-27-mobile-redesign-design.md)

---

## File Structure

| File | Status | Purpose |
|---|---|---|
| `styles.new.css` | **CREATE** | Voice-first rewrite, mobile-first, ≤1500 lines |
| `styles.css` | UNTOUCHED until cutover | Existing 4853-line stylesheet |
| `ethics.html`, `members.html`, `projects.html`, `ideas.html`, `calendar.html`, `index.html`, `admin.html` | EDIT (1 line each, at flip time) | Switch `<link href="styles.css">` → `<link href="styles.new.css">` |
| `docs/superpowers/baseline-screenshots/` | CREATE (gitignored) | Pre-rewrite screenshots for visual regression checks |

Each chunk produces self-contained changes. Chunks 1–4 build `styles.new.css` without affecting any live page (the new file isn't referenced by anything until Chunk 5). Chunk 5 migrates pages one at a time.

## Verification Pattern (used everywhere)

There is no test runner. Each task's verification step has the same shape:

1. Run `python3 -m http.server 8000` from project root (or `vercel dev` if you prefer)
2. Open the affected page at three browser widths:
   - **375px** (iPhone — Chrome/Safari devtools responsive mode)
   - **768px** (tablet)
   - **1280px** (desktop)
3. Compare against the design intent in the spec and the baseline screenshots
4. Look for: horizontal scroll (must be zero), tap targets ≥44px on mobile, body text ≥18px on mobile, hand-feel details preserved, no console errors

When a step says "verify in browser," this is what it means.

## Commit Pattern

Frequent, small commits. Each task ends in a commit. Commit messages are lowercase, present-tense, scoped to the file(s) touched:

```
mobile: add foundation tokens to styles.new.css
mobile: write mobile-first nav (wrap-cleanly)
mobile: flip ethics.html to styles.new.css
```

---

## Chunk 1: Foundation

Set up the branch, capture baseline screenshots, create `styles.new.css`, lay down tokens, reset, and layout primitives. After this chunk, the new stylesheet exists but isn't referenced by any page.

### Task 1.1: Pre-flight

**Files:**
- Create branch: `mobile-rewrite` off `main`
- Create directory: `docs/superpowers/baseline-screenshots/` (gitignored)
- Add to `.gitignore`: `docs/superpowers/baseline-screenshots/`

- [ ] **Step 1: Create branch**

```bash
cd "/Users/michelle/Vibe Projects/church of creationships"
git checkout -b mobile-rewrite
```

Expected: `Switched to a new branch 'mobile-rewrite'`

- [ ] **Step 2: Add screenshot dir to gitignore**

Append to `.gitignore`:

```
docs/superpowers/baseline-screenshots/
```

- [ ] **Step 3: Capture baseline screenshots**

Start a local server:

```bash
python3 -m http.server 8000
```

In a separate terminal/browser, open each page at each of the three widths and save a full-page screenshot to `docs/superpowers/baseline-screenshots/<page>-<width>.png`. Naming: `index-375.png`, `index-768.png`, `index-1280.png`, etc. for all 7 pages × 3 widths = 21 screenshots.

A quick way: in Chrome devtools, open responsive mode, set width, then `Cmd+Shift+P` → "Capture full size screenshot."

- [ ] **Step 4: Confirm baseline captured**

```bash
ls docs/superpowers/baseline-screenshots/ | wc -l
```

Expected: `21`

- [ ] **Step 5: Commit pre-flight**

```bash
git add .gitignore
git commit -m "mobile: gitignore baseline screenshots dir"
```

---

### Task 1.2: Create styles.new.css with header + tokens

**Files:**
- Create: `styles.new.css`

- [ ] **Step 1: Create the file with the section header structure**

Create `styles.new.css` with this skeleton — placeholder section comments only, no rules yet:

```css
/* ============================================================
   the creationship — mobile-first voice-first stylesheet
   See docs/superpowers/specs/2026-04-27-mobile-redesign-design.md
   ============================================================ */

/* ============================================================
   1. TOKENS
   ============================================================ */

/* ============================================================
   2. RESET & BASE
   ============================================================ */

/* ============================================================
   3. LAYOUT PRIMITIVES
   ============================================================ */

/* ============================================================
   4. NAV
   ============================================================ */

/* ============================================================
   5. HERO
   ============================================================ */

/* ============================================================
   6. LANDING SECTIONS
   ============================================================ */

/* ============================================================
   7. COMPONENTS
   schedule · proof · location · luma · new-here · join · buttons
   ============================================================ */

/* ============================================================
   8. HAND-FEEL DETAILS
   .swipe · .tier-strike · .proof__crown · torn-paper · pull-quotes
   ============================================================ */

/* ============================================================
   9. PAGE TAILS
   ethics · members · projects · ideas · calendar · admin
   ============================================================ */

/* ============================================================
   10. UTILITIES & ACCESSIBILITY
   ============================================================ */
```

- [ ] **Step 2: Add tokens under section 1**

Under `1. TOKENS`, add:

```css
:root {
  /* --- Color tokens (carry forward from existing styles.css :root) --- */
  /* Read from current styles.css lines ~10-50 and copy the existing color custom properties verbatim.
     These are: --bg, --paper, --text, --muted, --accent, --gold, --green, --border, --font-display, --font-body, etc.
     DO NOT redesign the palette — copy as-is. The redesign is structural, not chromatic. */

  /* --- Spacing scale (NEW) --- */
  --space-3xs: 4px;
  --space-2xs: 8px;
  --space-xs:  12px;
  --space-sm:  16px;
  --space-md:  24px;
  --space-lg:  32px;
  --space-xl:  48px;
  --space-2xl: 64px;
  --space-3xl: 96px;

  /* --- Type scale (NEW, fluid) --- */
  --text-caption: clamp(0.75rem, 0.7rem + 0.2vw, 0.85rem);
  --text-body:    clamp(1.125rem, 1rem + 0.4vw, 1.25rem);  /* 18-20px */
  --text-lead:    clamp(1.25rem, 1.1rem + 0.6vw, 1.5rem);
  --text-h3:      clamp(1.5rem, 1.3rem + 0.8vw, 2rem);
  --text-h2:      clamp(1.875rem, 1.5rem + 1.5vw, 2.75rem);
  --text-h1:      clamp(2.4rem, 1.8rem + 3vw, 4.5rem);
  --text-display: clamp(3.5rem, 2.5rem + 5vw, 6.5rem);

  /* --- Breakpoints (NEW — used in min-width media queries) --- */
  --bp-tablet:  640px;
  --bp-laptop:  960px;
  --bp-desktop: 1280px;
}
```

- [ ] **Step 3: Copy existing color tokens from old stylesheet**

```bash
grep -n "^:root" styles.css
```

Note all `:root` block start lines. Open `styles.css` in your editor and copy every `--*` custom property declaration from every `:root` block (color, font-family, any existing tokens). Paste them into `styles.new.css` under "Color tokens (carry forward...)." If the same variable is redefined across multiple `:root` blocks, take the **last** definition (CSS cascade rule).

- [ ] **Step 4: Verify the file parses**

Open `styles.new.css` directly in a browser:

```
file:///path/to/styles.new.css
```

Expected: file loads, no syntax errors. (Browser shows raw CSS text — that's fine; we're just confirming there's nothing breaking it.)

Alternative: run a CSS linter if available (`stylelint styles.new.css`). Otherwise, syntax-check by glancing for unmatched braces.

- [ ] **Step 5: Commit**

```bash
git add styles.new.css
git commit -m "mobile: scaffold styles.new.css with tokens"
```

---

### Task 1.3: Reset & base styles

**Files:**
- Modify: `styles.new.css` (section 2)

- [ ] **Step 1: Add modern reset under section 2**

```css
*, *::before, *::after {
  box-sizing: border-box;
}

html {
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
}

body {
  margin: 0;
  font-family: var(--font-body);
  font-size: var(--text-body);
  line-height: 1.55;
  color: var(--text);
  background: var(--bg);
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

main { flex: 1; }

img, svg, video {
  display: block;
  max-width: 100%;
  height: auto;
}

button { font: inherit; cursor: pointer; }
a { color: inherit; }

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-display);
  margin: 0;
  line-height: 1.15;
}

p { margin: 0 0 var(--space-sm); }
p:last-child { margin-bottom: 0; }

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

- [ ] **Step 2: Verify the body display:flex pattern matches what index.html inlines**

```bash
grep -A 3 "<style>" index.html | head -8
```

Confirm the existing `body { display: flex; flex-direction: column; min-height: 100vh; } main { flex: 1; }` rule (which lives inline in `<head>` of `index.html`) is now in our base styles. Note (do not act yet — handled at flip time): when `index.html` is flipped, we'll remove that inline `<style>` block since it's redundant.

- [ ] **Step 3: Commit**

```bash
git add styles.new.css
git commit -m "mobile: add reset & base styles"
```

---

### Task 1.4: Layout primitives

**Files:**
- Modify: `styles.new.css` (section 3)

- [ ] **Step 1: Add the container primitive**

Under `3. LAYOUT PRIMITIVES`:

```css
/* Container — text-bearing content, mobile-first comfortable line length */
.container {
  width: 100%;
  max-width: 640px;
  margin-inline: auto;
  padding-inline: var(--space-md);
}

@media (min-width: 960px) {
  .container {
    max-width: 1100px;
    padding-inline: var(--space-lg);
  }
}

/* Wide container — for hero, full-bleed sections, projects grid */
.container-wide {
  width: 100%;
  max-width: 1280px;
  margin-inline: auto;
  padding-inline: var(--space-md);
}

@media (min-width: 960px) {
  .container-wide {
    padding-inline: var(--space-xl);
  }
}

/* Full-bleed escape — used by .section-art on mobile */
.bleed {
  width: 100vw;
  margin-left:  calc(50% - 50vw);
  margin-right: calc(50% - 50vw);
}

/* Vertical rhythm between landing sections */
.landing-section {
  margin-block: var(--space-2xl);
}

@media (min-width: 960px) {
  .landing-section {
    margin-block: var(--space-3xl);
  }
}
```

- [ ] **Step 2: Confirm `.container` doesn't collide with existing markup**

```bash
grep -n 'class="[^"]*container[^"]*"' index.html calendar.html projects.html ideas.html ethics.html members.html admin.html | head -20
```

Read the output. The existing pages use `class="container"` on `<main>` and other places — that's fine, our new rule will style them. If any page uses a conflicting class name, note it but don't change markup yet.

- [ ] **Step 3: Verify the file is still well-formed**

```bash
grep -c "^[}]" styles.new.css
```

Should show a positive integer (count of closing braces). Open the file in your editor; the linter/highlighter shouldn't flag anything.

- [ ] **Step 4: Commit**

```bash
git add styles.new.css
git commit -m "mobile: add layout primitives (container, bleed, landing-section)"
```

---

## Chunk 2: Nav, Hero, Landing Sections

Build the three structures most pages depend on. After this chunk, `styles.new.css` is approximately 350-450 lines and contains everything needed to render a recognizable home page (no per-component polish yet).

### Task 2.1: Nav — wrap-cleanly mobile, unchanged desktop

**Files:**
- Modify: `styles.new.css` (section 4)

**Spec reference:** "Navigation — wrap-cleanly (mobile)" section.

- [ ] **Step 1: Read current nav markup to confirm class names**

```bash
sed -n '30,50p' index.html
```

Confirm classes: `.site-nav`, `.site-nav__inner`, `.site-nav__brand`, `.site-nav__links`, `.site-nav__link`, `.site-nav__link.active`. Don't change markup; the new CSS targets these exact selectors.

- [ ] **Step 2: Write the mobile-first nav rules**

Under `4. NAV`:

```css
/* Mobile base: brand on row 1, links wrap on row 2 */
.site-nav {
  border-bottom: 1px solid var(--border);
  background: var(--bg);
}

.site-nav__inner {
  padding: var(--space-md);
}

.site-nav__brand {
  display: block;
  font-family: var(--font-display);
  font-weight: 600;
  font-size: 1.125rem;
  text-decoration: none;
  letter-spacing: -0.01em;
  margin-bottom: var(--space-sm);
}

.site-nav__brand:hover { color: var(--accent); }

.site-nav__links {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-xs) var(--space-md);
}

.site-nav__link {
  display: inline-block;
  font-size: 0.95rem;
  text-decoration: none;
  padding: var(--space-2xs) 0;
  min-height: 44px;          /* iOS tap target */
  line-height: 1.6;
  color: var(--text);
}

.site-nav__link:hover { color: var(--accent); }
.site-nav__link.active { color: var(--accent); }

/* Desktop: brand left, links inline-right, single row */
@media (min-width: 960px) {
  .site-nav__inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    max-width: 1280px;
    margin-inline: auto;
    padding: var(--space-md) var(--space-xl);
  }
  .site-nav__brand {
    margin-bottom: 0;
  }
  .site-nav__links {
    gap: var(--space-lg);
  }
  .site-nav__link {
    min-height: auto;
    padding: var(--space-3xs) 0;
  }
}
```

- [ ] **Step 3: Manually preview the nav**

Create a one-off preview file at `.superpowers/brainstorm/nav-live-preview.html` that loads `styles.new.css` and renders just the nav markup. (Lightweight harness so we don't have to flip a real page yet.)

```html
<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link rel="stylesheet" href="../../styles.new.css">
</head><body>
<nav class="site-nav">
  <div class="site-nav__inner">
    <a href="#" class="site-nav__brand">the creationship</a>
    <div class="site-nav__links">
      <a href="#" class="site-nav__link active">home</a>
      <a href="#" class="site-nav__link">volunteer</a>
      <a href="#" class="site-nav__link">projects</a>
      <a href="#" class="site-nav__link">submit</a>
      <a href="#" class="site-nav__link">ethics</a>
    </div>
  </div>
</nav>
</body></html>
```

Open at 375px / 768px / 1280px. Expected:
- 375 + 768: brand on its own row, 5 links wrapping below with breathing room
- 1280: brand left, links right, single row

- [ ] **Step 4: Commit**

```bash
git add styles.new.css
git commit -m "mobile: write wrap-cleanly nav (mobile-first)"
```

---

### Task 2.2: Hero — mobile full-bleed, desktop two-column

**Files:**
- Modify: `styles.new.css` (section 5)

**Spec reference:** "Layout — zine on mobile" + "Images — full-bleed spine"

- [ ] **Step 1: Confirm hero markup**

```bash
sed -n '57,95p' index.html
```

Classes to target: `.hero`, `.hero__blob`, `.hero__grid`, `.hero__content`, `.hero__headline`, `.hero__headline .accent`, `.hero__subtitle`, `.hero__subtitle strong`, `.hero__cta-group`, `.hero__cta`, `.hero__scroll-link`, `.hero__meta`, `.hero__meta .dot`, `.hero__art`. No markup changes needed.

- [ ] **Step 2: Write mobile-first hero rules**

Under `5. HERO`:

```css
/* Mobile base: stacked. Headline first, then full-bleed art, then subtitle/CTAs */
.hero {
  position: relative;
  padding-top: var(--space-lg);
}

.hero__blob {
  position: absolute;
  inset: 0;
  z-index: -1;
  /* Soft gradient — copy values from old styles.css .hero__blob block, lines ~232-251 */
  /* Replace the comment with the actual rules from the old file. */
}

.hero__grid {
  display: flex;
  flex-direction: column;
  gap: var(--space-xl);
}

.hero__headline {
  font-family: var(--font-display);
  font-size: var(--text-display);
  line-height: 0.92;
  font-weight: 800;
  letter-spacing: -0.02em;
  padding-inline: var(--space-md);
}

.hero__headline .accent {
  color: var(--accent);
}

.hero__art {
  /* Full-bleed on mobile */
  width: 100vw;
  margin-left:  calc(50% - 50vw);
}

.hero__art .section-art {
  width: 100%;
  aspect-ratio: 1 / 1;
  object-fit: cover;
  display: block;
}

.hero__content {
  padding-inline: var(--space-md);
  display: flex;
  flex-direction: column;
  gap: var(--space-md);
}

.hero__subtitle {
  font-size: var(--text-lead);
  line-height: 1.5;
  color: var(--text);
}

.hero__subtitle strong { color: var(--accent); font-weight: 600; }

.hero__cta-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
  margin-top: var(--space-sm);
}

.hero__cta { /* See section 7 buttons; this is a width modifier */
  width: 100%;
  text-align: center;
}

.hero__scroll-link {
  font-size: var(--text-caption);
  color: var(--muted);
  text-decoration: none;
}

.hero__meta {
  display: flex;
  align-items: center;
  gap: var(--space-2xs);
  font-size: var(--text-caption);
  color: var(--muted);
  margin-top: var(--space-md);
}

.hero__meta .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent);
  flex-shrink: 0;
}

/* Desktop: two-column with art on the right */
@media (min-width: 960px) {
  .hero {
    padding-top: var(--space-2xl);
  }
  .hero__grid {
    display: grid;
    grid-template-columns: minmax(0, 1.1fr) minmax(0, 1fr);
    gap: var(--space-2xl);
    align-items: center;
    max-width: 1280px;
    margin-inline: auto;
    padding-inline: var(--space-xl);
    min-height: 70vh;
  }
  .hero__headline,
  .hero__content {
    padding-inline: 0;
  }
  .hero__art {
    width: 100%;
    margin-left: 0;
    max-width: 560px;
    justify-self: end;
  }
  .hero__art .section-art {
    aspect-ratio: 1 / 1;
    border-radius: 8px;
  }
  .hero__cta-group {
    flex-direction: row;
    align-items: center;
  }
  .hero__cta {
    width: auto;
  }
}
```

- [ ] **Step 3: Read the old hero__blob rule and inline its gradient values**

```bash
sed -n '232,251p' styles.css
```

Copy the gradient/blur/opacity values into the placeholder in the new `.hero__blob` rule. Don't redesign — just port.

- [ ] **Step 4: Preview by extending the live preview file**

Update `.superpowers/brainstorm/nav-live-preview.html` to include the hero markup directly under the nav. Use the existing markup from `index.html` lines 57-95 verbatim. Use a placeholder image for the hero art (e.g., a colored div with `aspect-ratio: 1/1`) since we haven't pre-loaded the assets.

Open at 375px / 768px / 1280px. Expected:
- 375: headline → full-bleed art → subtitle → stacked CTAs
- 1280: headline left, art right, two-column

- [ ] **Step 5: Commit**

```bash
git add styles.new.css
git commit -m "mobile: write hero (mobile full-bleed, desktop two-col)"
```

---

### Task 2.3: Landing section structure

**Files:**
- Modify: `styles.new.css` (section 6)

**Spec reference:** "Layout — zine on mobile"

- [ ] **Step 1: Confirm landing-section markup**

```bash
sed -n '100,120p' index.html
```

Classes: `.landing-section`, `.landing-section__label`, `.landing-section__heading`, `.landing-section__body`, `.section-grid`, `.section-grid--art-right`, `.section-grid--art-left`, `.section-grid__text`, `.section-grid__art`, `.section-art`, `.section-grid__art--sticky`. No markup changes.

- [ ] **Step 2: Write the structure rules**

Under `6. LANDING SECTIONS`:

```css
/* Mobile: stacked. .section-grid becomes a vertical flow.
   The image renders in source-order (no order: -1 hoist).
   .section-art is full-bleed via the same pattern as .hero__art. */

.landing-section__label {
  font-size: var(--text-caption);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--muted);
  margin-bottom: var(--space-sm);
}

.landing-section__heading {
  font-size: var(--text-h2);
  line-height: 1.15;
  margin-bottom: var(--space-md);
  letter-spacing: -0.01em;
}

.landing-section__body {
  font-size: var(--text-body);
  line-height: 1.65;
}

.landing-section__body p + p {
  margin-top: var(--space-md);
}

.section-grid {
  display: flex;
  flex-direction: column;
  gap: var(--space-xl);
}

/* On mobile, art is full-bleed; container padding is escaped */
.section-grid__art {
  width: 100vw;
  margin-left:  calc(50% - 50vw);
  margin-right: calc(50% - 50vw);
}

.section-art {
  width: 100%;
  aspect-ratio: 1 / 1;
  object-fit: cover;
  display: block;
}

.section-grid__text {
  /* Default: text content sits in the page container */
}

/* Desktop: two-column grids return */
@media (min-width: 960px) {
  .section-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: var(--space-2xl);
    align-items: center;
  }
  .section-grid--art-left .section-grid__art { order: 0; }
  .section-grid--art-left .section-grid__text { order: 1; }
  .section-grid--art-right .section-grid__art { order: 1; }
  .section-grid--art-right .section-grid__text { order: 0; }

  .section-grid__art {
    width: 100%;
    margin-left: 0;
    margin-right: 0;
  }
  .section-art {
    max-width: 480px;
    margin-inline: auto;
    aspect-ratio: 1 / 1;
    border-radius: 8px;
  }
  .section-grid__art--sticky {
    position: sticky;
    top: 80px;
  }
}
```

- [ ] **Step 3: Preview**

Add one landing-section block to the live-preview file (copy from `index.html` lines 100-119). Verify at 375 and 1280px.

Expected at 375: label → heading → body text → full-bleed image. No image-text-image-text monotony because each section preserves its source order independently.

Expected at 1280: two-column grid; "art-right" variant has art on right; "art-left" has art on left.

- [ ] **Step 4: Commit**

```bash
git add styles.new.css
git commit -m "mobile: write landing-section structure (single col mobile, grid desktop)"
```

---

## Chunk 3: Components & Hand-feel Details

Build out the supporting components — schedule timeline, proof cards, location card, Luma events, buttons, connection error banner, plus the hand-feel details (.swipe, .tier-strike, etc.) that give the site its character. After this chunk, the home page is fully styleable.

### Task 3.1: Schedule timeline

**Files:**
- Modify: `styles.new.css` (section 7)

**Source:** existing rules at `styles.css` ~line 749 (`/* --- Schedule Timeline --- */`).

- [ ] **Step 1: Read the existing schedule rules**

```bash
sed -n '749,810p' styles.css
```

- [ ] **Step 2: Rewrite mobile-first**

Under `7. COMPONENTS` add a `/* --- Schedule Timeline --- */` subsection. The mobile pattern: each `.schedule__item` is a single column with `.schedule__time` above `.schedule__content`. On desktop, time is left, content is right (the existing layout). Use the new spacing tokens. Keep the visual treatment (vertical rule, time prominence) but lean into mobile vertical space.

- [ ] **Step 3: Preview**

Copy the schedule markup (`index.html` ~lines 195-232) into the live-preview file. Verify at 375 and 1280.

- [ ] **Step 4: Commit**

```bash
git add styles.new.css
git commit -m "mobile: rewrite schedule timeline"
```

---

### Task 3.2: Proof / past work cards

**Files:**
- Modify: `styles.new.css` (section 7)

**Source:** existing rules at `styles.css` ~line 809 (`/* --- Proof / Past Work --- */`) and the proof crown SVG rules around line 555.

- [ ] **Step 1: Read existing proof rules** — `sed -n '809,855p' styles.css`
- [ ] **Step 2: Rewrite mobile-first.** Single column on mobile; the existing 2-3 column grid returns at `min-width: 960px`. Cards use `var(--space-md)` internal padding.
- [ ] **Step 3: Skip the `.proof__crown` rule.** Port only the card layout/positioning/typography rules. The crown SVG marker styling is handled in Task 3.7 (hand-feel details). Leave a comment placeholder: `/* .proof__crown styled in section 8 hand-feel */`.
- [ ] **Step 4: Preview** — copy proof block markup from `index.html` into the live-preview, verify 375 + 1280.
- [ ] **Step 5: Commit** — `git commit -m "mobile: rewrite proof/past-work cards"`

---

### Task 3.3: Location card / new-here / join CTA

**Files:** Modify `styles.new.css` (section 7).

**Source:** `styles.css` lines ~853-1207 (`Location`, `Next Sunday badge`, `New Here callout`, `Join CTA` blocks).

- [ ] **Step 1: Read each block in turn** with `sed`.
- [ ] **Step 2: Write each as its own subsection under `7. COMPONENTS`.** Mobile-first patterns:
  - Location card: stacked (icon/text), centered on mobile; horizontal layout at `min-width: 640px`
  - New-here callout: full-bleed `.bleed` background, internal `.container` for text, the rough/torn-paper edge survives via existing pseudo-elements
  - Join CTA: stacked, full-width buttons on mobile; inline at `min-width: 640px`
- [ ] **Step 3: Preview** each in the live-preview file at 375 and 1280.
- [ ] **Step 4: Commit** — `git commit -m "mobile: rewrite location/new-here/join blocks"`

---

### Task 3.4: Luma events list

**Files:** Modify `styles.new.css` (section 7).

**Source:** `styles.css` lines ~914-1143 (`/* --- Luma Events --- */` is the largest single component, ~230 lines).

- [ ] **Step 1: Read the existing rules** — `sed -n '914,1145p' styles.css`. There's a lot here: `.luma-events`, `.luma-events__header`, `.luma-events__label`, `.luma-events__cal-link`, `.luma-events__list`, `.luma-event`, skeleton-loader styles, `.featured-event`. Note any rules that are doing layout fixes vs. purely decorative.
- [ ] **Step 2: Identify what to keep vs. simplify.** The skeleton-loader rules are functional (loading states) — port them. The "featured-event" complex multi-row layout — simplify to single column on mobile.
- [ ] **Step 3: Write the rewrite.** Mobile pattern: each event is a vertical card with date prominent at top, title below, location/RSVP at bottom. Desktop ≥960px: optionally horizontal layout, but don't strain to make it work — single-column-with-wider-cards is also fine.
- [ ] **Step 4: Preview** at 375 + 1280. Use a static event card markup copied from `index.html` rendered output (or from the data-driven JS — read `data.js` if needed to understand the markup shape).
- [ ] **Step 5: Commit** — `git commit -m "mobile: rewrite luma events list"`

---

### Task 3.5: Buttons

**Files:** Modify `styles.new.css` (section 7).

**Source:** `styles.css` lines ~1316 onward (`/* === BUTTONS === */`).

- [ ] **Step 1: Read existing button rules** — about 60 lines.
- [ ] **Step 2: Port to new tokens.** Variants: `.btn`, `.btn--primary`, `.btn--ghost`, `.btn--gold`. On mobile, full-width by default when used inside a `.hero__cta-group` or `.cta-group`. Standalone `.btn` instances are inline-block.
- [ ] **Step 3: Tap-target audit:** every button must be ≥44px tall on mobile. Use `min-height: 44px` and adjust padding accordingly.
- [ ] **Step 4: Preview** with multiple variants in the live-preview file.
- [ ] **Step 5: Commit** — `git commit -m "mobile: rewrite buttons with mobile tap targets"`

---

### Task 3.6: Connection error banner

**Files:** Modify `styles.new.css` (section 7).

**Source:** `styles.css` line ~1925 (`/* === CONNECTION ERROR === */`).

- [ ] **Step 1: Read existing rule** — small block, ~15 lines.
- [ ] **Step 2: Port directly.** This is a fixed banner; mobile and desktop behavior is identical. Just retoken margins/padding/font-size.
- [ ] **Step 3: Commit** — `git commit -m "mobile: port connection-error banner"`

---

### Task 3.7: Hand-feel details

**Files:** Modify `styles.new.css` (section 8).

**Source:** scattered across `styles.css`. The relevant blocks:
- `.swipe` — soft underline on accent words. ~line 524.
- `.tier-strike` — strikethrough on body words. ~line 540.
- `.proof__crown` — crown SVG marker on shipped items. ~line 555.
- `.role-card` arrow → orange SVG on hover. ~line 566.
- Hero `©` strikethrough rule. ~line 600.
- `.pull-quote` — block quote treatment. (search: `grep -n "pull-quote" styles.css`)
- Torn-paper callouts on `.new-here`. (search: `grep -n "new-here" styles.css | head -5`)

- [ ] **Step 1: Locate each rule** — use the grep/search hints above to find the exact line ranges.
- [ ] **Step 2: Port each into section 8 under its own `/* --- name --- */` comment.** These rules already work; the goal is to consolidate them in one place and bump scale where appropriate for mobile (slightly thicker underline, etc.).
- [ ] **Step 3: Preview** all of these by adding sample markup to the live-preview file:
  ```html
  <p>example with <span class="swipe">swipe word</span> and <span class="tier-strike">struck word</span>.</p>
  <blockquote class="pull-quote">a pull quote feels like this.</blockquote>
  ```
- [ ] **Step 4: Verify on mobile (375px)** that each detail is visible and the underline/strikethrough thickness reads clearly.
- [ ] **Step 5: Commit** — `git commit -m "mobile: consolidate hand-feel details (.swipe, .tier-strike, .proof__crown, etc.)"`

---

## Chunk 4: Page-specific Tails

Each page has its own bespoke styles in the existing `styles.css`. Port them into section 9 of the new file, cleaning duplicates and removing rules that exist only to undo earlier ones.

### Task 4.1: ethics.html — smallest, port first

**Files:** Modify `styles.new.css` (section 9, subsection `--- ethics ---`).

- [ ] **Step 1:** Read `ethics.html` in full to identify which classes it uses beyond the shared shell (nav, container, landing-section, hand-feel).
- [ ] **Step 2:** Search `styles.css` for ethics-specific rules (`grep -n "ethics" styles.css`).
- [ ] **Step 3:** Port any unique rules. Most likely there are very few — ethics is mostly prose. If everything ethics needs is already in the shared blocks, write a `/* ethics.html — uses shared styles only */` comment in section 9 and move on.
- [ ] **Step 4: Preview** (we'll do the real test in Chunk 5 when we flip the file).
- [ ] **Step 5: Commit** — `git commit -m "mobile: port ethics.html-specific styles"`

### Task 4.2: members.html — currently hidden, low risk

**Files:** Modify `styles.new.css` (section 9, subsection `--- members ---`).

- [ ] **Step 1:** Read `members.html` fully.
- [ ] **Step 2:** Source — `styles.css` line ~4319 (`/* === MEMBER DIRECTORY === */`).
- [ ] **Step 3:** Read the entire member-directory block (~320 lines) and rewrite mobile-first. Member cards stack on mobile; grid returns at `min-width: 960px`.
- [ ] **Step 4: Preview** if practical (or defer to flip-time check).
- [ ] **Step 5: Commit** — `git commit -m "mobile: rewrite members directory"`

### Task 4.3: projects.html + project detail modal

**Files:** Modify `styles.new.css` (section 9, subsection `--- projects ---`).

- [ ] **Step 1:** Read `projects.html` and check `data.js` for the dynamic markup shape (`grep -n "innerHTML\|template" data.js | head -20`).
- [ ] **Step 2:** Source rules — `styles.css` line ~2920 (`.projects-grid`, `.project-card`, etc.) and ~3069 (`/* === PROJECT DETAIL MODAL === */`, ~430 lines).
- [ ] **Step 3:** Rewrite. Projects grid: 1 column on mobile, 2 columns at `min-width: 640px`, 3 at `min-width: 960px`. Project detail modal: full-screen on mobile (`100vw × 100vh`), centered card with backdrop on desktop. Modal close button ≥44px tap target.
- [ ] **Step 4: Commit** — `git commit -m "mobile: rewrite projects grid + project detail modal"`

### Task 4.4: ideas.html

**Files:** Modify `styles.new.css` (section 9, subsection `--- ideas ---`).

- [ ] **Step 1:** Read `ideas.html` to map its components: idea-submission form + idea-cards list.
- [ ] **Step 2:** Find existing rules — `grep -n "idea" styles.css | head -30`.
- [ ] **Step 3:** Rewrite. Form on mobile: vertically stacked, full-width inputs ≥44px tall, large submit button. Idea cards: single column mobile, optional 2-column at desktop.
- [ ] **Step 4: Commit** — `git commit -m "mobile: rewrite ideas form + cards"`

### Task 4.5: calendar.html

**Files:** Modify `styles.new.css` (section 9, subsection `--- calendar ---`).

- [ ] **Step 1:** Read `calendar.html` (largest after admin) to understand the multi-step volunteer signup flow + the week grid.
- [ ] **Step 2:** Source — `styles.css` line ~3844 (`/* === SUNDAYS CALENDAR === */`, ~470 lines).
- [ ] **Step 3:** Rewrite mobile-first. Week grid: stack each week as a vertical card on mobile (no horizontal grid below 640px); 7-day grid returns above. Signup form steps: each step is its own viewport-height-friendly card on mobile. Submit/cancel buttons are full-width on mobile, ≥44px.
- [ ] **Step 4: Commit** — `git commit -m "mobile: rewrite calendar (week grid + signup flow)"`

### Task 4.6: index.html — final pass

**Files:** Modify `styles.new.css` (section 9, subsection `--- index ---`).

- [ ] **Step 1:** Re-read `index.html` and confirm every class used is now styled by the new file. Use `grep -oE 'class="[^"]+"' index.html | tr ' ' '\n' | grep -oE '[a-z][a-z0-9_-]+' | sort -u` to extract the full class set, then `grep -F -f extracted-classes.txt styles.new.css` to confirm coverage.
- [ ] **Step 2:** Identify any unstyled classes — those go into section 9 as index-specific rules, OR are added to the shared sections if the class is used across pages.
- [ ] **Step 3: Commit** — `git commit -m "mobile: cover remaining index.html classes"`

### Task 4.7: admin.html — minimal pass

**Files:** Modify `styles.new.css` (section 9, subsection `--- admin ---`).

**Spec reference:** "admin.html mobile treatment — minimal pass." Don't fully optimize for mobile.

- [ ] **Step 1:** Source — `styles.css` line ~2532 (`/* === ADMIN DASHBOARD === */`, ~540 lines).
- [ ] **Step 2:** Port the existing admin styles wholesale into section 9 with minimal restructuring. The goals here are:
  1. No horizontal scroll at 375px — use `overflow-x: auto` on data tables if needed
  2. Tap targets ≥44px on action buttons
  3. Body text legible (≥16px)
  Don't reflow the dashboard layout. Operator uses landscape if needed.
- [ ] **Step 3: Commit** — `git commit -m "mobile: port admin styles (minimal pass per spec)"`

---

## Chunk 5: Migration & Cutover

Per-page flips in safest-first order, then cutover. Each page-flip is its own commit; if something breaks, a single revert restores that page.

### Task 5.1: Flip ethics.html

**Files:** Modify `ethics.html` line 23 (the `<link rel="stylesheet">` tag).

- [ ] **Step 1:** Confirm current link tag — `grep -n 'href="styles.css"' ethics.html`. Expected: line 23 (or similar).
- [ ] **Step 2:** Edit the file: change `href="styles.css"` to `href="styles.new.css"`.
- [ ] **Step 3:** Open `ethics.html` in a browser via `python3 -m http.server 8000`. Check at 375 / 768 / 1280. Compare against `docs/superpowers/baseline-screenshots/ethics-{375,768,1280}.png`.
- [ ] **Step 4:** Verify: no horizontal scroll, body text ≥18px, hand-feel details intact, no console errors.
- [ ] **Step 5:** If anything looks off, fix in `styles.new.css` (don't revert the flip), re-verify, commit the fix as a follow-up.
- [ ] **Step 6: Commit** — `git commit -m "mobile: flip ethics.html to styles.new.css"`

### Task 5.2: Flip members.html

`members.html` is currently hidden from nav (per project memory), so this is the safest real-page test before larger pages.

- [ ] **Step 1:** Confirm current link tag — `grep -n 'href="styles.css"' members.html`.
- [ ] **Step 2:** Edit: change `href="styles.css"` to `href="styles.new.css"`.
- [ ] **Step 3:** Open `members.html` at 375 / 768 / 1280. Compare against baseline screenshots.
- [ ] **Step 4:** Verify member cards stack cleanly on mobile (single column), reflow to grid at ≥960px. Member avatar/photo sizes legible.
- [ ] **Step 5:** Fix in `styles.new.css` if needed; re-verify.
- [ ] **Step 6: Commit** — `git commit -m "mobile: flip members.html to styles.new.css"`

### Task 5.3: Flip projects.html

- [ ] **Step 1:** Confirm current link tag.
- [ ] **Step 2:** Change `href="styles.css"` to `href="styles.new.css"`.
- [ ] **Step 3:** Open at 375 / 768 / 1280. Compare against baseline.
- [ ] **Step 4:** Verify projects grid: 1 col @ 375, 2 cols @ 768, 3 cols @ 1280. Tap a project to open the detail modal — confirm full-screen on mobile, centered card on desktop. Modal close button ≥44px tap target.
- [ ] **Step 5:** Fix in `styles.new.css` if needed.
- [ ] **Step 6: Commit** — `git commit -m "mobile: flip projects.html to styles.new.css"`

### Task 5.4: Flip ideas.html

- [ ] **Step 1:** Confirm current link tag.
- [ ] **Step 2:** Change `href="styles.css"` to `href="styles.new.css"`.
- [ ] **Step 3:** Open at 375 / 768 / 1280. Compare against baseline.
- [ ] **Step 4:** Verify the submission form on mobile: every input ≥44px tall, labels readable, submit button full-width and ≥44px. Idea cards list stacks cleanly.
- [ ] **Step 5:** Try submitting a test idea on a 375px-wide window — confirm the flow completes without horizontal scroll.
- [ ] **Step 6:** Fix in `styles.new.css` if needed.
- [ ] **Step 7: Commit** — `git commit -m "mobile: flip ideas.html to styles.new.css"`

### Task 5.5: Flip calendar.html

This is the most behaviorally complex page — multi-step volunteer signup flow.

- [ ] **Step 1:** Confirm current link tag.
- [ ] **Step 2:** Change `href="styles.css"` to `href="styles.new.css"`.
- [ ] **Step 3:** Open at 375 / 768 / 1280. Compare against baseline.
- [ ] **Step 4:** Verify week grid stacks vertically on mobile (each week is a card, not a 7-col grid). Returns to a grid at ≥640px.
- [ ] **Step 5: End-to-end signup test at 375px:** click an open slot → fill the form → submit → receive confirmation → use the cancel-by-token form to cancel. The whole flow should be completable on a phone-width window without horizontal scroll. (Note from project memory: the cancel-by-clickable-link in emails is broken; the cancel-by-token-paste form on calendar.html is the working primary path — that's what this step tests.)
- [ ] **Step 6:** Fix in `styles.new.css` if needed.
- [ ] **Step 7: Commit** — `git commit -m "mobile: flip calendar.html to styles.new.css"`

### Task 5.6: Flip index.html

Highest-risk page — most complex layout, 5 hero illustrations, all the hand-feel details.

- [ ] **Step 1:** Confirm current link tag location.
- [ ] **Step 2:** Change `href="styles.css"` to `href="styles.new.css"`.
- [ ] **Step 3:** Remove the inline `<style>` block at lines ~24-27 of `index.html` (it duplicates rules now in `styles.new.css`).
- [ ] **Step 4:** Open at 375 / 768 / 1280. Walk the entire page top-to-bottom at each width. Critical checks:
  - Hero: full-bleed art on mobile, two-column on desktop
  - All 5 illustrations are full-bleed on mobile, source-order in stack
  - Schedule timeline: stacked on mobile, time+content side-by-side on desktop
  - Pull-quote, swipe underlines, strikethroughs all present
  - Luma events render cleanly
  - Location card, new-here, join CTA all functional
- [ ] **Step 5:** Fix any issues in `styles.new.css`.
- [ ] **Step 6: Commit** — `git commit -m "mobile: flip index.html to styles.new.css"`

### Task 5.7: Flip admin.html

Lowest-priority page (desktop-only in practice, minimal pass per spec).

- [ ] **Step 1:** Confirm current link tag.
- [ ] **Step 2:** Change `href="styles.css"` to `href="styles.new.css"`.
- [ ] **Step 3:** Open at 375 / 768 / 1280.
- [ ] **Step 4:** Verify desktop (1280) is functionally identical to the baseline — the operator's primary use case. Tables, forms, action buttons all work as before.
- [ ] **Step 5:** Verify mobile (375) has no horizontal scroll, action buttons are tappable. Don't expect the dashboard layout to feel polished on phone — that's intentionally out of scope.
- [ ] **Step 6:** Fix in `styles.new.css` if needed.
- [ ] **Step 7: Commit** — `git commit -m "mobile: flip admin.html to styles.new.css"`

### Task 5.8: Cutover

After all 7 pages have been flipped and visually verified, do the rename.

- [ ] **Step 1:** Sanity check — `grep -rn 'styles.css' *.html`. Expected: zero matches (every page now references `styles.new.css`).
- [ ] **Step 2:** Delete the old file:

```bash
git rm styles.css
```

- [ ] **Step 3:** Rename:

```bash
git mv styles.new.css styles.css
```

- [ ] **Step 4:** Update every HTML file's `<link>` tag back to `styles.css`. Use a single replace-across-files approach:

```bash
sed -i '' 's|href="styles.new.css"|href="styles.css"|g' *.html
```

(Verify on macOS — the `-i ''` arg is correct for BSD sed. If on Linux, use `sed -i 's/.../.../g'` without the empty quotes.)

- [ ] **Step 5:** Verify — `grep -rn 'styles.new.css' *.html`. Expected: zero matches.
- [ ] **Step 6:** Open every page once more at 375 / 768 / 1280 to confirm nothing changed (the rename should be transparent).
- [ ] **Step 7: Commit** — `git commit -m "mobile: cutover — rename styles.new.css → styles.css, delete old"`

### Task 5.9: Final verification + PR

- [ ] **Step 1: Audit success criteria from the spec.** Walk every item in the spec's `## Success criteria` section against the current state. Each should be ✓.

- [ ] **Step 2: Final line count check** — `wc -l styles.css`. Expected: ≤1500.

If the count overruns, trim from the **rewritten components** (Chunk 3 sections — schedule, proof, Luma events, location, new-here, hand-feel) — those are the sections where rewrite gains compress most easily. Do **not** trim `admin.html` styles to hit the budget; the spec locks admin at minimal-pass and shrinking it would reflow the dashboard, which is explicitly out of scope.

If after trimming Chunk 3 you're still over budget, that's a signal to revisit the spec's ≤1500 target rather than over-compress. The spec frames the line count as design intent, not a hard pass/fail bar.

- [ ] **Step 3: Final selector audit** — confirm no orphan rules remain:

```bash
# Pull all class names referenced in HTML
grep -ohE 'class="[^"]+"' *.html | tr ' ' '\n' | grep -oE '[a-z][a-z0-9_-]+' | sort -u > /tmp/used-classes.txt
# Pull all class selectors defined in CSS
grep -oE '^\.[a-zA-Z][a-zA-Z0-9_-]+' styles.css | sed 's/^\.//' | sort -u > /tmp/defined-classes.txt
# Defined but never used:
comm -23 /tmp/defined-classes.txt /tmp/used-classes.txt > /tmp/orphans.txt
wc -l /tmp/orphans.txt
```

Expected: a small handful of orphans (state classes set by JS, pseudo-class targets, etc.). Skim the list; remove obvious unused selectors.

- [ ] **Step 4: Push branch and open PR**

```bash
git push -u origin mobile-rewrite
gh pr create --title "mobile redesign — voice-first responsive rewrite" --body "$(cat <<'EOF'
## Summary
- Replaces the patchy 4853-line `styles.css` with a coherent ≤1500-line mobile-first stylesheet
- Wrap-cleanly text nav on mobile (no tabs, no hamburger, no icons)
- Full-bleed illustrations on phone, source-order in stack
- Single column below 960px; desktop layout preserved at ≥960px
- Hand-feel details (swipe underlines, strikethroughs, torn-paper, proof crowns) survive
- Strangler-fig migration: per-page flips, then cutover

## Test plan
- [ ] All 7 pages render legibly at 375px / 768px / 1280px (compare against baseline screenshots)
- [ ] Calendar volunteer-signup flow completable on a 375px-wide phone end-to-end
- [ ] Projects detail modal opens/closes cleanly at all widths
- [ ] Ideas form submittable on mobile
- [ ] No horizontal scroll on any page at 375px
- [ ] No console errors on any page

## Spec
[`docs/superpowers/specs/2026-04-27-mobile-redesign-design.md`](docs/superpowers/specs/2026-04-27-mobile-redesign-design.md)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 5:** Return PR URL to operator for review.

---

## Out of Scope (Per Spec)

These are deferred and NOT to be done in this plan:

- **WebP image conversion** — separate follow-up commit after this ships. The 5 hero PNGs (~500KB-1MB each) become ~80% smaller as WebP. Non-blocking perf win.
- **Per-page CSS file split** — `admin.css`, `calendar.css`, etc. as separate files. Possible later refactor if maintenance cost justifies.
- **Token-based design system documentation, Storybook, design-system docs.**
- **JavaScript behavior changes.**
- **New page templates, sections, or content.**
- **Color palette or font-family changes.**

---

## Execution Notes

- **One operator, one machine.** Plan is written so a single person (or a single Claude session) can execute end-to-end.
- **Branch lives until PR merge.** Don't push to `main` directly.
- **Per-task commits.** Frequent commits make any regression a small revert.
- **Browser-tab warning:** when previewing `styles.new.css` files, hard-refresh (Cmd+Shift+R) to bust the CSS cache between iterations.

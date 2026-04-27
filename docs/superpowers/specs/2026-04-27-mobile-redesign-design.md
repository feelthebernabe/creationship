# Mobile Redesign — Design

**Date:** 2026-04-27
**Status:** Approved by user
**Scope:** All 7 pages of `creationship.vercel.app` — `index.html`, `calendar.html`, `projects.html`, `ideas.html`, `members.html`, `ethics.html`, `admin.html`. Single shared stylesheet at `styles.css`.

## Goal

Optimize the site for mobile while preserving — and amplifying — its hand-tuned, anti-corporate, zine-like character.

The current `styles.css` (4853 lines) has 16 scattered `@media` queries at four inconsistent breakpoints (480, 600, 640, 768 px). Coverage is partial: the user reports nav cramping, hero spillover, awkward forms, tap targets too small, horizontal scroll, image sizing wrong, and image position-in-stack feeling monotonous. The site currently renders the desktop layout on phones with patchy, accumulated overrides.

The design replaces this with a coherent mobile-first responsive layer, treats the site's illustrations as the structural spine on phone, and shrinks the stylesheet to roughly 1200 lines of voice-first CSS.

## Non-goals

- **Not** a token-based design system. The site has one operator and seven pages; tokens for color and spacing exist where they earn their keep, but components stay bespoke where character matters.
- **Not** a content rewrite. Markup changes are limited to what the new responsive layer needs.
- **Not** a JavaScript redesign. Behaviour stays identical; only layout, typography, and image treatment change.
- **Not** a per-page CSS split. One stylesheet keeps editing simple for a single operator.

## Voice-first principles

These guide every choice below:

1. **Conventional patterns are not free.** Bottom tab bars, hamburger menus, and 8-step token systems make sites feel like Stripe. This site is the back room of a vegan restaurant; convention drains its asset.
2. **Illustrations are content, not decoration.** They carry the philosophy. On mobile, they become the spine — full-bleed moments between text blocks, sized per their actual aspect ratio.
3. **Hand-feel details get bigger on mobile, not smaller.** The strikethrough copyright marks (`.tier-strike`), swipe underlines (`.swipe`), torn-paper callouts, and proof crowns must survive — even feel more present — on phone.
4. **Text rhythm is intimate.** Phones are read close. Body text is 18–19px (up from ~16), generous vertical whitespace, single column always below 960px.

## Foundation: tokens & breakpoints

### Existing color tokens
Stay as-is in `:root`. Already named clearly; not the source of mess.

### Spacing scale (additions)
A small t-shirt-sized scale, used wherever the value is shared across components. Bespoke values remain acceptable for components with character.

```css
--space-3xs: 4px;   --space-md:  24px;  --space-2xl: 64px;
--space-2xs: 8px;   --space-lg:  32px;  --space-3xl: 96px;
--space-xs:  12px;  --space-xl:  48px;
--space-sm:  16px;
```

### Type scale (additions)
Fluid `clamp()` per step. Phones get one size, desktops another, smooth between.

```css
--text-caption: clamp(0.75rem, 0.7rem + 0.2vw, 0.85rem);
--text-body:    clamp(1.125rem, 1rem + 0.4vw, 1.25rem);  /* 18–20px */
--text-lead:    clamp(1.25rem, 1.1rem + 0.6vw, 1.5rem);
--text-h3:      clamp(1.5rem, 1.3rem + 0.8vw, 2rem);
--text-h2:      clamp(1.875rem, 1.5rem + 1.5vw, 2.75rem);
--text-h1:      clamp(2.4rem, 1.8rem + 3vw, 4.5rem);
--text-display: clamp(3.5rem, 2.5rem + 5vw, 6.5rem);
```

The current hero `clamp(3.5rem, 9vw, 6.5rem)` already uses this idiom; the design generalises it.

### Breakpoints (mobile-first, replaces today's mixed set)
```css
--bp-tablet:  640px;
--bp-laptop:  960px;
--bp-desktop: 1280px;
```

Only three. Used as `min-width` queries. Mobile (≤640px) is the **base style**, no media query required. Tablet and desktop are **enhancements** layered on top. The current four-breakpoint mix (480, 600, 640, 768) collapses into three consistent `min-width` checks.

## Layout — "zine on mobile"

- **Single column always below 960px.** No multi-column grids on phone or small tablet.
- **Container max-width: 640px** for text-bearing sections on mobile, with horizontal padding `var(--space-md)` (24px). Comfortable line lengths.
- **Body font-size: 18–20px** (`--text-body` clamp) on phone — up from current 16px.
- **Vertical rhythm:** every landing section has `--space-2xl` (64px) of breathing space above and below.
- **Desktop layout unchanged** at ≥960px: the existing two-column hero and `.section-grid` structures stay intact.

## Navigation — wrap-cleanly (mobile)

The desktop top-nav stays. On mobile (`max-width: 640px` equivalent), it wraps cleanly:

- Brand on its own row, top-left.
- The 5 links (`home`, `volunteer`, `projects`, `submit`, `ethics`) wrap below as a flex-wrap row with `gap: var(--space-sm) var(--space-md)`.
- Active link uses the existing accent color treatment.
- Tap targets at least 44×44px.
- No hamburger, no bottom tab bar, no icons. The nav is text-only and quiet — same voice as the rest of the site.

The CSS comment at the existing nav block (`/* Navigation — quiet, text-only */`) becomes truthful on mobile, not just desktop.

## Images — full-bleed spine

The five hero illustrations on `index.html` (`tech_birdhouse.png`, `planting_phones.png`, `phone_bouquet_vertical.png`, `vr_flowers.png`, `feeding_pigeons.png`) and any future `.section-art` instances follow this treatment on mobile:

- **Width: 100vw**, breaking out of the container with `margin-left: calc(50% - 50vw); margin-right: calc(50% - 50vw);`. Edge to edge.
- **`aspect-ratio: 1 / 1`** on mobile. All five source assets are 1024×1024 squares — the "vertical" suffix on `phone_bouquet_vertical.png` describes the subject's orientation within the square frame, not the asset's dimensions. Displaying at 1:1 trusts the artwork. If a specific image's subject feels off-frame at phone width, that's an asset-level reframing in `assets/`, not a CSS crop.
- **`object-fit: cover`** for safety in case any future asset deviates from 1:1.
- **Position in stack:** the universal `order: -1` rule (which currently hoists every mobile image above its text, creating image-text-image-text monotony) is dropped. Images appear in source order on mobile, matching the desktop intent for that section.

| Image | Source dimensions | Mobile display | Subject placement |
|---|---|---|---|
| `tech_birdhouse.png` | 1024×1024 | 1:1, full-bleed | Centered |
| `planting_phones.png` | 1024×1024 | 1:1, full-bleed | Centered |
| `phone_bouquet_vertical.png` | 1024×1024 | 1:1, full-bleed | Centered (subject is vertical within frame) |
| `vr_flowers.png` | 1024×1024 | 1:1, full-bleed | Centered |
| `feeding_pigeons.png` | 1024×1024 | 1:1, full-bleed | Centered |

### Image perf — optional WebP conversion
The current PNGs are 500KB–1MB each. Converting to WebP yields ~80% file-size reduction with no visible quality loss. Implementation: `<picture>` elements with `<source type="image/webp">` and a PNG fallback. Generation script alongside `scripts/generate-icons.py`.

This is a separate cheap win and may be sequenced after the layout work.

## CSS rewrite — voice-first, ~1200 lines

Target end state for `styles.css`: roughly 1200 lines (down from 4853), in a single file.

### Keep
- Existing color tokens
- Hand-drawn details: `.swipe`, `.tier-strike`, `.proof__crown`, torn-paper callout effects, the new-here block
- Section structure and BEM-ish naming (`.landing-section__heading`, `.section-grid__art`, `.hero__cta`, etc.)
- The behavioural CSS that drives `.reveal`, parallax, scroll-driven micro-interactions
- Page-specific styles for admin, calendar, members, ideas — each becomes a clearly-marked section

### Remove
- Legacy `.ambient-art` block (line 418)
- Duplicate `@media (max-width: 768px)` and `@media (max-width: 640px)` blocks consolidated into the new mobile-first structure
- Page-specific styles that exist solely to undo earlier rules
- The orphaned "UX REDESIGN — NEW COMPONENTS" block; merge into the components it describes
- Unused selectors (audited via grep against all HTML pages before deletion)

### Reorganise (top → bottom)
1. Tokens (color + new spacing + new type + new breakpoints)
2. Reset & base
3. Layout primitives (container, stack rhythm)
4. Nav
5. Hero
6. Landing sections (structure + variants)
7. Component blocks: schedule, proof, location, luma events, new-here, join CTA, buttons, modals
8. Page-specific tails: admin, calendar, members, ideas, ethics
9. Utilities (visually-hidden, screen-reader-only)
10. Print & reduced-motion overrides

Each section gets a comment header. No more append-only growth.

## Migration — strangler-fig

Ship without breaking the live site. At every checkpoint, both old and new are intact.

1. **Branch.** `mobile-rewrite` off `main`. Don't touch `main` directly.
2. **Build alongside.** Write the new CSS as `styles.new.css` in the project root. Each HTML page can be flipped to the new stylesheet by changing one `<link>` tag.
3. **Page flip order** (smallest/simplest first → biggest/most complex last):
   1. `ethics.html` (smallest, mostly prose)
   2. `members.html` (currently hidden — safest test bed)
   3. `projects.html` (no inline images; dynamic content)
   4. `ideas.html` (form + idea cards)
   5. `calendar.html` (multi-step form, week grid)
   6. `index.html` (hero + 5 illustrations + complex grid)
   7. `admin.html` (largest single block of bespoke styles; lowest visibility risk since only Michelle uses it)
4. **Per-page commit.** Each flip is its own commit. Regressions have a small surface area; a single revert restores the prior page.
5. **Visual regression check at each flip.** Open desktop (1440px), tablet (768px), phone (375px); eyeball; fix. Real browser, not just emulator.
6. **Cutover.** When all pages are on `styles.new.css`: delete `styles.css`, rename `styles.new.css` → `styles.css`, single-line edit across all pages, single commit. PR to `main`.

## Out of scope (explicitly deferred)

- Per-page CSS file split (`admin.css`, `calendar.css`, etc.) — possible follow-up, not bundled with this work.
- Adding a token-based design system (color tokens beyond what already exists, design-system documentation, Storybook, etc.).
- Reworking JavaScript behaviour or state management.
- New page templates, new sections, or content additions.
- Changing the existing accent colors or font families.

## Resolved decisions

- **WebP conversion** — **deferred** to a follow-up commit after the layout work ships. Layout is the user-visible win; perf is invisible-but-real and can land independently without coordinating with the rewrite.
- **`admin.html` mobile treatment** — **minimal pass.** Make it not-broken at phone width (no horizontal scroll, tap targets ≥44px, legible text), but do not optimise dashboard tables, modals, or multi-column controls for thumb-scrolling. The operator uses admin on desktop; landscape on a phone is an acceptable fallback for occasional checks. This means `admin.html` is the lightest-touch page in the rewrite — its bespoke ~540 lines mostly stay structurally intact, with only the responsive patches needed to satisfy the success criteria.

## Success criteria

The redesign is done when:

- All 7 pages render legibly on a 375px-wide phone with no horizontal scroll, tap targets ≥44px, body text ≥18px.
- The 5 hero illustrations on `index.html` are full-width on mobile, each at its correct aspect ratio.
- The mobile nav wraps cleanly, brand on row 1, links on row 2 — no cramped wrap, no hamburger.
- `styles.css` is meaningfully smaller (target: ≤1500 lines, down from 4853), top-down organised, with no `Legacy` or "NEW COMPONENTS" headers. Exact line count is design intent, not a hard pass/fail bar.
- The desktop experience at ≥960px is visually unchanged (regression-free).
- Hand-feel details (swipe underlines, strikethroughs, torn-paper callouts, proof crowns) are visible and functional on both mobile and desktop.

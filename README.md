# the creationship

a weekly create-a-thon for moral imagination.  
part weekly ritual, part build session — a place to create things that matter, irl together.  
sundays at caravan of dreams, east village.

**live:** [creationship.vercel.app](https://creationship.vercel.app)  
**source:** [github.com/feelthebernabe/creationship](https://github.com/feelthebernabe/creationship)

---

## what this is

the creationship is a signup, coordination, and idea-tracking system for a weekly sunday gathering of builders, makers, and thinkers in nyc. it's run as a static site backed by supabase.

## pages

| page | url | purpose |
|------|-----|---------|
| **home** | `/index.html` | landing page with manifesto, schedule, role signup, and collaborative soundscape |
| **the vault** | `/ideas.html` | magic-link-authenticated idea repository — seed → project → company pipeline |
| **core team** | `/admin.html` | password-gated admin dashboard for managing signups, calendar, and people |

## tech stack

- **frontend:** vanilla html/css/js — no framework, no build step
- **data:** [supabase](https://supabase.com) (postgresql + auth + RLS)
- **hosting:** [vercel](https://vercel.com) — static deploy
- **analytics:** vercel web analytics (`/_vercel/insights/script.js`)
- **fonts:** inter (display + body)
- **design:** two-register system — editorial sans-serif base + Basquiat-inspired painterly hero (hand-drawn scrawls, crown, paint swipes, struck-through ©s)

## supabase tables

| table | purpose | auth |
|-------|---------|------|
| `people` | contact directory | anon (public write) |
| `role_signups` | hold space / teach / brain trust signups | anon |
| `sundays` | calendar + session metadata | anon |
| `invitations` | community gating tokens | anon |
| `ideas` | the vault — idea pipeline | **authenticated** (magic link) |
| `playlist_suggestions` | soundscape song suggestions | anon |

## key features

### landing page
- Basquiat-inspired full-bleed hero — hand-drawn painterly composition: scattered scrawled phrases (some struck through), crown above headline, orange paint swipe behind CREATE-A-THON, three rough-edged color blocks, chrome iridescent sweep + cyan spotlight + violet pool for dream-chamber atmosphere
- "the premise" — narrative explaining creationships, with strikethroughs on the things this isn't (e.g. "~~solo builders~~ or ~~siloed disciplines~~")
- three currents: new tech · forever human · the bridge (`data-accordion` → collapses on mobile ≤640px)
- sunday schedule timeline
- proof section — past projects with a crown SVG marking shipped items
- location card with next-sunday countdown
- role signup flow (hold space / teach / brain trust) — hover swaps text "→" for the hero's orange arrow SVG
- "new here?" callout with rough-edge torn-paper clip-path

### collaborative soundscape
- embedded spotify playlist
- two paths: add directly on spotify, or suggest a song via form
- community suggestions feed with real-time rendering

### the vault (ideas)
- magic link authentication (supabase auth OTP)
- idea lifecycle: seed → project → company
- stage pipeline visualization with filtering
- per-idea: title, description, links (github/demo/other), team members, company name
- edit/delete your own ideas, read everyone's
- search and filter

### admin dashboard
- sha-256 hashed password gate (no plaintext in source)
- stats overview (total signups, by role, by status)
- signup management with expand/collapse detail views
- status updates (pending → approved/declined) with admin notes
- calendar view for sunday scheduling
- people directory
- data export (json)

## sql migrations

run these in the supabase sql editor in order:

1. `supabase-migration.sql` — core tables (people, role_signups, sundays, invitations)
2. `ideas-migration.sql` — ideas table + RLS
3. `ideas-v2-migration.sql` — adds github_url, website_url, demo_url, team_members (jsonb)
4. `ideas-v3-migration.sql` — adds stage (seed/project/company) + company_name
5. `playlist-migration.sql` — playlist_suggestions table
6. `rls-tighten-migration.sql` — tighten row-level security policies

## auth setup

for the vault (magic link login) to work, configure in supabase dashboard:

- **authentication → url configuration:**
  - site url: `https://creationship.vercel.app`
  - redirect urls: `https://creationship.vercel.app/ideas.html`

## local development

no build step. just open `index.html` in a browser, or:

```bash
npx serve .
```

supabase calls will work from any origin since the anon key is configured for public access.

## deploy

```bash
vercel --prod
```

## project structure

```
├── index.html              # landing page + signup + soundscape (includes vercel analytics)
├── ideas.html              # the vault — authenticated idea board
├── admin.html              # core team dashboard
├── styles.css              # full design system
├── data.js                 # supabase client + all CRUD operations
├── logo.png                # mandala logo
├── favicon.svg             # svg favicon
├── og-image.png            # open graph image (home)
├── og-vault.png            # open graph image (vault)
├── supabase-migration.sql  # core schema
├── ideas-migration.sql     # ideas table
├── ideas-v2-migration.sql  # ideas v2
├── ideas-v3-migration.sql  # ideas v3
├── playlist-migration.sql  # playlist suggestions
├── rls-tighten-migration.sql # security policies
└── .vercelignore           # excludes private data + dev tooling from deploys
```

## design system

Two registers stacked.

**1. Editorial base** — bold Inter sans-serif, high contrast, light chrome with saturated accent hits. Inspired by editorial agency sites (Goat Agency, Red Antler).

**2. Basquiat-inspired hero + accents** — the landing hero is a hand-drawn painterly composition with scattered scrawled phrases (some struck through with heavy ink bars), crown iconography, orange "paint swipe" behind key headline words, ©  marks, tally strokes, and three rough-edged paint blocks. Chrome/dream-chamber atmospheric layers sit on top: cyan spotlight beam, violet pool, iridescent sweep. The Basquiat language threads quietly through the rest of the landing page — eyebrow labels with appended marks (tally / struck © / orange underline), section h2s with paint swipes on key words, and selective body strikethroughs.

**Site rule:** every © is struck through wherever it appears (hero, eyebrow labels, future ©s). Implemented via `text-decoration: line-through` with `text-decoration-skip-ink: none` so the strike runs straight across the glyph.

**SVG filter `#rough-edge`** is defined once at the top of the landing section in [index.html](index.html) — referenced by paint blocks and headline swipes for that hand-painted edge displacement.

| token | value | usage |
|-------|-------|-------|
| `--bg` | `#f2f2f2` | page background, hero canvas |
| `--bg-dark` | `#0a0a0a` | hero ink, nav, footer, dark cards |
| `--accent` | `#b8ff72` | neon lime — CTAs, highlights, hero paint block |
| `--bg-accent` | `#ff4b1f` | orange-red — section accents, paint swipe, hero arrow |
| `--accent-reflect` | `#7a2dff` | plasma purple — reflective/contemplative moments, hero paint block |
| `--font` | Inter (300–900) | all typography |

## accessibility

- `prefers-reduced-motion` media query disables all animations and marquee scroll
- semantic html with proper heading hierarchy (`h1` → `h2` → `h3`)
- scroll-margin-top on all `[id]` elements for sticky nav offset
- `IntersectionObserver` reveal animations respect reduced motion

## seo

- open graph + twitter card meta tags on `index.html` and `ideas.html`
- `favicon.svg` + `og-image.png` + `og-vault.png` assets
- descriptive `<title>` and `<meta name="description">` per page
- semantic html5 structure throughout

## next steps

- [ ] custom domain setup (e.g. `creationship.co`)
- [ ] email notifications for new signups (resend or supabase edge functions)
- [ ] invitation token enforcement (`/join?token=`)
- [ ] supabase auth for admin (replace client-side hashed password gate)
- [ ] playlist suggestion moderation in admin dashboard
- [ ] og-image auto generation per idea in the vault

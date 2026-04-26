# the creationship

a weekly create-a-thon for moral imagination.  
part weekly ritual, part build session — a place to create things that matter, irl together.  
sundays at caravan of dreams, east village.

**live:** [creationship.vercel.app](https://creationship.vercel.app)  
**source:** [github.com/feelthebernabe/creationship](https://github.com/feelthebernabe/creationship)

---

## what this is

the creationship is a signup, coordination, and idea-tracking system for a weekly sunday gathering of builders, makers, and thinkers in nyc. it's run as a static site backed by supabase, with a few thin vercel serverless functions for AI-assisted project extraction.

## pages

| page | url | purpose |
|------|-----|---------|
| **home** | `/index.html` | landing with manifesto, schedule, role signup, soundscape |
| **sundays** | `/calendar.html` | member sign-up calendar — claim teach/MC, mint invite codes, edit topic |
| **members** | `/members.html` | public directory of approved members |
| **projects** | `/projects.html` | public showcase of community work with per-project detail modal and shareable permalink URLs |
| **creations** | `/ideas.html` | magic-link-authenticated submit + edit page (formerly "the vault") — seed → project → company pipeline; includes "paste anything" extract panel and full edit modal |
| **core team** | `/admin.html` | password-gated admin dashboard for signups, calendar, members, invitations, bulk-paste import |

## tech stack

- **frontend:** vanilla html/css/js — no framework, no build step
- **data:** [supabase](https://supabase.com) (postgres + auth + RLS)
- **hosting:** [vercel](https://vercel.com) — static deploy + 3 serverless functions under `/api/`
- **AI:** [anthropic claude](https://anthropic.com) — haiku 4.5 for single-project extraction, sonnet 4.6 (with prompt caching) for bulk WhatsApp parsing
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
| `ideas` | submitted creations + public projects showcase — pipeline + `display_name` + `slug` for sharing | **authenticated** writes, anon reads |
| `invitations` + `invitation_redemptions` | invite codes (master + per-member referrals); ledger tracks multi-use redemptions | service role for mutations; anon read of own |
| `playlist_suggestions` | soundscape song suggestions | anon |

## key features

### landing page
- Basquiat-inspired full-bleed hero — hand-drawn painterly composition: scattered scrawled phrases (some struck through), crown above headline, orange paint swipe behind CREATE-A-THON, three rough-edged color blocks, chrome iridescent sweep + cyan spotlight + violet pool for dream-chamber atmosphere
- "the premise" — narrative explaining creationships, with strikethroughs on the things this isn't (e.g. "~~solo builders~~ or ~~siloed disciplines~~")
- three currents: new tech · forever human · the bridge (`data-accordion` → collapses on mobile ≤640px)
- sunday schedule timeline
- proof section — past projects with a crown SVG marking shipped items, links out to `/projects.html` for the full gallery
- location card with next-sunday countdown
- role signup flow (hold space / teach / brain trust) — hover swaps text "→" for the hero's orange arrow SVG
- "new here?" callout with rough-edge torn-paper clip-path

### projects showcase (public)
- responsive grid of all `status='active'` ideas, grouped by stage (companies / projects / seeds)
- click any card → detail modal with bigger layout, labeled site / code / demo link pills, team chips
- per-project permalink URLs: `/projects.html?p=<slug>` — back button works, deep links auto-open the matching modal on load
- share actions in modal footer: copy link + tweet intent (no oauth flow, just `twitter.com/intent/tweet`)
- privacy default: contributors render as `display_name` (typically "First L." initials); `author_name` keeps the full name as record-of-truth

### collaborative soundscape
- embedded spotify playlist
- two paths: add directly on spotify, or suggest a song via form
- community suggestions feed with real-time rendering

### creations (formerly "the vault")
- magic link authentication (supabase auth OTP) — easy-mode auto-approves every sign-in as a member
- idea lifecycle: seed → project → company
- stage pipeline visualization with filtering and search
- per-idea: title, description, github / website / demo URLs, team members, company name, optional `display_name` for public attribution
- ✨ "paste anything — we'll extract it" panel: paste a whatsapp message, tweet, or rough notes → POSTs to `/api/extract-project` → prefills the form fields
- **full-edit modal** — click "edit" on your own card to change every field (title, description, links, team, stage, display name); delete also lives here

### sundays calendar (members)
- public read of the next 8 weeks; auto-extends each visit
- claim teach or MC slot; edit your topic; drop out
- mint per-member invite codes (codes still functional even though gating is dormant)
- past archive view + cancellation badges + 1-of-3-filled summary pill per Sunday card

### members directory (public)
- `/members.html` — every approved member by join order with inviter attribution; founding members tagged
- read-only; no auth required

### admin dashboard
- sha-256 hashed password gate (no plaintext in source)
- stats overview (total signups, by role, by status)
- signup management with expand/collapse detail views and status updates (pending → approved/declined)
- calendar view for sunday scheduling
- people directory
- data export (json)
- **ideas tab:** bulk-paste a WhatsApp chunk (or drop `_chat.txt`) → `/api/extract-projects-bulk` returns editable draft rows with display_name autoplaceholder → import selected via `/api/admin-import-projects`
- **members tab:** approve/revoke members, adjust invite quotas, mint or toggle the shared launch code (`WELCOME-2026` is the active master code; turn off to switch to invite-only)

## serverless endpoints (`api/`)

| endpoint | model | auth | purpose |
|----------|-------|------|---------|
| `POST /api/extract-project` | claude haiku 4.5 | rate-limited per IP | parse one blob of text into a single project record (forced tool use returns strict JSON) |
| `POST /api/extract-projects-bulk` | claude sonnet 4.6 | `ADMIN_SECRET` bearer | parse a WhatsApp export chunk into many project records; system prompt is `cache_control: ephemeral` so repeat runs are cheap |
| `POST /api/admin-import-projects` | n/a | `ADMIN_SECRET` bearer | bulk-insert reviewed projects with `IMPORT_USER_ID` ownership; per-row slug collision retry |
| `GET /api/luma-events` | n/a | public | parses the public luma iCal feed and returns upcoming creationship events (no API key needed); powers the home-page "this sunday" featured-event card |

## sql migrations

run these in the supabase sql editor in order:

1. `supabase-migration.sql` — core tables (people, role_signups, sundays, invitations)
2. `ideas-migration.sql` — ideas table + RLS (anon read, auth write)
3. `ideas-v2-migration.sql` — adds github_url, website_url, demo_url, team_members (jsonb)
4. `ideas-v3-migration.sql` — adds stage (seed/project/company) + company_name
5. `playlist-migration.sql` — playlist_suggestions table
6. `rls-tighten-migration.sql` — tighten row-level security policies
7. `scripts/display-and-slug-migration.sql` — adds `display_name` + `slug` columns + unique index on non-empty slugs
8. **either** `scripts/bulk-import-projects.sql` (fresh installs — inserts 18 projects with display_name + slug pre-populated) **or** `scripts/backfill-display-slug.sql` (existing installs that already imported under the old schema)

## environment variables (vercel)

set in **vercel → project settings → environment variables**, then redeploy:

| name | purpose |
|------|---------|
| `ANTHROPIC_API_KEY` | claude API key — for `/api/extract-*` |
| `SUPABASE_SERVICE_ROLE_KEY` | bypasses RLS for server-side admin inserts |
| `IMPORT_USER_ID` | `auth.users.id` UUID that owns admin-imported rows |
| `ADMIN_SECRET` | bearer token for `/api/extract-projects-bulk` and `/api/admin-import-projects` — match the plaintext password used at `/admin.html` |

`.env.local` (gitignored) holds the same keys for local script use; copy from `.env.example`.

## auth setup

for magic-link login (sundays calendar + creations submit/edit) to work, configure in supabase dashboard:

- **authentication → url configuration:**
  - site url: `https://creationship.vercel.app`
  - redirect urls (allowlist): `https://creationship.vercel.app/**`, `https://church-of-creationship.vercel.app/**`, `https://*.vercel.app/**`, `http://localhost:3000/**`

## local development

no build step. just open `index.html` in a browser, or:

```bash
npx serve .
```

for the autoload endpoints locally:

```bash
npm install
vercel dev
```

(requires `.env.local` populated, see `.env.example`.)

## deploy

```bash
vercel --prod
```

vercel auto-deploys on push to `main`.

## project structure

```
├── index.html                       # landing + signup + soundscape
├── projects.html                    # public projects showcase + detail modal
├── ideas.html                       # creations — authenticated idea board + edit modal + paste-and-prefill
├── admin.html                       # core team dashboard + bulk-paste ideas tab
├── styles.css                       # full design system + modal + bulk-row styles
├── data.js                          # supabase client + all CRUD ops + slug helper
├── package.json                     # deps for serverless functions and scripts
├── api/
│   ├── _shared.js                   # PROJECT_SCHEMA + system prompts + rate limit
│   ├── extract-project.js           # Haiku — single-project text → JSON
│   ├── extract-projects-bulk.js     # Sonnet (cached) — bulk parsing
│   └── admin-import-projects.js     # service-role bulk insert with slug retry
├── scripts/
│   ├── bulk-import-projects.js      # node script (alt to SQL path)
│   ├── bulk-import-projects.sql     # one-shot SQL: 18 projects with display_name + slug
│   ├── backfill-display-slug.sql    # update display_name + slug for already-imported rows
│   └── display-and-slug-migration.sql  # add the two columns + unique index
├── logo.png                         # mandala logo
├── favicon.svg
├── og-image.png                     # open graph (home + projects)
├── og-vault.png                     # open graph (vault)
├── supabase-migration.sql           # core schema
├── ideas-migration.sql              # ideas v1
├── ideas-v2-migration.sql           # + links + team
├── ideas-v3-migration.sql           # + stage + company_name
├── playlist-migration.sql
├── rls-tighten-migration.sql
├── .env.example                     # local env template
├── .vercelignore                    # excludes private data + dev tooling
└── README.md
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
| `--bg-accent` | `#ff4b1f` | orange-red — section accents, paint swipe, hero arrow, "company" stage badge, accent share button |
| `--accent-reflect` | `#7a2dff` | plasma purple — reflective/contemplative moments, hero paint block |
| `--font` | Inter (300–900) | all typography |

## accessibility

- `prefers-reduced-motion` media query disables all animations, modal slide-up, and reveal scroll
- modal: keyboard-operable cards (Enter / Space to open), Escape to close, focus management on the close button
- semantic html with proper heading hierarchy (`h1` → `h2` → `h3`)
- scroll-margin-top on all `[id]` elements for sticky nav offset
- `IntersectionObserver` reveal animations respect reduced motion

## seo

- open graph + twitter card meta tags on every page
- `favicon.svg` + `og-image.png` + `og-vault.png` assets
- descriptive `<title>` and `<meta name="description">` per page
- per-project shareable URLs are crawlable (modal contents are present in the rendered DOM after fetch)
- semantic html5 structure throughout

## next steps

- [ ] custom domain setup (e.g. `creationship.co`)
- [ ] email notifications for new signups (resend or supabase edge functions)
- [ ] invitation token enforcement (`/join?token=`)
- [ ] supabase auth for admin (replace client-side hashed password gate)
- [ ] playlist suggestion moderation in admin dashboard
- [ ] per-project og-image auto-generation (currently the projects page shares its single og-image)
- [ ] inline edit for `display_name` after submission (currently only set on first submit)

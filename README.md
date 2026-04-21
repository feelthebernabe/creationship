# the creationship

a weekly create-a-thon for moral imagination.  
part weekly ritual, part infinite create-a-thon — sundays at caravan of dreams, east village.

**live:** [creationship.vercel.app](https://creationship.vercel.app)

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
- **design:** editorial sans-serif, light chrome, neon lime accent, high-contrast

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
- full-bleed hero with bold editorial typography
- manifesto marquee strip
- "the premise" — narrative explaining creationships
- three currents: new tech · forever human · the bridge (`data-accordion` → collapses on mobile ≤640px)
- sunday schedule timeline
- proof section (past projects)
- location card with next-sunday countdown
- role signup flow (hold space / teach / brain trust)

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
└── rls-tighten-migration.sql # security policies
```

## design system

the visual language is inspired by editorial agency sites (goat agency, red antler) — bold sans-serif typography, high contrast, light chrome with saturated accent hits.

| token | value | usage |
|-------|-------|-------|
| `--bg` | `#f2f2f2` | page background |
| `--bg-dark` | `#0a0a0a` | hero, nav, footer, dark cards |
| `--accent` | `#b8ff72` | cta buttons, active states, highlights |
| `--bg-accent` | `#ff4b1f` | vibrant sections (schedule times, "new here") |
| `--font` | Inter | all typography |

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

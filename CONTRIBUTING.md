# contributing

skipping the basics — this assumes you've shipped a web app before. ping michelle if anything below is fuzzy.

## access

you have write access on the repo. branch protection blocks force-push and deletion on `main`, but doesn't require PR review. social contract: open a PR rather than pushing to `main` directly. michelle merges.

## what's fair game

all of it. no off-limits areas. the only hard rule on schema: **write a new migration, don't edit existing ones** (even if they look wrong — write a follow-up that fixes them).

## frontend-only setup

no env vars, no backend.

```bash
python3 -m http.server 8000
```

`projects.html` has a built-in seed of 17 projects so it renders against an empty database. `calendar.html`, signup forms, and `members.html` will look empty without a backend — fine if you're only touching markup, copy, or CSS.

## full-stack setup

### 1. supabase project

free tier. note the project URL, the anon key, and the service-role key.

### 2. run migrations

```bash
supabase link --project-ref <your-ref>
supabase db push
```

`supabase db push` runs everything in [supabase/migrations/](supabase/migrations/) chronologically. **but** those migrations assume the base tables already exist, so before pushing, run the legacy root-level SQL files **once** in this order in the supabase SQL editor:

1. [supabase-migration.sql](supabase-migration.sql)
2. [ideas-migration.sql](ideas-migration.sql)
3. [ideas-v2-migration.sql](ideas-v2-migration.sql)
4. [ideas-v3-migration.sql](ideas-v3-migration.sql)
5. [playlist-migration.sql](playlist-migration.sql)
6. [rls-tighten-migration.sql](rls-tighten-migration.sql)

historical context: these files predate the supabase CLI and create the base tables. the timestamped migrations alter on top of them. once production stabilizes we'll squash them into a single `init.sql`.

### 3. env vars

copy `.env.example` to `.env.local` and fill in:

| var | who needs it |
|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | every server-side path. secret — bypasses RLS. |
| `IMPORT_USER_ID` | bulk-import scripts only (your auth user uuid). |
| `ANTHROPIC_API_KEY` | only if you're touching `/api/extract-*`. |
| `RESEND_API_KEY` | only if you're touching email. without it, email no-ops with a warn log. |
| `ADMIN_SECRET` | any random string — gates `/admin.html` actions. |
| `CRON_SECRET` | any random string — gates `/api/cron-reminders`. |

### 4. point the frontend at your project

`SUPABASE_URL` and the anon key are hardcoded in three places (this is intentional — anon key is meant to be public; RLS does the protection):

- [data.js:5-6](data.js#L5-L6)
- [api/cancel-claim.js:8-9](api/cancel-claim.js#L8-L9)
- [api/claim-slot.js:13-14](api/claim-slot.js#L13-L14)

swap to your project's values for local testing. **do not commit the swap** — production will break instantly. easy way: keep the swap on a local-only branch you never push, or stash before committing.

### 5. run locally

```bash
npm install
vercel dev
```

serves the static site + serverless functions on `localhost:3000`. (`python3 -m http.server` works for static-only but won't run the `/api/` functions.)

## architecture map

- **frontend pages** — static html at repo root. vanilla js, no framework, no build. shared client config + supabase wrapper in [data.js](data.js).
- **serverless functions** — [api/](api/), vercel-shaped. `_email.js` and `_shared.js` are helpers (underscore prefix = vercel skips routing).
- **schema** — supabase. tables + RLS + RPCs in [supabase/migrations/](supabase/migrations/) plus the historical root-level files. zero-auth flows use `SECURITY DEFINER` RPCs to bypass RLS safely.
- **email** — [resend](https://resend.com), templates inline in [api/_email.js](api/_email.js). graceful no-op when `RESEND_API_KEY` is missing.
- **cron** — [vercel.json](vercel.json) triggers `/api/cron-reminders` daily at 14:00 UTC.

## flow

1. `git checkout -b your-name/short-description` off `main`
2. push the branch to `origin` (write access — no fork needed)
3. open a PR against `main`
4. michelle reviews + merges

## ground rules

- voice: lowercase, terse, sentence-style. match what's there.
- new migrations only — never edit existing migration files.
- never commit your local supabase URL/anon-key swap.
- not every feature will fit. open an issue first if you're unsure of direction.

## known gotchas

- **easy-mode auto-approve** — any magic-link sign-in becomes an approved member automatically (see `20260426071649_easy_mode_auto_approve.sql`). don't rely on invite gating in dev.
- **resend sandbox** — `from` address is currently `onboarding@resend.dev`; the click-tracker has an SSL outage on `us-east-1.resend-clicks.com`, so emails are sent text-only as a workaround. once a custom sender domain ships, HTML emails come back.
- **members.html hidden from nav** — the nav link is intentionally commented out everywhere. the page still serves at the URL; the underlying RPC has been revoked from `anon`. uncomment the nav line in every page to restore.
- **two migration directories** — root-level `*-migration.sql` are pre-CLI history, `supabase/migrations/` is the source of truth for new work. don't add new files to root.

## questions

file an issue, or text michelle.

# church of creationship — signup & calendar system

*planning doc, not code. for michelle + ben + core team to mark up.*

---

## what this is

a lightweight, community-gated system to coordinate the three roles that make sunday happen — **hold the space**, **teach**, **brain trust** — plus an admin layer for the core team to vet, schedule, and eventually archive offerings.

not a public signup form. not a calendar plugin. something closer to infrastructure for a weekly ritual: it should hold the shape.

---

## what you've said so far

- **three roles**, all with a vetting step
- **community-gated** — not open to the internet; people arrive through an invitation or link
- **admin access** for the whole core team
- **teaching archive** is a yes, eventually
- **integrations** (substack, eventbrite, calendar apps) — open question, not today
- **five ritual segments** — open question, maybe relevant to teaching slots
- **one-page signup flow** was the last UX preference, but that was for google forms and doesn't have to constrain this

---

## the three roles, unpacked

### hold the space
- likely an ongoing rotating commitment, not per-sunday
- open questions:
  - minimum commitment? (e.g. 4 sundays, a season)
  - how many space-holders per sunday?
  - what does "holding the space" actually ask of someone — arriving early, opening the ritual, closing it, pastoral care during, logistics?
- vetting step: probably a short intake + conversation with a core team member

### teach
- one teacher per sunday? or can a sunday hold multiple offerings?
- how far out can people claim a date — 4 weeks? 12? open-ended?
- vetting: the teacher submits a pitch, a core team member reviews, status moves from *proposed → approved → scheduled → completed*
- this is the most structured flow

### brain trust
- open question: is this a cohort (fixed group that meets) or a pool (people you reach out to ad hoc)?
- vetting: likely an application — what do you bring, what do you want, how much time can you give?
- cap? rolling or seasonal intake?

---

## what the system needs to do

### for the person signing up (the "edge" view)

1. land on a page via an invited link
2. see what church of creationship is, in your voice
3. pick a role (or more than one)
4. fill out a role-specific intake:
   - **teach:** name, contact, proposed date(s), pitch, what they need from the space
   - **hold the space:** name, contact, availability pattern, why this draws them, any relevant experience
   - **brain trust:** name, contact, what they bring, what they want, time capacity
5. get a confirmation that lands warm, not transactional
6. receive an email from a real human within a few days

### for the core team (the "core" view — admin)

1. shared login, everyone on the core team sees the same dashboard
2. inbox of pending signups, filterable by role
3. click into a signup, see the full intake, leave notes, change status
4. calendar view of sundays — who's teaching, who's holding, what's open
5. archive view of past sundays — who taught, what was the offering, eventually links to recordings or notes
6. ability to manually add a sunday entry (for when teaching gets booked over a phone call, not through the form)

---

## the shape of the thing (architectural sketch)

### data model (rough)

**people**
- id, name, contact, created_at, notes (admin-only)

**role_signups**
- id, person_id, role_type (hold_space | teach | brain_trust)
- status (pending | in_review | approved | declined | completed)
- intake_data (jsonb — role-specific fields)
- reviewed_by, reviewed_at, review_notes
- created_at

**sundays** *(one row per week, even empty ones)*
- id, date, status (open | booked | completed | cancelled)
- teacher_id (nullable, fk to role_signups)
- space_holders (array of person ids or role_signup ids)
- segment_plan (optional — if we land on the five ritual segments being relevant)
- title, description (public-facing copy for the week)
- archive fields: recording_url, notes, photos, themes (for clustering later)

**invitations** *(for community-gating)*
- id, token, created_by, used_by, expires_at, role_hint (nullable — e.g. "i'm inviting you specifically to teach")

### auth & gating

- no public signup
- access is via invitation token in the URL (`/join?token=...`) — token grants single-use access to the signup flow
- admin side: actual login (magic link via supabase auth) for the core team
- nobody else can see the admin dashboard, the calendar, or the archive

### the pages

**public (but gated by invitation token):**
- `/` — landing, only shown after token validates. what church of creationship is, three role cards, pick one.
- `/signup/teach` — teaching intake
- `/signup/hold-the-space` — space-holder intake
- `/signup/brain-trust` — brain trust application
- `/thanks` — confirmation, what happens next

**admin (gated by core team login):**
- `/admin` — dashboard, pending signups inbox
- `/admin/signup/:id` — signup detail + review actions
- `/admin/calendar` — sunday grid, fill status at a glance
- `/admin/sunday/:date` — edit a sunday: who's teaching, who's holding, copy
- `/admin/archive` — past sundays, searchable, eventually clusterable by theme
- `/admin/people` — everyone who's signed up, across roles, across time

---

## open design questions worth sitting with

1. **the calendar primitive.** should a "sunday" entry exist for every sunday going forward automatically (cron job, or pre-seeded), or should it only exist when something's booked into it? the former makes the calendar view cleaner; the latter is simpler.

2. **can someone sign up for multiple roles at once?** one intake with branching, or three separate intakes? i lean toward: separate flows per role, but a person record that links them.

3. **the invitation model.** are tokens single-use (one per person) or shareable (one per inviter)? single-use is more controlled, shareable is more viral. for community-gating, single-use feels right.

4. **vetting workflow.** is there a single reviewer per signup, or does the core team see them collectively? lightweight: anyone on the core team can mark a signup reviewed. heavier: assignment + sign-off. i'd start lightweight.

5. **the five ritual segments.** if they're relevant, teaching signups might ask *"which segment is this for?"* — opening, core, edge (whatever the five are). if it's not relevant yet, we just leave that field out and add it later. this is a "v2" question, not a blocker.

6. **notifications.** when a signup comes in, does the core team get an email? a slack ping? nothing, just the dashboard? i'd vote email digest daily to whoever's on "signup duty" that week.

7. **archive search & clustering.** "themes" is the interesting word. tagging offerings with themes manually is cheap; AI-clustering them retrospectively is rich but much later. start with tags.

8. **the integration question.** substack / calendar apps / eventbrite can all wait. the one that might matter soon is **google calendar** — being able to push a booked sunday as a calendar event for the teacher and space-holders, so it shows up in their personal calendar. that's a nice-to-have for v1, not a must.

---

## suggested build phases

### v0 — the bones (1–2 weekends of vibe coding)
- supabase set up: people, role_signups, sundays tables
- three intake forms, each a separate page, each writing to role_signups
- invitation tokens (single-use), validation in a middleware
- admin login via supabase magic link
- admin dashboard: list of pending signups, click to see detail, status change buttons
- a basic calendar view (month grid, sundays highlighted, click to see/edit what's on that sunday)
- deploys to vercel, supabase free tier, basically zero ongoing cost

### v0.5 — making it feel right
- email confirmations (using resend or similar) when someone signs up — lands warm, not robotic
- admin gets an email when a new signup comes in
- sunday detail pages let you assign teachers + space-holders from existing people/signups
- "anyone on the core team can mark reviewed" flow
- basic notes field on every signup

### v1 — archive + polish
- past sundays move to an archive view, searchable
- manual theme tags per offering
- public-facing (still gated) preview of upcoming sundays — if you want teachers to see what's coming up before they pitch
- optional: the five ritual segments integrated into teaching signup, if by then you've decided they should be

### v2 — the richer layer
- google calendar push for booked sundays
- teacher prep guide auto-sent when someone gets approved
- basic analytics: signups per month, teaching slot fill rate, roles that need recruiting
- maybe: community-facing calendar (still gated) so members can see what's coming and RSVP

### someday
- AI theme clustering of archived offerings
- a proper "teacher profile" page for each person who's taught
- substack integration — auto-pull the week's offering into the newsletter
- eventbrite integration for bigger community events

---

## the voice question

the edge-facing copy (landing, intakes, confirmation) needs to sound like **you** — the Dear Crisis / creationships / moral health voice. lowercase, specific, emotionally honest. not "thank you for your interest in our programming." more like "got you. we'll be in touch within the week."

that copy should get drafted separately and sit in a copy doc, not be hardcoded first. you'll want to revise it ten times.

---

## what i'd recommend doing next

1. mark up this doc — delete what's wrong, sharpen what's fuzzy
2. answer the open design questions above (or flag them as "figure out while building")
3. decide if v0 scope feels right, or if something's missing / over-scoped
4. pull Ben in for a 30-minute look before i write a line of code — he'll see things in it you won't
5. then we build

one question worth naming before you run this past anyone: **is there anyone currently signed up or promised a role that needs to get into the system on day one?** if yes, that changes the first-week priority from "build the form" to "import the existing list cleanly."

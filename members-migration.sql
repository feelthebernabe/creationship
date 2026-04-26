-- ============================================================
-- THE CREATIONSHIP — MEMBERS, INVITES, & CALENDAR CLAIMS
-- Adds member identity (auth.user ↔ people), referral-tree
-- invitations, and the RPCs that drive calendar.html.
-- Run this in the Supabase SQL Editor AFTER:
--   - supabase-migration.sql
--   - rls-tighten-migration.sql
-- ============================================================

-- ============================================================
-- 1. SCHEMA ADDITIONS ON people
-- ============================================================

ALTER TABLE people
  ADD COLUMN IF NOT EXISTS auth_user_id UUID,
  ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES people(id),
  ADD COLUMN IF NOT EXISTS invites_remaining INTEGER DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS people_auth_user_id_unique
  ON people(auth_user_id) WHERE auth_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_people_approved ON people(approved_at)
  WHERE approved_at IS NOT NULL;

-- ----- invitations: support multi-use master codes alongside
--       single-use referral codes. max_uses NULL = unlimited.
--       is_active = false short-circuits redemption (admin "off" switch).

ALTER TABLE invitations
  ADD COLUMN IF NOT EXISTS max_uses INT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS use_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS label TEXT DEFAULT '';

-- Per-redemption ledger so multi-use codes can still trace who joined.
CREATE TABLE IF NOT EXISTS invitation_redemptions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  invitation_id UUID NOT NULL REFERENCES invitations(id) ON DELETE CASCADE,
  redeemed_by UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  redeemed_at TIMESTAMPTZ DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS invitation_redemptions_unique
  ON invitation_redemptions (invitation_id, redeemed_by);

ALTER TABLE invitation_redemptions ENABLE ROW LEVEL SECURITY;
-- No public policies — access is via SECURITY DEFINER functions only.

-- ============================================================
-- 2. INVITE TOKEN GENERATOR
-- 8-char base32 (no I/O/0/1 ambiguity), dashed mid: `K3X7-NPQR`.
-- ============================================================

CREATE OR REPLACE FUNCTION gen_invite_token() RETURNS TEXT AS $$
DECLARE
  v_chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_token TEXT := '';
  v_i INT;
BEGIN
  FOR v_i IN 1..8 LOOP
    v_token := v_token || substr(v_chars, 1 + floor(random() * length(v_chars))::int, 1);
    IF v_i = 4 THEN v_token := v_token || '-'; END IF;
  END LOOP;
  RETURN v_token;
END $$ LANGUAGE plpgsql;

-- ============================================================
-- 3. MEMBER IDENTITY
-- ensure_member() — idempotent: links auth.uid() → people row.
-- Called by data.js on every page load when a session exists.
-- ============================================================

CREATE OR REPLACE FUNCTION ensure_member() RETURNS people AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_email TEXT;
  v_person people%ROWTYPE;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = v_user_id;
  IF v_email IS NULL THEN RAISE EXCEPTION 'no_email'; END IF;

  SELECT * INTO v_person FROM people WHERE auth_user_id = v_user_id;
  IF FOUND THEN RETURN v_person; END IF;

  SELECT * INTO v_person FROM people WHERE LOWER(email) = LOWER(v_email);
  IF FOUND THEN
    UPDATE people SET auth_user_id = v_user_id
     WHERE id = v_person.id
     RETURNING * INTO v_person;
    RETURN v_person;
  END IF;

  INSERT INTO people (auth_user_id, name, email)
    VALUES (v_user_id, split_part(v_email, '@', 1), v_email)
    RETURNING * INTO v_person;
  RETURN v_person;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION ensure_member() TO authenticated;

-- ----- get_my_member: read-only fetch of the caller's row -----

CREATE OR REPLACE FUNCTION get_my_member() RETURNS people AS $$
  SELECT * FROM people WHERE auth_user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION get_my_member() TO authenticated;

-- ============================================================
-- 4. INVITATION FLOW
-- mint_invite() — approved members spend 1 of their quota
-- redeem_invite(token) — sets approved_at, grants quota
-- ============================================================

CREATE OR REPLACE FUNCTION mint_invite() RETURNS invitations AS $$
DECLARE
  v_person people%ROWTYPE;
  v_invite invitations%ROWTYPE;
  v_token TEXT;
  v_attempt INT := 0;
BEGIN
  SELECT * INTO v_person FROM people
    WHERE auth_user_id = auth.uid() AND approved_at IS NOT NULL
    FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'not_approved'; END IF;
  IF v_person.invites_remaining <= 0 THEN RAISE EXCEPTION 'no_quota'; END IF;

  -- Retry on token collision (vanishingly rare with 32^8 keyspace)
  LOOP
    v_token := gen_invite_token();
    BEGIN
      INSERT INTO invitations (token, created_by, expires_at, max_uses, is_active, label)
        VALUES (v_token, v_person.id::text, now() + interval '30 days', 1, true, 'referral')
        RETURNING * INTO v_invite;
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      v_attempt := v_attempt + 1;
      IF v_attempt > 5 THEN RAISE; END IF;
    END;
  END LOOP;

  UPDATE people SET invites_remaining = invites_remaining - 1
    WHERE id = v_person.id;

  RETURN v_invite;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION mint_invite() TO authenticated;

CREATE OR REPLACE FUNCTION redeem_invite(p_token TEXT) RETURNS people AS $$
DECLARE
  v_invite invitations%ROWTYPE;
  v_person people%ROWTYPE;
  v_user_id UUID := auth.uid();
  v_inviter_uuid UUID;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;

  -- Lock the invite row so two concurrent redeemers can't both win.
  -- Match on UPPER token; accept if active, not expired, and either:
  --   single-use (max_uses=1) and not yet used, OR
  --   multi-use (max_uses>1 or NULL) and use_count < max_uses (NULL = unlimited).
  SELECT * INTO v_invite FROM invitations
    WHERE token = UPPER(TRIM(p_token))
      AND is_active = true
      AND (expires_at IS NULL OR expires_at > now())
      AND (
        (COALESCE(max_uses, 1) = 1 AND used_by IS NULL)
        OR (max_uses IS NULL OR use_count < max_uses)
      )
    FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_or_expired'; END IF;

  SELECT * INTO v_person FROM people WHERE auth_user_id = v_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'no_member_row'; END IF;

  -- Self-invite guard: can't redeem a referral code you minted
  IF v_invite.created_by = v_person.id::text THEN
    RAISE EXCEPTION 'self_redemption';
  END IF;

  -- Idempotency: if this person already redeemed this code, just return them.
  -- Unique index on (invitation_id, redeemed_by) backs this.
  BEGIN
    INSERT INTO invitation_redemptions (invitation_id, redeemed_by)
      VALUES (v_invite.id, v_person.id);
  EXCEPTION WHEN unique_violation THEN
    SELECT * INTO v_person FROM people WHERE id = v_person.id;
    RETURN v_person;
  END;

  -- Bump counters. For single-use codes, also stamp used_by for legacy reads.
  UPDATE invitations
     SET use_count = use_count + 1,
         used_by = CASE
           WHEN COALESCE(max_uses, 1) = 1 THEN v_person.id
           ELSE used_by
         END
   WHERE id = v_invite.id;

  -- approved_by is only meaningful for personal referrals (created_by is a person id).
  -- For master codes (created_by NULL), leave approved_by NULL.
  BEGIN
    v_inviter_uuid := v_invite.created_by::uuid;
  EXCEPTION WHEN invalid_text_representation THEN
    v_inviter_uuid := NULL;
  END;

  UPDATE people
     SET approved_at = COALESCE(approved_at, now()),
         approved_by = COALESCE(approved_by, v_inviter_uuid),
         invites_remaining = GREATEST(invites_remaining, 2)
   WHERE id = v_person.id
   RETURNING * INTO v_person;

  RETURN v_person;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION redeem_invite(TEXT) TO authenticated;

-- ----- list invitations the caller has minted -----

CREATE OR REPLACE FUNCTION get_my_invitations()
RETURNS TABLE (
  id UUID, token TEXT, used_by_name TEXT, expires_at TIMESTAMPTZ, created_at TIMESTAMPTZ
) AS $$
  SELECT
    i.id, i.token,
    used.name AS used_by_name,
    i.expires_at, i.created_at
  FROM invitations i
  LEFT JOIN people used ON used.id = i.used_by
  WHERE i.created_by = (SELECT id::text FROM people WHERE auth_user_id = auth.uid())
  ORDER BY i.created_at DESC;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION get_my_invitations() TO authenticated;

-- ============================================================
-- 5. SUNDAY CALENDAR — ROLLING WINDOW + PUBLIC READ
-- ensure_upcoming_sundays(n) — idempotent backfill
-- get_upcoming_calendar(n) — joined view safe for anon read
-- ============================================================

CREATE OR REPLACE FUNCTION ensure_upcoming_sundays(p_weeks INT DEFAULT 8)
RETURNS VOID AS $$
DECLARE
  v_first_sunday DATE := CURRENT_DATE + ((7 - EXTRACT(DOW FROM CURRENT_DATE)::int) % 7);
  v_i INT;
BEGIN
  FOR v_i IN 0..(p_weeks - 1) LOOP
    INSERT INTO sundays (date, status)
      VALUES (v_first_sunday + (v_i * 7), 'open')
      ON CONFLICT (date) DO NOTHING;
  END LOOP;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION ensure_upcoming_sundays(INT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION get_upcoming_calendar(p_weeks INT DEFAULT 8)
RETURNS TABLE (
  id UUID,
  date DATE,
  status TEXT,
  title TEXT,
  description TEXT,
  themes TEXT[],
  teacher_signup_id UUID,
  teacher_name TEXT,
  teacher_topic TEXT,
  mc_signups JSONB
) AS $$
  SELECT
    s.id, s.date, s.status, s.title, s.description, s.themes,
    s.teacher_signup_id,
    tp.name AS teacher_name,
    ts.intake_data->>'title' AS teacher_topic,
    COALESCE(
      (
        SELECT jsonb_agg(jsonb_build_object('signup_id', ms.id, 'name', mp.name))
        FROM role_signups ms
        JOIN people mp ON mp.id = ms.person_id
        WHERE ms.id = ANY(s.space_holder_ids)
      ),
      '[]'::jsonb
    ) AS mc_signups
  FROM sundays s
  LEFT JOIN role_signups ts ON ts.id = s.teacher_signup_id
  LEFT JOIN people tp ON tp.id = ts.person_id
  WHERE s.date >= CURRENT_DATE
    AND s.date < CURRENT_DATE + (p_weeks * 7)
  ORDER BY s.date;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION get_upcoming_calendar(INT) TO anon, authenticated;

-- ============================================================
-- 6. CLAIM / UNCLAIM A SUNDAY SLOT
-- All require approved member status. Atomic.
-- ============================================================

CREATE OR REPLACE FUNCTION claim_teach(
  p_sunday_id UUID,
  p_title TEXT,
  p_description TEXT
) RETURNS sundays AS $$
DECLARE
  v_person people%ROWTYPE;
  v_sunday sundays%ROWTYPE;
  v_signup role_signups%ROWTYPE;
BEGIN
  SELECT * INTO v_person FROM people
    WHERE auth_user_id = auth.uid() AND approved_at IS NOT NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'not_approved'; END IF;

  SELECT * INTO v_sunday FROM sundays WHERE id = p_sunday_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sunday_not_found'; END IF;
  IF v_sunday.teacher_signup_id IS NOT NULL THEN
    RAISE EXCEPTION 'teach_slot_taken';
  END IF;
  IF v_sunday.date < CURRENT_DATE THEN RAISE EXCEPTION 'past_sunday'; END IF;

  INSERT INTO role_signups (person_id, role_type, status, intake_data)
    VALUES (
      v_person.id, 'teach', 'approved',
      jsonb_build_object('title', p_title, 'description', p_description, 'sunday_id', p_sunday_id)
    )
    RETURNING * INTO v_signup;

  UPDATE sundays
     SET teacher_signup_id = v_signup.id,
         status = 'booked',
         title = COALESCE(NULLIF(p_title, ''), title),
         description = COALESCE(NULLIF(p_description, ''), description)
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  RETURN v_sunday;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION claim_teach(UUID, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION claim_mc(p_sunday_id UUID) RETURNS sundays AS $$
DECLARE
  v_person people%ROWTYPE;
  v_sunday sundays%ROWTYPE;
  v_signup role_signups%ROWTYPE;
  v_already UUID;
BEGIN
  SELECT * INTO v_person FROM people
    WHERE auth_user_id = auth.uid() AND approved_at IS NOT NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'not_approved'; END IF;

  SELECT * INTO v_sunday FROM sundays WHERE id = p_sunday_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sunday_not_found'; END IF;
  IF v_sunday.date < CURRENT_DATE THEN RAISE EXCEPTION 'past_sunday'; END IF;

  -- Already MC'ing? no-op, return current state
  SELECT id INTO v_already FROM role_signups
    WHERE id = ANY(v_sunday.space_holder_ids) AND person_id = v_person.id;
  IF FOUND THEN RETURN v_sunday; END IF;

  INSERT INTO role_signups (person_id, role_type, status, intake_data)
    VALUES (v_person.id, 'hold_space', 'approved',
            jsonb_build_object('sunday_id', p_sunday_id))
    RETURNING * INTO v_signup;

  UPDATE sundays
     SET space_holder_ids = array_append(space_holder_ids, v_signup.id)
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  RETURN v_sunday;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION claim_mc(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION unclaim_teach(p_sunday_id UUID) RETURNS sundays AS $$
DECLARE
  v_person people%ROWTYPE;
  v_sunday sundays%ROWTYPE;
  v_signup role_signups%ROWTYPE;
BEGIN
  SELECT * INTO v_person FROM people WHERE auth_user_id = auth.uid();
  IF NOT FOUND THEN RAISE EXCEPTION 'no_member_row'; END IF;

  SELECT * INTO v_sunday FROM sundays WHERE id = p_sunday_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sunday_not_found'; END IF;
  IF v_sunday.teacher_signup_id IS NULL THEN RETURN v_sunday; END IF;

  SELECT * INTO v_signup FROM role_signups WHERE id = v_sunday.teacher_signup_id;
  IF v_signup.person_id <> v_person.id THEN RAISE EXCEPTION 'not_your_slot'; END IF;
  IF v_sunday.date - CURRENT_DATE < 1 THEN RAISE EXCEPTION 'too_late_to_unclaim'; END IF;

  UPDATE sundays
     SET teacher_signup_id = NULL,
         status = CASE WHEN array_length(space_holder_ids, 1) IS NULL THEN 'open' ELSE status END
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  DELETE FROM role_signups WHERE id = v_signup.id;

  RETURN v_sunday;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION unclaim_teach(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION unclaim_mc(p_sunday_id UUID) RETURNS sundays AS $$
DECLARE
  v_person people%ROWTYPE;
  v_sunday sundays%ROWTYPE;
  v_signup_id UUID;
BEGIN
  SELECT * INTO v_person FROM people WHERE auth_user_id = auth.uid();
  IF NOT FOUND THEN RAISE EXCEPTION 'no_member_row'; END IF;

  SELECT * INTO v_sunday FROM sundays WHERE id = p_sunday_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sunday_not_found'; END IF;
  IF v_sunday.date - CURRENT_DATE < 1 THEN RAISE EXCEPTION 'too_late_to_unclaim'; END IF;

  SELECT id INTO v_signup_id FROM role_signups
    WHERE id = ANY(v_sunday.space_holder_ids) AND person_id = v_person.id;
  IF NOT FOUND THEN RETURN v_sunday; END IF;

  UPDATE sundays
     SET space_holder_ids = array_remove(space_holder_ids, v_signup_id)
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  DELETE FROM role_signups WHERE id = v_signup_id;

  RETURN v_sunday;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION unclaim_mc(UUID) TO authenticated;

-- ----- Allow the claiming teacher to update theme/description -----

CREATE OR REPLACE FUNCTION update_sunday_theme(
  p_sunday_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_themes TEXT[]
) RETURNS sundays AS $$
DECLARE
  v_person people%ROWTYPE;
  v_sunday sundays%ROWTYPE;
  v_signup role_signups%ROWTYPE;
BEGIN
  SELECT * INTO v_person FROM people WHERE auth_user_id = auth.uid();
  IF NOT FOUND THEN RAISE EXCEPTION 'no_member_row'; END IF;

  SELECT * INTO v_sunday FROM sundays WHERE id = p_sunday_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sunday_not_found'; END IF;
  IF v_sunday.teacher_signup_id IS NULL THEN RAISE EXCEPTION 'no_teacher_yet'; END IF;

  SELECT * INTO v_signup FROM role_signups WHERE id = v_sunday.teacher_signup_id;
  IF v_signup.person_id <> v_person.id THEN RAISE EXCEPTION 'not_your_slot'; END IF;

  UPDATE sundays
     SET title = p_title,
         description = p_description,
         themes = COALESCE(p_themes, themes)
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  UPDATE role_signups
     SET intake_data = intake_data
       || jsonb_build_object('title', p_title, 'description', p_description)
   WHERE id = v_signup.id;

  RETURN v_sunday;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION update_sunday_theme(UUID, TEXT, TEXT, TEXT[]) TO authenticated;

-- ============================================================
-- 7. ADMIN HELPERS (callable from admin.html w/ service role
-- header, OR by any authenticated user since admin.html is
-- behind the existing password gate).
-- ============================================================

-- List members + their state for the admin panel
CREATE OR REPLACE FUNCTION admin_list_members()
RETURNS TABLE (
  id UUID,
  name TEXT,
  email TEXT,
  approved_at TIMESTAMPTZ,
  invites_remaining INT,
  invited_by_name TEXT,
  created_at TIMESTAMPTZ
) AS $$
  SELECT
    p.id, p.name, p.email, p.approved_at, p.invites_remaining,
    inv.name AS invited_by_name,
    p.created_at
  FROM people p
  LEFT JOIN people inv ON inv.id = p.approved_by
  WHERE p.auth_user_id IS NOT NULL
  ORDER BY p.created_at DESC;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION admin_list_members() TO authenticated;

-- Toggle a member's approved state + set quota
CREATE OR REPLACE FUNCTION admin_set_member_approval(
  p_person_id UUID,
  p_approved BOOLEAN,
  p_invites INT DEFAULT 2
) RETURNS people AS $$
DECLARE v_person people%ROWTYPE;
BEGIN
  -- Light gate: caller must themselves be approved (i.e. the core team).
  -- For a hard gate, swap to a service-role check.
  IF NOT EXISTS (
    SELECT 1 FROM people
    WHERE auth_user_id = auth.uid() AND approved_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  UPDATE people
     SET approved_at = CASE WHEN p_approved THEN COALESCE(approved_at, now()) ELSE NULL END,
         invites_remaining = CASE WHEN p_approved THEN p_invites ELSE 0 END
   WHERE id = p_person_id
   RETURNING * INTO v_person;

  RETURN v_person;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION admin_set_member_approval(UUID, BOOLEAN, INT) TO authenticated;

-- Mint a one-off admin code (single-use, created_by = NULL = "from admin").
-- Use this to seed individual people without spending a member's quota.
CREATE OR REPLACE FUNCTION admin_mint_invite() RETURNS invitations AS $$
DECLARE
  v_invite invitations%ROWTYPE;
  v_token TEXT;
  v_attempt INT := 0;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM people
    WHERE auth_user_id = auth.uid() AND approved_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  LOOP
    v_token := gen_invite_token();
    BEGIN
      INSERT INTO invitations (token, created_by, expires_at, max_uses, is_active, label)
        VALUES (v_token, NULL, now() + interval '60 days', 1, true, 'admin')
        RETURNING * INTO v_invite;
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      v_attempt := v_attempt + 1;
      IF v_attempt > 5 THEN RAISE; END IF;
    END;
  END LOOP;

  RETURN v_invite;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION admin_mint_invite() TO authenticated;

-- Mint (or update) the shared master code for the early-bootstrap window.
-- Anyone can redeem it until the admin toggles is_active off.
--   p_token     — custom string like 'WELCOME-2026'; NULL → autogenerate.
--   p_label     — human note shown in admin UI ('master', 'launch week', …).
--   p_max_uses  — NULL = unlimited, otherwise a hard cap.
--   p_expires_at — NULL = never expires.
-- Idempotent on token: re-running with the same token updates the row in place.
CREATE OR REPLACE FUNCTION admin_create_master_invite(
  p_token TEXT,
  p_label TEXT DEFAULT 'master',
  p_max_uses INT DEFAULT NULL,
  p_expires_at TIMESTAMPTZ DEFAULT NULL
) RETURNS invitations AS $$
DECLARE
  v_invite invitations%ROWTYPE;
  v_token TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM people
    WHERE auth_user_id = auth.uid() AND approved_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  v_token := UPPER(TRIM(COALESCE(p_token, gen_invite_token())));
  IF length(v_token) < 4 THEN RAISE EXCEPTION 'token_too_short'; END IF;

  INSERT INTO invitations (token, created_by, expires_at, max_uses, is_active, label)
    VALUES (v_token, NULL, p_expires_at, p_max_uses, true, p_label)
    ON CONFLICT (token) DO UPDATE
      SET expires_at = EXCLUDED.expires_at,
          max_uses = EXCLUDED.max_uses,
          label = EXCLUDED.label,
          is_active = true
    RETURNING * INTO v_invite;

  RETURN v_invite;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION admin_create_master_invite(TEXT, TEXT, INT, TIMESTAMPTZ) TO authenticated;

-- Toggle any invite on/off (admin "kill switch" for the master code).
CREATE OR REPLACE FUNCTION admin_set_invite_active(
  p_invite_id UUID,
  p_active BOOLEAN
) RETURNS invitations AS $$
DECLARE v_invite invitations%ROWTYPE;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM people
    WHERE auth_user_id = auth.uid() AND approved_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  UPDATE invitations SET is_active = p_active
   WHERE id = p_invite_id
   RETURNING * INTO v_invite;

  RETURN v_invite;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION admin_set_invite_active(UUID, BOOLEAN) TO authenticated;

-- List all invites for admin dashboard (with use stats + inviter name).
CREATE OR REPLACE FUNCTION admin_list_invites()
RETURNS TABLE (
  id UUID,
  token TEXT,
  label TEXT,
  is_active BOOLEAN,
  max_uses INT,
  use_count INT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  created_by_name TEXT
) AS $$
  SELECT
    i.id, i.token, i.label, i.is_active, i.max_uses, i.use_count,
    i.expires_at, i.created_at,
    CASE
      WHEN i.created_by IS NULL THEN 'admin'
      ELSE (SELECT name FROM people WHERE id::text = i.created_by)
    END AS created_by_name
  FROM invitations i
  ORDER BY i.created_at DESC;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION admin_list_invites() TO authenticated;

-- ============================================================
-- 8. RLS — locked down. All mutations go through SECURITY
-- DEFINER functions above; tables themselves are read-only
-- to authenticated and (for sundays) public.
-- ============================================================

-- people: keep authenticated SELECT (already set in rls-tighten),
-- but block direct UPDATE/INSERT — go through ensure_member().
DROP POLICY IF EXISTS "Allow public update on people" ON people;

-- role_signups: keep authenticated SELECT (already set),
-- block direct INSERT/UPDATE — go through claim_*().
DROP POLICY IF EXISTS "Allow public insert on role_signups" ON role_signups;

-- invitations: drop the wide-open policy, replace with caller-scoped read.
DROP POLICY IF EXISTS "Allow public all on invitations" ON invitations;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members read their own invitations"
  ON invitations FOR SELECT
  USING (
    created_by = (SELECT id::text FROM people WHERE auth_user_id = auth.uid())
  );

-- Note: SECURITY DEFINER functions bypass RLS by design — that's
-- where all mutations live. The drops above just close the doors
-- that previously allowed bypassing those functions.

-- ============================================================
-- DONE. Smoke tests:
--   SELECT * FROM ensure_upcoming_sundays(8);
--   SELECT * FROM get_upcoming_calendar(8);
-- ============================================================

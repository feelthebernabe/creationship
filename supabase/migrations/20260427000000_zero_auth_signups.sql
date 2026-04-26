-- ============================================================
-- ZERO-AUTH SIGNUPS + EMAIL REMINDERS
-- Anyone can claim a Sunday slot by typing email + topic.
-- Each signup gets a cancel_token used by the email "cancel" link.
-- A daily cron uses get_due_reminders() to fire 7-day + 24h pings.
-- ============================================================

-- 1) Schema additions ---------------------------------------------------------

ALTER TABLE role_signups
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS cancel_token TEXT,
  ADD COLUMN IF NOT EXISTS notified_at JSONB DEFAULT '{}'::jsonb;

CREATE UNIQUE INDEX IF NOT EXISTS role_signups_cancel_token_unique
  ON role_signups(cancel_token) WHERE cancel_token IS NOT NULL;

CREATE INDEX IF NOT EXISTS role_signups_email_idx ON role_signups(email);


-- 2) Helpers ------------------------------------------------------------------

-- Find or create a `people` row for an email (no auth.users link required).
-- Used by the zero-auth claim path. Reuses the existing LOWER(email) unique
-- index so a person who signs up for two Sundays has one canonical row.
CREATE OR REPLACE FUNCTION _ensure_person_by_email(p_email TEXT, p_name TEXT)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  IF p_email IS NULL OR p_email = '' THEN RAISE EXCEPTION 'email_required'; END IF;

  SELECT id INTO v_id FROM people WHERE LOWER(email) = LOWER(p_email);
  IF v_id IS NOT NULL THEN
    -- Top up name if it was empty before.
    UPDATE people
       SET name = COALESCE(NULLIF(p_name, ''), name)
     WHERE id = v_id;
    RETURN v_id;
  END IF;

  INSERT INTO people (name, email)
    VALUES (COALESCE(NULLIF(p_name, ''), split_part(p_email, '@', 1)), p_email)
    RETURNING id INTO v_id;
  RETURN v_id;
END $$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3) Zero-auth claim: teach ---------------------------------------------------

CREATE OR REPLACE FUNCTION claim_teach_open(
  p_sunday_id UUID,
  p_name TEXT,
  p_email TEXT,
  p_title TEXT,
  p_description TEXT
) RETURNS TABLE (
  sunday_id UUID,
  sunday_date DATE,
  cancel_token TEXT
) AS $$
DECLARE
  v_person_id UUID;
  v_sunday sundays%ROWTYPE;
  v_signup role_signups%ROWTYPE;
  v_token TEXT;
BEGIN
  IF p_title IS NULL OR p_title = '' THEN RAISE EXCEPTION 'title_required'; END IF;
  v_person_id := _ensure_person_by_email(p_email, p_name);

  SELECT * INTO v_sunday FROM sundays WHERE id = p_sunday_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sunday_not_found'; END IF;
  IF v_sunday.teacher_signup_id IS NOT NULL THEN RAISE EXCEPTION 'teach_slot_taken'; END IF;
  IF v_sunday.date < CURRENT_DATE THEN RAISE EXCEPTION 'past_sunday'; END IF;
  IF v_sunday.status = 'cancelled' THEN RAISE EXCEPTION 'sunday_cancelled'; END IF;

  v_token := encode(gen_random_bytes(16), 'hex');

  INSERT INTO role_signups (
    person_id, role_type, status, intake_data,
    email, name, cancel_token, notified_at
  ) VALUES (
    v_person_id, 'teach', 'approved',
    jsonb_build_object('title', p_title, 'description', p_description, 'sunday_id', p_sunday_id),
    p_email, p_name, v_token, '{}'::jsonb
  ) RETURNING * INTO v_signup;

  UPDATE sundays SET
    teacher_signup_id = v_signup.id,
    status = 'booked',
    title = COALESCE(NULLIF(p_title, ''), title),
    description = COALESCE(NULLIF(p_description, ''), description)
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  RETURN QUERY SELECT v_sunday.id, v_sunday.date, v_token;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION claim_teach_open(UUID, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;


-- 4) Zero-auth claim: MC ------------------------------------------------------

CREATE OR REPLACE FUNCTION claim_mc_open(
  p_sunday_id UUID,
  p_name TEXT,
  p_email TEXT
) RETURNS TABLE (
  sunday_id UUID,
  sunday_date DATE,
  cancel_token TEXT
) AS $$
DECLARE
  v_person_id UUID;
  v_sunday sundays%ROWTYPE;
  v_signup role_signups%ROWTYPE;
  v_token TEXT;
  v_dup_id UUID;
BEGIN
  v_person_id := _ensure_person_by_email(p_email, p_name);

  SELECT * INTO v_sunday FROM sundays WHERE id = p_sunday_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sunday_not_found'; END IF;
  IF v_sunday.date < CURRENT_DATE THEN RAISE EXCEPTION 'past_sunday'; END IF;
  IF v_sunday.status = 'cancelled' THEN RAISE EXCEPTION 'sunday_cancelled'; END IF;

  -- Already MC'ing this Sunday under the same email? Return that signup's token.
  SELECT id INTO v_dup_id
    FROM role_signups
   WHERE id = ANY(v_sunday.space_holder_ids)
     AND person_id = v_person_id;
  IF v_dup_id IS NOT NULL THEN
    SELECT * INTO v_signup FROM role_signups WHERE id = v_dup_id;
    RETURN QUERY SELECT v_sunday.id, v_sunday.date, v_signup.cancel_token;
    RETURN;
  END IF;

  v_token := encode(gen_random_bytes(16), 'hex');

  INSERT INTO role_signups (
    person_id, role_type, status, intake_data,
    email, name, cancel_token, notified_at
  ) VALUES (
    v_person_id, 'hold_space', 'approved',
    jsonb_build_object('sunday_id', p_sunday_id),
    p_email, p_name, v_token, '{}'::jsonb
  ) RETURNING * INTO v_signup;

  UPDATE sundays
     SET space_holder_ids = array_append(space_holder_ids, v_signup.id)
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  RETURN QUERY SELECT v_sunday.id, v_sunday.date, v_token;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION claim_mc_open(UUID, TEXT, TEXT) TO anon, authenticated;


-- 5) Cancel by token ----------------------------------------------------------
-- Anyone with the token can cancel; it's a per-signup secret embedded in
-- the confirmation email. Returns a snapshot of what was cancelled so the
-- API endpoint can render the right "dropped from <date>" toast.

CREATE OR REPLACE FUNCTION cancel_with_token(p_token TEXT)
RETURNS TABLE (
  sunday_id UUID,
  sunday_date DATE,
  role_type TEXT,
  email TEXT,
  name TEXT,
  title TEXT
) AS $$
DECLARE
  v_signup role_signups%ROWTYPE;
  v_sunday_id UUID;
  v_sunday sundays%ROWTYPE;
BEGIN
  IF p_token IS NULL OR p_token = '' THEN RAISE EXCEPTION 'invalid_token'; END IF;

  SELECT * INTO v_signup FROM role_signups WHERE cancel_token = p_token;
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_token'; END IF;

  v_sunday_id := (v_signup.intake_data->>'sunday_id')::uuid;
  IF v_sunday_id IS NULL THEN RAISE EXCEPTION 'no_sunday_link'; END IF;

  SELECT * INTO v_sunday FROM sundays WHERE id = v_sunday_id FOR UPDATE;

  IF v_signup.role_type = 'teach' THEN
    UPDATE sundays
       SET teacher_signup_id = NULL,
           status = CASE WHEN array_length(space_holder_ids, 1) IS NULL THEN 'open' ELSE status END
     WHERE id = v_sunday_id;
  ELSIF v_signup.role_type = 'hold_space' THEN
    UPDATE sundays
       SET space_holder_ids = array_remove(space_holder_ids, v_signup.id)
     WHERE id = v_sunday_id;
  END IF;

  DELETE FROM role_signups WHERE id = v_signup.id;

  RETURN QUERY SELECT
    v_sunday.id, v_sunday.date, v_signup.role_type,
    v_signup.email, v_signup.name, v_signup.intake_data->>'title';
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION cancel_with_token(TEXT) TO anon, authenticated;


-- 6) Cron-side helpers --------------------------------------------------------
-- get_due_reminders('day7' | 'day1') returns rows that need a notification
-- of that kind, scoped to Sundays exactly 7 or 1 day from now (server UTC).
-- Skips already-notified rows via notified_at JSONB.

CREATE OR REPLACE FUNCTION get_due_reminders(p_kind TEXT)
RETURNS TABLE (
  signup_id UUID,
  sunday_id UUID,
  sunday_date DATE,
  sunday_title TEXT,
  sunday_description TEXT,
  role_type TEXT,
  email TEXT,
  name TEXT,
  cancel_token TEXT
) AS $$
DECLARE
  v_target_date DATE;
BEGIN
  IF p_kind = 'day7' THEN v_target_date := CURRENT_DATE + 7;
  ELSIF p_kind = 'day1' THEN v_target_date := CURRENT_DATE + 1;
  ELSE RAISE EXCEPTION 'invalid_kind';
  END IF;

  RETURN QUERY
  SELECT
    rs.id, s.id, s.date, s.title, s.description, rs.role_type,
    rs.email, rs.name, rs.cancel_token
  FROM role_signups rs
  JOIN sundays s ON s.id = (rs.intake_data->>'sunday_id')::uuid
  WHERE s.date = v_target_date
    AND s.status NOT IN ('cancelled', 'completed')
    AND rs.email IS NOT NULL
    AND rs.cancel_token IS NOT NULL
    AND COALESCE(rs.notified_at->>p_kind, '') = '';
END $$ LANGUAGE plpgsql SECURITY DEFINER;
-- service_role calls this via the cron endpoint; no public grants.


CREATE OR REPLACE FUNCTION mark_notified(p_signup_id UUID, p_kind TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE role_signups
     SET notified_at = COALESCE(notified_at, '{}'::jsonb)
                       || jsonb_build_object(p_kind, now())
   WHERE id = p_signup_id;
END $$ LANGUAGE plpgsql SECURITY DEFINER;


-- 7) Cancellation fanout helper ----------------------------------------------
-- When admin marks a Sunday cancelled, we need to email everyone signed up.
-- Returns the recipients; the API endpoint sends and then admin can flip
-- the status to 'cancelled'.

CREATE OR REPLACE FUNCTION get_signups_for_sunday(p_sunday_id UUID)
RETURNS TABLE (
  signup_id UUID,
  role_type TEXT,
  email TEXT,
  name TEXT,
  cancel_token TEXT
) AS $$
  SELECT
    rs.id, rs.role_type, rs.email, rs.name, rs.cancel_token
  FROM role_signups rs
  JOIN sundays s ON s.id = (rs.intake_data->>'sunday_id')::uuid
  WHERE s.id = p_sunday_id
    AND rs.email IS NOT NULL;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Recompute calendar with per-row "is this slot mine?" flags so the UI
-- only shows the action that actually applies. Drop the timezone-broken
-- < 1 day unclaim cutoff — members self-coordinate via chat.

DROP FUNCTION IF EXISTS get_upcoming_calendar(INT);

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
  is_my_teach BOOLEAN,
  mc_signups JSONB
) AS $$
DECLARE
  v_my_id UUID;
BEGIN
  SELECT p.id INTO v_my_id FROM people p WHERE p.auth_user_id = auth.uid();

  RETURN QUERY
  SELECT
    s.id, s.date, s.status, s.title, s.description, s.themes,
    s.teacher_signup_id,
    tp.name AS teacher_name,
    ts.intake_data->>'title' AS teacher_topic,
    (v_my_id IS NOT NULL AND ts.person_id = v_my_id) AS is_my_teach,
    COALESCE(
      (
        SELECT jsonb_agg(jsonb_build_object(
          'signup_id', ms.id,
          'name', mp.name,
          'is_me', (v_my_id IS NOT NULL AND ms.person_id = v_my_id)
        ))
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
END $$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION get_upcoming_calendar(INT) TO anon, authenticated;

-- Unclaim functions: remove the timezone-broken `< 1 day` guard.
-- Allow unclaim until the date itself is in the past.
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

  UPDATE sundays
     SET teacher_signup_id = NULL,
         status = CASE WHEN array_length(space_holder_ids, 1) IS NULL THEN 'open' ELSE status END
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  DELETE FROM role_signups WHERE id = v_signup.id;
  RETURN v_sunday;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

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

  SELECT id INTO v_signup_id FROM role_signups
    WHERE id = ANY(v_sunday.space_holder_ids) AND person_id = v_person.id;
  IF NOT FOUND THEN RAISE EXCEPTION 'not_your_slot'; END IF;

  UPDATE sundays
     SET space_holder_ids = array_remove(space_holder_ids, v_signup_id)
   WHERE id = p_sunday_id
   RETURNING * INTO v_sunday;

  DELETE FROM role_signups WHERE id = v_signup_id;
  RETURN v_sunday;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION unclaim_teach(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION unclaim_mc(UUID) TO authenticated;

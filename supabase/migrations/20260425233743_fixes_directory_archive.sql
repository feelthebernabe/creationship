-- 1) used_by fix: only single-use codes (max_uses=1) should ever set used_by.
--    Multi-use codes (master with max_uses=NULL or any max_uses != 1) leave
--    it alone. The invitation_redemptions ledger is the source of truth.
CREATE OR REPLACE FUNCTION redeem_invite(p_token TEXT) RETURNS people AS $$
DECLARE
  v_invite invitations%ROWTYPE;
  v_person people%ROWTYPE;
  v_user_id UUID := auth.uid();
  v_inviter_uuid UUID;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'not_authenticated'; END IF;

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

  IF v_invite.created_by = v_person.id::text THEN
    RAISE EXCEPTION 'self_redemption';
  END IF;

  BEGIN
    INSERT INTO invitation_redemptions (invitation_id, redeemed_by)
      VALUES (v_invite.id, v_person.id);
  EXCEPTION WHEN unique_violation THEN
    SELECT * INTO v_person FROM people WHERE id = v_person.id;
    RETURN v_person;
  END;

  -- ★ fix: only single-use codes get a used_by stamp.
  UPDATE invitations
     SET use_count = use_count + 1,
         used_by = CASE WHEN max_uses = 1 THEN v_person.id ELSE used_by END
   WHERE id = v_invite.id;

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


-- 2) Public member directory.
--    Returns name, when they joined, and inviter name. Visible to anon.
CREATE OR REPLACE FUNCTION get_member_directory()
RETURNS TABLE (
  id UUID,
  name TEXT,
  approved_at TIMESTAMPTZ,
  invited_by_name TEXT,
  invites_remaining INT
) AS $$
  SELECT
    p.id,
    p.name,
    p.approved_at,
    inv.name AS invited_by_name,
    p.invites_remaining
  FROM people p
  LEFT JOIN people inv ON inv.id = p.approved_by
  WHERE p.approved_at IS NOT NULL
  ORDER BY p.approved_at ASC;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION get_member_directory() TO anon, authenticated;


-- 3) Past Sundays archive — same shape as get_upcoming_calendar but
--    looking backwards. Public-readable.
CREATE OR REPLACE FUNCTION get_past_calendar(p_weeks INT DEFAULT 12)
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
  WHERE s.date < CURRENT_DATE
    AND s.date >= CURRENT_DATE - (p_weeks * 7)
  ORDER BY s.date DESC;
END $$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

GRANT EXECUTE ON FUNCTION get_past_calendar(INT) TO anon, authenticated;


-- 4) Admin: delete the two legacy test rows from pre-migration era.
--    These have auth_user_id IS NULL and were never linked to a real
--    auth.users entry. Only delete if both conditions hold.
DELETE FROM role_signups WHERE person_id IN (
  SELECT id FROM people WHERE auth_user_id IS NULL AND email IN ('test@example.com','test@creationship.org')
);
DELETE FROM people WHERE auth_user_id IS NULL AND email IN ('test@example.com','test@creationship.org');

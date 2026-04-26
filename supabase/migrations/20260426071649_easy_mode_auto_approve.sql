-- ============================================================
-- EASY MODE: auto-approve every magic-link sign-in.
-- Invite-code gating is dormant. The schema, RPCs, master code,
-- and per-member quotas all remain intact. To re-enable gating:
-- replace this function body with the pre-2026-04-26 version
-- (no UPDATE/COALESCE on approved_at in the email-match and
-- INSERT branches; let only redeem_invite() flip approved_at).
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

  -- Already linked to this auth user? Top up approval/quota if missing,
  -- then return as-is.
  SELECT * INTO v_person FROM people WHERE auth_user_id = v_user_id;
  IF FOUND THEN
    IF v_person.approved_at IS NULL THEN
      UPDATE people
         SET approved_at = now(),
             invites_remaining = GREATEST(invites_remaining, 2)
       WHERE id = v_person.id
       RETURNING * INTO v_person;
    END IF;
    RETURN v_person;
  END IF;

  -- Match an existing email-only row (legacy or admin-prepopulated).
  -- Stamp the auth_user_id and auto-approve.
  SELECT * INTO v_person FROM people WHERE LOWER(email) = LOWER(v_email);
  IF FOUND THEN
    UPDATE people
       SET auth_user_id = v_user_id,
           approved_at = COALESCE(approved_at, now()),
           invites_remaining = GREATEST(invites_remaining, 2)
     WHERE id = v_person.id
     RETURNING * INTO v_person;
    RETURN v_person;
  END IF;

  -- Fresh person. Auto-approve and grant the default quota.
  INSERT INTO people (auth_user_id, name, email, approved_at, invites_remaining)
    VALUES (v_user_id, split_part(v_email, '@', 1), v_email, now(), 2)
    RETURNING * INTO v_person;
  RETURN v_person;
END $$ LANGUAGE plpgsql SECURITY DEFINER;

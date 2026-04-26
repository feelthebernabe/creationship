-- ============================================================
-- get_my_active_signups: list everyone's upcoming claims by email
-- ============================================================
-- Powers the "lost your cancel link? enter your email" form on
-- calendar.html. Returns the cancel_token for each upcoming, non-
-- cancelled signup tied to the email.
--
-- IMPORTANT: cancel_tokens are sensitive. This function MUST NOT
-- be callable by anon — otherwise anyone could enumerate signups
-- by guessing emails and grab cancel links. The /api/resend-cancel-
-- links endpoint calls this with the service_role key, then emails
-- the tokens to the address (so they only reach the inbox owner).

CREATE OR REPLACE FUNCTION get_my_active_signups(p_email TEXT)
RETURNS TABLE (
  signup_id UUID,
  sunday_id UUID,
  sunday_date DATE,
  role_type TEXT,
  cancel_token TEXT,
  title TEXT
) AS $$
  SELECT
    rs.id,
    s.id,
    s.date,
    rs.role_type,
    rs.cancel_token,
    rs.intake_data->>'title'
  FROM role_signups rs
  JOIN sundays s ON s.id = (rs.intake_data->>'sunday_id')::uuid
  WHERE LOWER(rs.email) = LOWER(TRIM(p_email))
    AND s.date >= CURRENT_DATE
    AND s.status NOT IN ('cancelled', 'completed')
    AND rs.cancel_token IS NOT NULL
  ORDER BY s.date ASC;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- No GRANT to anon/authenticated — service_role only via the API endpoint.
REVOKE EXECUTE ON FUNCTION get_my_active_signups(TEXT) FROM PUBLIC;

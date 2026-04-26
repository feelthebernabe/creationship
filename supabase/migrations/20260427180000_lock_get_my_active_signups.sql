-- ============================================================
-- Lock get_my_active_signups properly.
--
-- The previous migration revoked from PUBLIC, but Supabase auto-grants
-- EXECUTE to anon, authenticated, and service_role on any new function.
-- Those explicit grants survive a `REVOKE FROM PUBLIC`. Same trap that
-- bit the member-directory revoke earlier.
--
-- Verification before this migration:
--   anon=X/postgres | authenticated=X/postgres | ...   (leaky)
-- After:
--   service_role=X/postgres | postgres=X/postgres      (locked)
-- ============================================================

REVOKE EXECUTE ON FUNCTION get_my_active_signups(TEXT) FROM anon, authenticated;

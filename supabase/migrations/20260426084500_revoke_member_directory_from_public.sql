-- Follow-up to 20260426084419_revoke_member_directory_public.sql.
--
-- The prior migration revoked EXECUTE from anon + authenticated, but the
-- RPC was still publicly callable — verified by curl returning HTTP 200
-- with the full member roster after the first revoke applied.
--
-- Root cause: Postgres functions default to GRANT EXECUTE TO PUBLIC.
-- anon / authenticated are members of PUBLIC and inherit that grant
-- regardless of explicit per-role grants. Revoking from the specific
-- roles is a no-op while PUBLIC still holds it.
--
-- Fix: revoke from PUBLIC. The prior REVOKEs are now redundant but
-- harmless; kept here for belt-and-suspenders clarity.

REVOKE EXECUTE ON FUNCTION get_member_directory() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION get_member_directory() FROM anon, authenticated;

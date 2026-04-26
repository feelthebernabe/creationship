-- Revoke public + authenticated EXECUTE on get_member_directory().
--
-- Why: members.html is being unshipped (excluded via .vercelignore + nav
-- links commented). The RPC is a separate exposure surface — anyone holding
-- the public anon key (which is hardcoded in data.js, visible to every
-- visitor) could call it directly via Supabase REST and dump the member
-- roster + inviter chain. Revoking the grants closes that surface.
--
-- The function definition stays in place. To re-enable, run a follow-up
-- migration that re-grants EXECUTE to whichever roles you want.

REVOKE EXECUTE ON FUNCTION get_member_directory() FROM anon, authenticated;

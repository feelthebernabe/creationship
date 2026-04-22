-- ============================================================
-- PHASE 3 SCHEMA MIGRATION
-- Adds display_name + slug to the ideas table.
--
-- HOW TO RUN:
--   1. Supabase dashboard → SQL Editor → New query
--   2. Paste this file
--   3. Click "Run"
--   4. Expect: "Success. No rows returned" (may show 2+ notices)
--
-- Idempotent — safe to run multiple times.
-- ============================================================

-- How the public page shows this contributor. Default-empty; the
-- render layer falls back to a computed "First L." initials form
-- from author_name when empty.
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS display_name text DEFAULT '';

-- URL slug for per-project permalinks (/projects.html?p=<slug>).
-- Populated by client at insert time; server retries with -2 suffix
-- on unique-constraint collision.
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS slug text DEFAULT '';

-- Uniqueness only applies to non-empty slugs — lets existing rows
-- coexist before backfill.
CREATE UNIQUE INDEX IF NOT EXISTS ideas_slug_unique
  ON ideas (slug)
  WHERE slug <> '';

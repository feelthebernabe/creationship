-- ============================================================
-- PHASE 3 BACKFILL
-- Populates display_name + slug on the 18 already-imported rows.
--
-- WHEN TO RUN: if you already ran the original bulk-import SQL
-- BEFORE the display_name + slug columns existed. If you're
-- starting fresh, just run the updated scripts/bulk-import-projects.sql
-- instead — it already includes these columns.
--
-- PRE-REQ: display-and-slug-migration.sql must have run first.
--
-- HOW TO RUN:
--   1. Supabase dashboard → SQL Editor → New query
--   2. Paste this file
--   3. Click "Run"
--   4. Expect: 18 UPDATE rows, 0 errors
--
-- Matches by exact title. Idempotent — re-running is a no-op
-- since each UPDATE just re-writes the same values.
-- ============================================================

UPDATE ideas SET display_name = 'Michelle',      slug = 'mbt-therapist-bot'              WHERE title = 'MBT Therapist Bot';
UPDATE ideas SET display_name = 'Benjamin W.',   slug = 'vibe-parties'                   WHERE title = 'Vibe Parties';
UPDATE ideas SET display_name = 'Benjamin W.',   slug = 'caravan-of-dreams-website'      WHERE title = 'Caravan of Dreams Website';
UPDATE ideas SET display_name = 'Michelle',      slug = 'kula-evolver-exchange'          WHERE title = 'Kula (Evolver Exchange)';
UPDATE ideas SET display_name = 'Sal',           slug = 'hackathon-dynamics-complexity-models' WHERE title = 'Hackathon Dynamics / Complexity Models';
UPDATE ideas SET display_name = 'Sal',           slug = 'vibe-cadaver'                   WHERE title = 'Vibe Cadaver';
UPDATE ideas SET display_name = 'Aaron R.',      slug = 'ocean-agentics'                 WHERE title = 'Ocean Agentics';
UPDATE ideas SET display_name = 'Hope E.',       slug = 'the-medical-collective'         WHERE title = 'The Medical Collective';
UPDATE ideas SET display_name = 'the group',    slug = 'ai-doc-afterparty'              WHERE title = 'AI Doc Afterparty';
UPDATE ideas SET display_name = 'Vincent',       slug = 'speech-pathology-ai'            WHERE title = 'Speech Pathology AI';
UPDATE ideas SET display_name = 'Vincent',       slug = 'recipe-engineer'                WHERE title = 'Recipe Engineer';
UPDATE ideas SET display_name = 'Michelle',      slug = 'kittyshare-kitty-fund'          WHERE title = 'KittyShare / Kitty Fund';
UPDATE ideas SET display_name = 'Hannah L.',     slug = 'first-thought-best-thought'     WHERE title = 'First Thought Best Thought';
UPDATE ideas SET display_name = 'Josh Y.',       slug = 'notamazon'                      WHERE title = 'NotAmazon';
UPDATE ideas SET display_name = 'Benjamin W.',   slug = 'cause-compass'                  WHERE title = 'Cause Compass';
UPDATE ideas SET display_name = 'Charlotte B.',  slug = 'earth-day-salon'                WHERE title = 'Earth Day Salon';
UPDATE ideas SET display_name = 'Danielle G.',   slug = 'demilitarise-education-ux'      WHERE title = 'Demilitarise Education UX';
UPDATE ideas SET display_name = 'Danielle G.',   slug = 'metagov-governance-visualization' WHERE title = 'Metagov Governance Visualization';

-- Sanity check — should return all 18 with populated values
SELECT title, display_name, slug FROM ideas
WHERE slug IN (
  'mbt-therapist-bot','vibe-parties','caravan-of-dreams-website','kula-evolver-exchange',
  'hackathon-dynamics-complexity-models','vibe-cadaver','ocean-agentics','the-medical-collective',
  'ai-doc-afterparty','speech-pathology-ai','recipe-engineer','kittyshare-kitty-fund',
  'first-thought-best-thought','notamazon','cause-compass','earth-day-salon',
  'demilitarise-education-ux','metagov-governance-visualization'
)
ORDER BY title;

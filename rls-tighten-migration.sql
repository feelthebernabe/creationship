-- ============================================================
-- THE CREATIONSHIP — RLS POLICY TIGHTENING
-- Restricts read access on sensitive tables
-- Run this in Supabase SQL Editor
-- ============================================================

-- ============================
-- PEOPLE TABLE
-- Only service_role (admin) can read all people
-- Anon users can only INSERT (to sign up)
-- ============================

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Allow all operations for now" ON people;
DROP POLICY IF EXISTS "Allow public read" ON people;
DROP POLICY IF EXISTS "Allow public insert" ON people;
DROP POLICY IF EXISTS "Allow public update" ON people;

-- Ensure RLS is enabled
ALTER TABLE people ENABLE ROW LEVEL SECURITY;

-- Anyone can sign up (insert themselves)
CREATE POLICY "Allow public insert on people"
  ON people FOR INSERT
  WITH CHECK (true);

-- Only authenticated users can read people
CREATE POLICY "Allow authenticated read on people"
  ON people FOR SELECT
  USING (auth.role() = 'authenticated');

-- ============================
-- ROLE_SIGNUPS TABLE
-- Anon can INSERT (submit a signup)
-- Only authenticated can read/update
-- ============================

DROP POLICY IF EXISTS "Allow all operations for now" ON role_signups;
DROP POLICY IF EXISTS "Allow public read" ON role_signups;
DROP POLICY IF EXISTS "Allow public insert" ON role_signups;
DROP POLICY IF EXISTS "Allow public update" ON role_signups;

ALTER TABLE role_signups ENABLE ROW LEVEL SECURITY;

-- Anyone can submit a signup
CREATE POLICY "Allow public insert on role_signups"
  ON role_signups FOR INSERT
  WITH CHECK (true);

-- Only authenticated users can read signups
CREATE POLICY "Allow authenticated read on role_signups"
  ON role_signups FOR SELECT
  USING (auth.role() = 'authenticated');

-- Only authenticated users can update signups (admin status changes)
CREATE POLICY "Allow authenticated update on role_signups"
  ON role_signups FOR UPDATE
  USING (auth.role() = 'authenticated');

-- ============================
-- SUNDAYS TABLE
-- Public can read (to see schedule)
-- Only authenticated can insert/update
-- ============================

DROP POLICY IF EXISTS "Allow all operations for now" ON sundays;
DROP POLICY IF EXISTS "Allow public read" ON sundays;
DROP POLICY IF EXISTS "Allow public insert" ON sundays;
DROP POLICY IF EXISTS "Allow public update" ON sundays;

ALTER TABLE sundays ENABLE ROW LEVEL SECURITY;

-- Anyone can see the schedule
CREATE POLICY "Allow public read on sundays"
  ON sundays FOR SELECT
  USING (true);

-- Only authenticated can modify the calendar
CREATE POLICY "Allow authenticated insert on sundays"
  ON sundays FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated update on sundays"
  ON sundays FOR UPDATE
  USING (auth.role() = 'authenticated');

-- ============================
-- PLAYLIST_SUGGESTIONS TABLE
-- Public can read and insert
-- Only authenticated can update/delete
-- ============================

DROP POLICY IF EXISTS "Allow all operations" ON playlist_suggestions;
DROP POLICY IF EXISTS "Allow public read" ON playlist_suggestions;
DROP POLICY IF EXISTS "Allow public insert" ON playlist_suggestions;
DROP POLICY IF EXISTS "Allow public update" ON playlist_suggestions;
DROP POLICY IF EXISTS "Allow public delete" ON playlist_suggestions;
DROP POLICY IF EXISTS "Anyone can read suggestions" ON playlist_suggestions;
DROP POLICY IF EXISTS "Anyone can add suggestions" ON playlist_suggestions;
DROP POLICY IF EXISTS "Authenticated users can update suggestions" ON playlist_suggestions;

ALTER TABLE playlist_suggestions ENABLE ROW LEVEL SECURITY;

-- Anyone can see and add suggestions
CREATE POLICY "Allow public read on playlist_suggestions"
  ON playlist_suggestions FOR SELECT
  USING (true);

CREATE POLICY "Allow public insert on playlist_suggestions"
  ON playlist_suggestions FOR INSERT
  WITH CHECK (true);

-- Only authenticated can update/delete suggestions
CREATE POLICY "Allow authenticated update on playlist_suggestions"
  ON playlist_suggestions FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated delete on playlist_suggestions"
  ON playlist_suggestions FOR DELETE
  USING (auth.role() = 'authenticated');

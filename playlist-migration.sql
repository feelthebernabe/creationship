-- ============================================================
-- THE CREATIONSHIP — PLAYLIST SUGGESTIONS TABLE
-- Run this in Supabase SQL Editor
-- ============================================================

CREATE TABLE IF NOT EXISTS playlist_suggestions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  song_title text NOT NULL,
  artist text NOT NULL,
  suggested_by text NOT NULL,
  reason text DEFAULT '',
  spotify_link text DEFAULT '',
  status text DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'added', 'declined')),
  created_at timestamptz DEFAULT now()
);

-- No RLS — public read/write via anon key (same as signups)
ALTER TABLE playlist_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read suggestions" ON playlist_suggestions
  FOR SELECT USING (true);

CREATE POLICY "Anyone can insert suggestions" ON playlist_suggestions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update suggestions" ON playlist_suggestions
  FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete suggestions" ON playlist_suggestions
  FOR DELETE USING (true);

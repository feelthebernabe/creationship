-- ============================================================
-- THE CREATIONSHIP — IDEAS TABLE
-- Run this in Supabase SQL Editor
-- ============================================================

-- Ideas table
CREATE TABLE IF NOT EXISTS ideas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id) NOT NULL,
  author_name text NOT NULL DEFAULT '',
  author_email text NOT NULL,
  title text NOT NULL,
  description text DEFAULT '',
  status text DEFAULT 'open' CHECK (status IN ('open', 'discussed', 'building', 'shipped', 'archived')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;

-- Everyone (including anon for admin dashboard) can read ideas
CREATE POLICY "Anyone can read ideas" ON ideas
  FOR SELECT USING (true);

-- Authenticated users can insert their own ideas
CREATE POLICY "Auth users can insert own ideas" ON ideas
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own ideas
CREATE POLICY "Users can update own ideas" ON ideas
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

-- Users can delete their own ideas
CREATE POLICY "Users can delete own ideas" ON ideas
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

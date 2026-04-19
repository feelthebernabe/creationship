-- ============================================================
-- CHURCH OF CREATIONSHIPS — IDEAS TABLE V2
-- Adds: github_url, website_url, demo_url, team_members
-- Run this in Supabase SQL Editor
-- ============================================================

-- Add new columns to the existing ideas table
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS github_url text DEFAULT '';
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS website_url text DEFAULT '';
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS demo_url text DEFAULT '';
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS team_members jsonb DEFAULT '[]'::jsonb;

-- team_members stores an array of objects like:
-- [{"name": "Michelle"}, {"name": "Alex"}]

-- ============================================================
-- THE CREATIONSHIP — Supabase Schema
-- Run this in the Supabase SQL Editor for your project
-- ============================================================

-- People table
CREATE TABLE IF NOT EXISTS people (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  phone TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create unique index on email (lowercase)
CREATE UNIQUE INDEX IF NOT EXISTS people_email_unique ON people (LOWER(email));

-- Role signups table
CREATE TABLE IF NOT EXISTS role_signups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  person_id UUID REFERENCES people(id) ON DELETE CASCADE,
  role_type TEXT NOT NULL CHECK (role_type IN ('hold_space', 'teach', 'brain_trust')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_review', 'approved', 'declined', 'completed')),
  intake_data JSONB DEFAULT '{}',
  reviewed_by TEXT,
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Sundays table
CREATE TABLE IF NOT EXISTS sundays (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE UNIQUE NOT NULL,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'booked', 'completed', 'cancelled')),
  teacher_signup_id UUID REFERENCES role_signups(id),
  space_holder_ids UUID[] DEFAULT '{}',
  title TEXT DEFAULT '',
  description TEXT DEFAULT '',
  recording_url TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  themes TEXT[] DEFAULT '{}'
);

-- Invitations table (for future community-gating)
CREATE TABLE IF NOT EXISTS invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  token TEXT UNIQUE NOT NULL,
  created_by TEXT,
  used_by UUID REFERENCES people(id),
  role_hint TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- For v0: permissive policies. The admin password gate
-- provides basic access control. Replace with Supabase Auth
-- (magic links) in v0.5.
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_signups ENABLE ROW LEVEL SECURITY;
ALTER TABLE sundays ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- People: anyone can insert (signup form), anyone can read (admin)
CREATE POLICY "Allow public insert on people" ON people
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select on people" ON people
  FOR SELECT USING (true);
CREATE POLICY "Allow public update on people" ON people
  FOR UPDATE USING (true);

-- Role signups: anyone can insert, anyone can read/update
CREATE POLICY "Allow public insert on role_signups" ON role_signups
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public select on role_signups" ON role_signups
  FOR SELECT USING (true);
CREATE POLICY "Allow public update on role_signups" ON role_signups
  FOR UPDATE USING (true);

-- Sundays: full access
CREATE POLICY "Allow public all on sundays" ON sundays
  FOR ALL USING (true) WITH CHECK (true);

-- Invitations: full access
CREATE POLICY "Allow public all on invitations" ON invitations
  FOR ALL USING (true) WITH CHECK (true);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_signups_role ON role_signups(role_type);
CREATE INDEX IF NOT EXISTS idx_signups_status ON role_signups(status);
CREATE INDEX IF NOT EXISTS idx_signups_person ON role_signups(person_id);
CREATE INDEX IF NOT EXISTS idx_sundays_date ON sundays(date);

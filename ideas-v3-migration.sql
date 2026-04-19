-- ============================================================
-- CREATIONSHIP — IDEAS V3: LIFECYCLE STAGES
-- Adds: stage (seed/project/company), company_name
-- Updates: status constraint to include new stages
-- Run this in Supabase SQL Editor
-- ============================================================

-- Add stage column (seed → project → company)
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS stage text DEFAULT 'seed'
  CHECK (stage IN ('seed', 'project', 'company'));

-- Add company name for when an idea becomes a company
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS company_name text DEFAULT '';

-- Drop old status constraint so we can leave it flexible
-- (status is now separate from stage — status tracks 'active', 'paused', 'archived')
ALTER TABLE ideas DROP CONSTRAINT IF EXISTS ideas_status_check;
ALTER TABLE ideas ALTER COLUMN status SET DEFAULT 'active';

-- Update any existing 'open' statuses to 'active'
UPDATE ideas SET status = 'active' WHERE status = 'open';
UPDATE ideas SET status = 'active' WHERE status = 'discussed';
UPDATE ideas SET status = 'active' WHERE status = 'building';
UPDATE ideas SET status = 'active' WHERE status = 'shipped';

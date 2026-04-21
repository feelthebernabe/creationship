-- ============================================================
-- BULK IMPORT — 18 projects extracted from the Church of
-- Creationship WhatsApp group (Feb 13 – Apr 21, 2026).
--
-- HOW TO RUN (zero edits needed):
--   1. Supabase dashboard → SQL Editor → New query
--   2. Paste this entire file
--   3. Click "Run"
--   4. Expect: "Success. 18 rows" and the sanity-check counts
--
-- The user_id auto-looks up Michelle's account from auth.users
-- via the email below. Change the email in the CTE if a
-- different account should own these rows.
--
-- NOTE: Supabase SQL Editor runs as the postgres superuser,
-- bypassing RLS — no service role key needed for this path.
-- ============================================================

WITH me AS (
  SELECT id FROM auth.users WHERE email = 'tracymacuga@gmail.com' LIMIT 1
)
INSERT INTO ideas
  (user_id, author_name, author_email, title, description,
   github_url, website_url, demo_url, team_members,
   stage, company_name, status)
SELECT
  (SELECT id FROM me),
  v.author_name, '', v.title, v.description,
  v.github_url, v.website_url, v.demo_url, v.team_members::jsonb,
  v.stage, '', 'active'
FROM (VALUES
  ('Michelle', 'MBT Therapist Bot',
   'AI therapist trained on Mentalization-Based Therapy manuals. Relentlessly curious, deliberately not-knowing stance. Grounded in Bateman & Fonagy.',
   '', '', '', '[]', 'seed'),

  ('Benjamin Von Wong', 'Vibe Parties',
   'A site for hosting vibe parties, shipped rapidly post-hackathon with a tutorial flow.',
   '', 'https://vibe-parties.web.app', 'https://vibe-parties.web.app/101',
   '[{"name":"Brandon Levy"}]', 'project'),

  ('Benjamin Von Wong', 'Caravan of Dreams Website',
   'Demo site for Caravan of Dreams focused on nourishing mind and body — prototype for a living community restaurant/space.',
   '', 'https://caravan-of-dreams.vercel.app', '',
   '[{"name":"Brandon Levy"},{"name":"Angel"}]', 'project'),

  ('Michelle', 'Kula (Evolver Exchange)',
   'A peer-to-peer reputation-based sharing network inspired by the Kula ring gift exchange. Disruptively independent p2p economy.',
   '', 'https://kula-ten.vercel.app/', 'https://kula-ten.vercel.app/feed',
   '[{"name":"Sal"},{"name":"Daniel Pinchbeck"},{"name":"Nikita"},{"name":"Charlotte Binns"},{"name":"Hope Endrenyi"}]', 'project'),

  ('Sal', 'Hackathon Dynamics / Complexity Models',
   'Interactive models exploring what makes a "deepening" hackathon different from a traditional tech hackathon.',
   '', 'https://slvtrs.com/complexity/hackathon.html', 'https://slvtrs.com/complexity',
   '[]', 'project'),

  ('Sal', 'Vibe Cadaver',
   'A vibesite that rewrites itself with communal input, in the spirit of exquisite corpse.',
   '', 'https://vibecadaver.slvtrs.com/', '',
   '[]', 'seed'),

  ('Aaron Roan', 'Ocean Agentics',
   'AI-generated hub on the High Seas Treaty / BBNJ. Ocean conservation × tech.',
   '', 'https://oceanagentics.com', '',
   '[]', 'project'),

  ('Hope Endrenyi', 'The Medical Collective',
   'Platform for medical innovation / healthcare design — experience design coursework with product potential.',
   '', 'https://the-medical-collective.web.app/', '',
   '[]', 'project'),

  ('group watch', 'AI Doc Afterparty',
   'Film/event about AI doctors — group planned watch party.',
   '', 'https://the-ai-doc-nyc.web.app/', '',
   '[]', 'project'),

  ('Vincent', 'Speech Pathology AI',
   'Locally-hosted LLM that coaches Parkinson''s patients on speech exercises. Applicable beyond Parkinson''s.',
   '', 'https://speechpath.lovable.app/', '',
   '[]', 'project'),

  ('Vincent', 'Recipe Engineer',
   'Reverse-engineers cooking videos into recipes. Immediate use: a Caravan cookbook. Long-term: capturing familial recipes.',
   '', 'https://recipeengineer.lovable.app/', '',
   '[]', 'project'),

  ('Michelle', 'KittyShare / Kitty Fund',
   'Community savings / mutual aid fund. Phase 1 web-accessible; Phase 2 adds social + mission-driven events.',
   '', 'https://kittyshare.pages.dev', 'https://funfund-38f.pages.dev',
   '[{"name":"Sahil"}]', 'project'),

  ('Hannah Levinson', 'First Thought Best Thought',
   'Mobile game inspired by Burroughs'' "first thought best thought" principle. TestFlight coming.',
   '', 'https://firstthoughtbestthought.netlify.app/', '',
   '[{"name":"Maya"}]', 'project'),

  ('Josh Y', 'NotAmazon',
   'Find the same goods Amazon sells at local stores/farmers markets. AI scans store shelves; paste your Amazon list to find local alternatives.',
   'https://github.com/qix/not-amazon', '', 'https://not-amazon-production.up.railway.app/',
   '[{"name":"Hannah Levinson"},{"name":"Maya"}]', 'project'),

  ('Benjamin Von Wong', 'Cause Compass',
   'Volunteer matchmaker — chatbot intake builds a qualitative profile and matches people to causes. V1 prototype, buggy.',
   '', 'https://cause-compass-silk.vercel.app/', '',
   '[]', 'seed'),

  ('Charlotte Binns', 'Earth Day Salon',
   'Earth Day fireside salon on True Human, Gaia, protopic political imagination, embodied kinship consciousness.',
   '', 'https://www.viewcy.com/event/earth_day_salon', '',
   '[{"name":"Samantha Sweetwater"},{"name":"Daniel Pinchbeck"}]', 'company'),

  ('Danielle Gauthier', 'Demilitarise Education UX',
   'UX design making the Demilitarise Education site easier to navigate; improving treaty/policy readability.',
   '', '', '', '[]', 'project'),

  ('Danielle Gauthier', 'Metagov Governance Visualization',
   'Governance-gap visualization UI using sentiment research + ethnographic database for Metagov''s knowledge organization software.',
   '', '', '', '[]', 'project')
) AS v(author_name, title, description, github_url, website_url, demo_url, team_members, stage);

-- Sanity check — should show 18 rows split 3/13/2 across seed/project/company
SELECT stage, count(*) FROM ideas WHERE created_at >= now() - interval '5 minutes' GROUP BY stage ORDER BY stage;

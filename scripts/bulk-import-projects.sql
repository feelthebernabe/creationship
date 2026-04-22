-- ============================================================
-- BULK IMPORT — 18 projects extracted from the Church of
-- Creationship WhatsApp group (Feb 13 – Apr 21, 2026).
--
-- HOW TO RUN (zero edits needed):
--   1. First run scripts/display-and-slug-migration.sql so the
--      display_name + slug columns exist
--   2. Supabase dashboard → SQL Editor → New query
--   3. Paste this entire file
--   4. Click "Run"
--   5. Expect: "Success. No rows returned" for the INSERT and
--      the sanity-check breakdown below
--
-- The user_id auto-looks up the feelthebernabe@gmail.com auth
-- user. Change the email in the CTE if a different account
-- should own these rows.
--
-- Privacy note: author_name keeps the name as it appeared in
-- WhatsApp (record-of-truth). display_name is what the public
-- page shows — default "First L." initials. Contributors can
-- update their own display_name later via the Vault.
--
-- NOTE: Supabase SQL Editor runs as the postgres superuser,
-- bypassing RLS — no service role key needed for this path.
-- ============================================================

WITH me AS (
  SELECT id FROM auth.users WHERE email = 'feelthebernabe@gmail.com' LIMIT 1
)
INSERT INTO ideas
  (user_id, author_name, display_name, author_email, title, description,
   github_url, website_url, demo_url, team_members,
   stage, company_name, status, slug)
SELECT
  (SELECT id FROM me),
  v.author_name, v.display_name, '', v.title, v.description,
  v.github_url, v.website_url, v.demo_url, v.team_members::jsonb,
  v.stage, '', 'active', v.slug
FROM (VALUES
  ('Michelle', 'Michelle', 'MBT Therapist Bot', 'mbt-therapist-bot',
   'AI therapist trained on Mentalization-Based Therapy manuals. Relentlessly curious, deliberately not-knowing stance. Grounded in Bateman & Fonagy.',
   '', '', '', '[]', 'seed'),

  ('Benjamin Von Wong', 'Benjamin W.', 'Vibe Parties', 'vibe-parties',
   'A site for hosting vibe parties, shipped rapidly post-hackathon with a tutorial flow.',
   '', 'https://vibe-parties.web.app', 'https://vibe-parties.web.app/101',
   '[{"name":"Brandon Levy"}]', 'project'),

  ('Benjamin Von Wong', 'Benjamin W.', 'Caravan of Dreams Website', 'caravan-of-dreams-website',
   'Demo site for Caravan of Dreams focused on nourishing mind and body — prototype for a living community restaurant/space.',
   '', 'https://caravan-of-dreams.vercel.app', '',
   '[{"name":"Brandon Levy"},{"name":"Angel"}]', 'project'),

  ('Michelle', 'Michelle', 'Kula (Evolver Exchange)', 'kula-evolver-exchange',
   'A peer-to-peer reputation-based sharing network inspired by the Kula ring gift exchange. Disruptively independent p2p economy.',
   '', 'https://kula-ten.vercel.app/', 'https://kula-ten.vercel.app/feed',
   '[{"name":"Sal"},{"name":"Daniel Pinchbeck"},{"name":"Nikita"},{"name":"Charlotte Binns"},{"name":"Hope Endrenyi"}]', 'project'),

  ('Sal', 'Sal', 'Hackathon Dynamics / Complexity Models', 'hackathon-dynamics-complexity-models',
   'Interactive models exploring what makes a "deepening" hackathon different from a traditional tech hackathon.',
   '', 'https://slvtrs.com/complexity/hackathon.html', 'https://slvtrs.com/complexity',
   '[]', 'project'),

  ('Sal', 'Sal', 'Vibe Cadaver', 'vibe-cadaver',
   'A vibesite that rewrites itself with communal input, in the spirit of exquisite corpse.',
   '', 'https://vibecadaver.slvtrs.com/', '',
   '[]', 'seed'),

  ('Aaron Roan', 'Aaron R.', 'Ocean Agentics', 'ocean-agentics',
   'AI-generated hub on the High Seas Treaty / BBNJ. Ocean conservation × tech.',
   '', 'https://oceanagentics.com', '',
   '[]', 'project'),

  ('Hope Endrenyi', 'Hope E.', 'The Medical Collective', 'the-medical-collective',
   'Platform for medical innovation / healthcare design — experience design coursework with product potential.',
   '', 'https://the-medical-collective.web.app/', '',
   '[]', 'project'),

  ('group watch', 'the group', 'AI Doc Afterparty', 'ai-doc-afterparty',
   'Film/event about AI doctors — group planned watch party.',
   '', 'https://the-ai-doc-nyc.web.app/', '',
   '[]', 'project'),

  ('Vincent', 'Vincent', 'Speech Pathology AI', 'speech-pathology-ai',
   'Locally-hosted LLM that coaches Parkinson''s patients on speech exercises. Applicable beyond Parkinson''s.',
   '', 'https://speechpath.lovable.app/', '',
   '[]', 'project'),

  ('Vincent', 'Vincent', 'Recipe Engineer', 'recipe-engineer',
   'Reverse-engineers cooking videos into recipes. Immediate use: a Caravan cookbook. Long-term: capturing familial recipes.',
   '', 'https://recipeengineer.lovable.app/', '',
   '[]', 'project'),

  ('Michelle', 'Michelle', 'KittyShare / Kitty Fund', 'kittyshare-kitty-fund',
   'Community savings / mutual aid fund. Phase 1 web-accessible; Phase 2 adds social + mission-driven events.',
   '', 'https://kittyshare.pages.dev', 'https://funfund-38f.pages.dev',
   '[{"name":"Sahil"}]', 'project'),

  ('Hannah Levinson', 'Hannah L.', 'First Thought Best Thought', 'first-thought-best-thought',
   'Mobile game inspired by Burroughs'' "first thought best thought" principle. TestFlight coming.',
   '', 'https://firstthoughtbestthought.netlify.app/', '',
   '[{"name":"Maya"}]', 'project'),

  ('Josh Y', 'Josh Y.', 'NotAmazon', 'notamazon',
   'Find the same goods Amazon sells at local stores/farmers markets. AI scans store shelves; paste your Amazon list to find local alternatives.',
   'https://github.com/qix/not-amazon', '', 'https://not-amazon-production.up.railway.app/',
   '[{"name":"Hannah Levinson"},{"name":"Maya"}]', 'project'),

  ('Benjamin Von Wong', 'Benjamin W.', 'Cause Compass', 'cause-compass',
   'Volunteer matchmaker — chatbot intake builds a qualitative profile and matches people to causes. V1 prototype, buggy.',
   '', 'https://cause-compass-silk.vercel.app/', '',
   '[]', 'seed'),

  ('Charlotte Binns', 'Charlotte B.', 'Earth Day Salon', 'earth-day-salon',
   'Earth Day fireside salon on True Human, Gaia, protopic political imagination, embodied kinship consciousness.',
   '', 'https://www.viewcy.com/event/earth_day_salon', '',
   '[{"name":"Samantha Sweetwater"},{"name":"Daniel Pinchbeck"}]', 'company'),

  ('Danielle Gauthier', 'Danielle G.', 'Demilitarise Education UX', 'demilitarise-education-ux',
   'UX design making the Demilitarise Education site easier to navigate; improving treaty/policy readability.',
   '', '', '', '[]', 'project'),

  ('Danielle Gauthier', 'Danielle G.', 'Metagov Governance Visualization', 'metagov-governance-visualization',
   'Governance-gap visualization UI using sentiment research + ethnographic database for Metagov''s knowledge organization software.',
   '', '', '', '[]', 'project')
) AS v(author_name, display_name, title, slug, description, github_url, website_url, demo_url, team_members, stage);

-- Sanity check — should show 18 rows split 3/13/2 across seed/project/company
SELECT stage, count(*) FROM ideas WHERE created_at >= now() - interval '5 minutes' GROUP BY stage ORDER BY stage;

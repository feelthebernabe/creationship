-- ============================================================
-- BULK IMPORT — 18 projects extracted from the Church of
-- Creationship WhatsApp group (Feb 13 – Apr 21, 2026).
--
-- HOW TO RUN:
--   1. Supabase dashboard → SQL Editor → New query
--   2. Find your user UUID with this query first:
--        SELECT id, email FROM auth.users WHERE email = 'tracymacuga@gmail.com';
--   3. Replace <YOUR_USER_ID> below (single find/replace) with that UUID
--   4. Click "Run"
--   5. Expect: "Success. 18 rows" in the results pane
--
-- NOTE: Supabase SQL Editor runs as the postgres superuser,
-- bypassing RLS — no service role key needed for this path.
-- ============================================================

INSERT INTO ideas (user_id, author_name, author_email, title, description, github_url, website_url, demo_url, team_members, stage, company_name, status)
VALUES
  ('<YOUR_USER_ID>', 'Michelle', '', 'MBT Therapist Bot',
    'AI therapist trained on Mentalization-Based Therapy manuals. Relentlessly curious, deliberately not-knowing stance. Grounded in Bateman & Fonagy.',
    '', '', '', '[]'::jsonb, 'seed', '', 'active'),

  ('<YOUR_USER_ID>', 'Benjamin Von Wong', '', 'Vibe Parties',
    'A site for hosting vibe parties, shipped rapidly post-hackathon with a tutorial flow.',
    '', 'https://vibe-parties.web.app', 'https://vibe-parties.web.app/101',
    '[{"name":"Brandon Levy"}]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Benjamin Von Wong', '', 'Caravan of Dreams Website',
    'Demo site for Caravan of Dreams focused on nourishing mind and body — prototype for a living community restaurant/space.',
    '', 'https://caravan-of-dreams.vercel.app', '',
    '[{"name":"Brandon Levy"},{"name":"Angel"}]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Michelle', '', 'Kula (Evolver Exchange)',
    'A peer-to-peer reputation-based sharing network inspired by the Kula ring gift exchange. Disruptively independent p2p economy.',
    '', 'https://kula-ten.vercel.app/', 'https://kula-ten.vercel.app/feed',
    '[{"name":"Sal"},{"name":"Daniel Pinchbeck"},{"name":"Nikita"},{"name":"Charlotte Binns"},{"name":"Hope Endrenyi"}]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Sal', '', 'Hackathon Dynamics / Complexity Models',
    'Interactive models exploring what makes a "deepening" hackathon different from a traditional tech hackathon.',
    '', 'https://slvtrs.com/complexity/hackathon.html', 'https://slvtrs.com/complexity',
    '[]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Sal', '', 'Vibe Cadaver',
    'A vibesite that rewrites itself with communal input, in the spirit of exquisite corpse.',
    '', 'https://vibecadaver.slvtrs.com/', '',
    '[]'::jsonb, 'seed', '', 'active'),

  ('<YOUR_USER_ID>', 'Aaron Roan', '', 'Ocean Agentics',
    'AI-generated hub on the High Seas Treaty / BBNJ. Ocean conservation × tech.',
    '', 'https://oceanagentics.com', '',
    '[]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Hope Endrenyi', '', 'The Medical Collective',
    'Platform for medical innovation / healthcare design — experience design coursework with product potential.',
    '', 'https://the-medical-collective.web.app/', '',
    '[]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'group watch', '', 'AI Doc Afterparty',
    'Film/event about AI doctors — group planned watch party.',
    '', 'https://the-ai-doc-nyc.web.app/', '',
    '[]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Vincent', '', 'Speech Pathology AI',
    'Locally-hosted LLM that coaches Parkinson''s patients on speech exercises. Applicable beyond Parkinson''s.',
    '', 'https://speechpath.lovable.app/', '',
    '[]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Vincent', '', 'Recipe Engineer',
    'Reverse-engineers cooking videos into recipes. Immediate use: a Caravan cookbook. Long-term: capturing familial recipes.',
    '', 'https://recipeengineer.lovable.app/', '',
    '[]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Michelle', '', 'KittyShare / Kitty Fund',
    'Community savings / mutual aid fund. Phase 1 web-accessible; Phase 2 adds social + mission-driven events.',
    '', 'https://kittyshare.pages.dev', 'https://funfund-38f.pages.dev',
    '[{"name":"Sahil"}]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Hannah Levinson', '', 'First Thought Best Thought',
    'Mobile game inspired by Burroughs'' "first thought best thought" principle. TestFlight coming.',
    '', 'https://firstthoughtbestthought.netlify.app/', '',
    '[{"name":"Maya"}]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Josh Y', '', 'NotAmazon',
    'Find the same goods Amazon sells at local stores/farmers markets. AI scans store shelves; paste your Amazon list to find local alternatives.',
    'https://github.com/qix/not-amazon', '', 'https://not-amazon-production.up.railway.app/',
    '[{"name":"Hannah Levinson"},{"name":"Maya"}]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Benjamin Von Wong', '', 'Cause Compass',
    'Volunteer matchmaker — chatbot intake builds a qualitative profile and matches people to causes. V1 prototype, buggy.',
    '', 'https://cause-compass-silk.vercel.app/', '',
    '[]'::jsonb, 'seed', '', 'active'),

  ('<YOUR_USER_ID>', 'Charlotte Binns', '', 'Earth Day Salon',
    'Earth Day fireside salon on True Human, Gaia, protopic political imagination, embodied kinship consciousness.',
    '', 'https://www.viewcy.com/event/earth_day_salon', '',
    '[{"name":"Samantha Sweetwater"},{"name":"Daniel Pinchbeck"}]'::jsonb, 'company', '', 'active'),

  ('<YOUR_USER_ID>', 'Danielle Gauthier', '', 'Demilitarise Education UX',
    'UX design making the Demilitarise Education site easier to navigate; improving treaty/policy readability.',
    '', '', '', '[]'::jsonb, 'project', '', 'active'),

  ('<YOUR_USER_ID>', 'Danielle Gauthier', '', 'Metagov Governance Visualization',
    'Governance-gap visualization UI using sentiment research + ethnographic database for Metagov''s knowledge organization software.',
    '', '', '', '[]'::jsonb, 'project', '', 'active');

-- Sanity check — should return 18 with stage breakdown 3/13/2 (seed/project/company)
SELECT stage, count(*) FROM ideas WHERE created_at >= now() - interval '5 minutes' GROUP BY stage;

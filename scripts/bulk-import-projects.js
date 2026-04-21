#!/usr/bin/env node
// One-shot script: import 18 projects extracted from the Church of Creationship
// WhatsApp group (Feb 13 – Apr 21, 2026) into Supabase `ideas` table.
//
// Pre-req: copy .env.example to .env.local and fill in:
//   SUPABASE_SERVICE_ROLE_KEY  (bypasses RLS — server-only)
//   IMPORT_USER_ID             (your auth.users.id UUID; required because ideas.user_id is NOT NULL)
//
// Run: npm install && node scripts/bulk-import-projects.js

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

// Minimal .env.local loader so we don't require `dotenv`.
function loadEnv() {
  const p = path.join(__dirname, '..', '.env.local');
  if (!fs.existsSync(p)) return;
  const lines = fs.readFileSync(p, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const m = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\s*$/);
    if (!m) continue;
    let val = m[2].trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    if (!process.env[m[1]]) process.env[m[1]] = val;
  }
}

loadEnv();

const SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';
const SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE_KEY;
const USER_ID = process.env.IMPORT_USER_ID;

if (!SERVICE_ROLE) {
  console.error('missing SUPABASE_SERVICE_ROLE_KEY in .env.local');
  process.exit(1);
}
if (!USER_ID) {
  console.error('missing IMPORT_USER_ID in .env.local');
  process.exit(1);
}

const PROJECTS = [
  {
    title: 'MBT Therapist Bot',
    author_name: 'Michelle',
    description: "AI therapist trained on Mentalization-Based Therapy manuals. Relentlessly curious, deliberately not-knowing stance. Grounded in Bateman & Fonagy.",
    stage: 'seed',
    github_url: '',
    website_url: '',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'Vibe Parties',
    author_name: 'Benjamin Von Wong',
    description: 'A site for hosting vibe parties, shipped rapidly post-hackathon with a tutorial flow.',
    stage: 'project',
    github_url: '',
    website_url: 'https://vibe-parties.web.app',
    demo_url: 'https://vibe-parties.web.app/101',
    team_members: [{ name: 'Brandon Levy' }],
  },
  {
    title: 'Caravan of Dreams Website',
    author_name: 'Benjamin Von Wong',
    description: 'Demo site for Caravan of Dreams focused on nourishing mind and body — prototype for a living community restaurant/space.',
    stage: 'project',
    github_url: '',
    website_url: 'https://caravan-of-dreams.vercel.app',
    demo_url: '',
    team_members: [{ name: 'Brandon Levy' }, { name: 'Angel' }],
  },
  {
    title: 'Kula (Evolver Exchange)',
    author_name: 'Michelle',
    description: 'A peer-to-peer reputation-based sharing network inspired by the Kula ring gift exchange. Disruptively independent p2p economy.',
    stage: 'project',
    github_url: '',
    website_url: 'https://kula-ten.vercel.app/',
    demo_url: 'https://kula-ten.vercel.app/feed',
    team_members: [
      { name: 'Sal' },
      { name: 'Daniel Pinchbeck' },
      { name: 'Nikita' },
      { name: 'Charlotte Binns' },
      { name: 'Hope Endrenyi' },
    ],
  },
  {
    title: 'Hackathon Dynamics / Complexity Models',
    author_name: 'Sal',
    description: 'Interactive models exploring what makes a "deepening" hackathon different from a traditional tech hackathon.',
    stage: 'project',
    github_url: '',
    website_url: 'https://slvtrs.com/complexity/hackathon.html',
    demo_url: 'https://slvtrs.com/complexity',
    team_members: [],
  },
  {
    title: 'Vibe Cadaver',
    author_name: 'Sal',
    description: 'A vibesite that rewrites itself with communal input, in the spirit of exquisite corpse.',
    stage: 'seed',
    github_url: '',
    website_url: 'https://vibecadaver.slvtrs.com/',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'Ocean Agentics',
    author_name: 'Aaron Roan',
    description: 'AI-generated hub on the High Seas Treaty / BBNJ. Ocean conservation × tech.',
    stage: 'project',
    github_url: '',
    website_url: 'https://oceanagentics.com',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'The Medical Collective',
    author_name: 'Hope Endrenyi',
    description: 'Platform for medical innovation / healthcare design — experience design coursework with product potential.',
    stage: 'project',
    github_url: '',
    website_url: 'https://the-medical-collective.web.app/',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'AI Doc Afterparty',
    author_name: 'group watch',
    description: 'Film/event about AI doctors — group planned watch party.',
    stage: 'project',
    github_url: '',
    website_url: 'https://the-ai-doc-nyc.web.app/',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'Speech Pathology AI',
    author_name: 'Vincent',
    description: "Locally-hosted LLM that coaches Parkinson's patients on speech exercises. Applicable beyond Parkinson's.",
    stage: 'project',
    github_url: '',
    website_url: 'https://speechpath.lovable.app/',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'Recipe Engineer',
    author_name: 'Vincent',
    description: 'Reverse-engineers cooking videos into recipes. Immediate use: a Caravan cookbook. Long-term: capturing familial recipes.',
    stage: 'project',
    github_url: '',
    website_url: 'https://recipeengineer.lovable.app/',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'KittyShare / Kitty Fund',
    author_name: 'Michelle',
    description: 'Community savings / mutual aid fund. Phase 1 web-accessible; Phase 2 adds social + mission-driven events.',
    stage: 'project',
    github_url: '',
    website_url: 'https://kittyshare.pages.dev',
    demo_url: 'https://funfund-38f.pages.dev',
    team_members: [{ name: 'Sahil' }],
  },
  {
    title: 'First Thought Best Thought',
    author_name: 'Hannah Levinson',
    description: 'Mobile game inspired by Burroughs\' "first thought best thought" principle. TestFlight coming.',
    stage: 'project',
    github_url: '',
    website_url: 'https://firstthoughtbestthought.netlify.app/',
    demo_url: '',
    team_members: [{ name: 'Maya' }],
  },
  {
    title: 'NotAmazon',
    author_name: 'Josh Y',
    description: 'Find the same goods Amazon sells at local stores/farmers markets. AI scans store shelves; paste your Amazon list to find local alternatives.',
    stage: 'project',
    github_url: 'https://github.com/qix/not-amazon',
    website_url: '',
    demo_url: 'https://not-amazon-production.up.railway.app/',
    team_members: [{ name: 'Hannah Levinson' }, { name: 'Maya' }],
  },
  {
    title: 'Cause Compass',
    author_name: 'Benjamin Von Wong',
    description: 'Volunteer matchmaker — chatbot intake builds a qualitative profile and matches people to causes. V1 prototype, buggy.',
    stage: 'seed',
    github_url: '',
    website_url: 'https://cause-compass-silk.vercel.app/',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'Earth Day Salon',
    author_name: 'Charlotte Binns',
    description: 'Earth Day fireside salon on True Human, Gaia, protopic political imagination, embodied kinship consciousness.',
    stage: 'company',
    github_url: '',
    website_url: 'https://www.viewcy.com/event/earth_day_salon',
    demo_url: '',
    team_members: [{ name: 'Samantha Sweetwater' }, { name: 'Daniel Pinchbeck' }],
  },
  {
    title: 'Demilitarise Education UX',
    author_name: 'Danielle Gauthier',
    description: 'UX design making the Demilitarise Education site easier to navigate; improving treaty/policy readability.',
    stage: 'project',
    github_url: '',
    website_url: '',
    demo_url: '',
    team_members: [],
  },
  {
    title: 'Metagov Governance Visualization',
    author_name: 'Danielle Gauthier',
    description: 'Governance-gap visualization UI using sentiment research + ethnographic database for Metagov\'s knowledge organization software.',
    stage: 'project',
    github_url: '',
    website_url: '',
    demo_url: '',
    team_members: [],
  },
];

async function main() {
  if (PROJECTS.length !== 18) {
    console.error(`expected 18 projects, got ${PROJECTS.length}`);
    process.exit(1);
  }

  const client = createClient(SUPABASE_URL, SERVICE_ROLE, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const rows = PROJECTS.map(p => ({
    user_id: USER_ID,
    author_name: p.author_name,
    author_email: '',
    title: p.title,
    description: p.description,
    github_url: p.github_url || '',
    website_url: p.website_url || '',
    demo_url: p.demo_url || '',
    team_members: p.team_members || [],
    stage: p.stage,
    company_name: '',
    status: 'active',
  }));

  console.log(`inserting ${rows.length} projects…`);
  const { data, error } = await client.from('ideas').insert(rows).select();

  if (error) {
    console.error('insert failed:', error.message);
    process.exit(1);
  }

  console.log(`inserted ${data.length} rows.`);
  const byStage = data.reduce((acc, r) => {
    acc[r.stage] = (acc[r.stage] || 0) + 1;
    return acc;
  }, {});
  console.log('by stage:', byStage);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});

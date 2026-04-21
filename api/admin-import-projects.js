// POST /api/admin-import-projects
// Body: { adminSecret: string, projects: [...] }
// Returns: { inserted: number }
// Uses SUPABASE_SERVICE_ROLE_KEY to bypass RLS for admin bulk insertion.
// Ownership of imported rows: process.env.IMPORT_USER_ID (set once on Vercel).

const { createClient } = require('@supabase/supabase-js');
const { readJsonBody } = require('./_shared.js');

const SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';
const MAX_BATCH = 100;
const VALID_STAGES = new Set(['seed', 'project', 'company']);

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method not allowed' });
    return;
  }

  if (!process.env.SUPABASE_SERVICE_ROLE_KEY || !process.env.ADMIN_SECRET || !process.env.IMPORT_USER_ID) {
    res.status(500).json({ error: 'server not configured' });
    return;
  }

  let body;
  try { body = await readJsonBody(req); }
  catch { res.status(400).json({ error: 'invalid json' }); return; }

  if (body?.adminSecret !== process.env.ADMIN_SECRET) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  const importUserId = process.env.IMPORT_USER_ID;

  const projects = Array.isArray(body?.projects) ? body.projects : null;
  if (!projects || !projects.length) { res.status(400).json({ error: 'projects must be a non-empty array' }); return; }
  if (projects.length > MAX_BATCH) { res.status(400).json({ error: `too many rows (max ${MAX_BATCH})` }); return; }

  const rows = [];
  for (const p of projects) {
    const title = typeof p?.title === 'string' ? p.title.trim() : '';
    if (!title) { res.status(400).json({ error: 'every project needs a title' }); return; }
    const stage = typeof p?.stage === 'string' ? p.stage.trim() : 'seed';
    if (!VALID_STAGES.has(stage)) { res.status(400).json({ error: `invalid stage: ${stage}` }); return; }

    const team = Array.isArray(p?.team_members)
      ? p.team_members.filter(m => m && typeof m.name === 'string' && m.name.trim())
                       .map(m => ({ name: m.name.trim() }))
      : [];

    rows.push({
      user_id: importUserId,
      author_name: typeof p?.author_name === 'string' ? p.author_name.trim() : '',
      author_email: '',
      title,
      description: typeof p?.description === 'string' ? p.description : '',
      github_url: typeof p?.github_url === 'string' ? p.github_url.trim() : '',
      website_url: typeof p?.website_url === 'string' ? p.website_url.trim() : '',
      demo_url: typeof p?.demo_url === 'string' ? p.demo_url.trim() : '',
      team_members: team,
      stage,
      company_name: typeof p?.company_name === 'string' ? p.company_name.trim() : '',
      status: 'active',
    });
  }

  const client = createClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const { data, error } = await client.from('ideas').insert(rows).select('id');
    if (error) {
      console.error('supabase insert error:', error.message);
      res.status(500).json({ error: 'insert failed' });
      return;
    }
    res.status(200).json({ inserted: data.length });
  } catch (err) {
    console.error('unexpected error:', err?.message || err);
    res.status(500).json({ error: 'insert failed' });
  }
};

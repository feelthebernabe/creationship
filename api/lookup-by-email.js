// POST /api/lookup-by-email
//
// Body: { email }
//
// Returns the upcoming slots claimed under that email, with cancel
// tokens, so the page can render "drop out" buttons inline.
//
// Trust model: anyone who types an email can see + cancel that
// person's upcoming slots. Symmetric with sign-up — anyone can
// claim under any email. Safety net is the cancellation email
// (sent via /api/cancel-claim) which informs the affected address.
//
// Endpoint always returns 200 with `slots: [...]` so it can't be
// used to enumerate which addresses ARE signed up vs not (no signups
// returns []; bad email returns 400).

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  let body;
  try { body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body; }
  catch { return res.status(400).json({ error: 'invalid_json' }); }

  const inputEmail = String(body?.email || '').trim().slice(0, 200);
  if (!inputEmail || !/^\S+@\S+\.\S+$/.test(inputEmail)) {
    return res.status(400).json({ error: 'email_invalid' });
  }

  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey) return res.status(500).json({ error: 'service_role_missing' });
  const supa = createClient(SUPABASE_URL, serviceKey);

  const { data, error } = await supa.rpc('get_my_active_signups', { p_email: inputEmail });
  if (error) {
    console.error('[lookup-by-email] rpc error:', error.message);
    return res.status(500).json({ error: 'server_error' });
  }

  return res.status(200).json({ ok: true, slots: data || [] });
};

// POST /api/notify-cancellation
//
// Body: { sunday_id }
//
// Admin-triggered: emails everyone signed up for a Sunday that just got
// cancelled. Auth: ADMIN_SECRET bearer (matches admin.html password).
// Does NOT mutate sundays.status — admin tab does that separately.

const { createClient } = require('@supabase/supabase-js');
const email = require('./_email');

const SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  // Bearer auth using ADMIN_SECRET (same shape as other admin endpoints).
  const adminSecret = process.env.ADMIN_SECRET;
  const auth = req.headers.authorization || '';
  const provided = auth.replace(/^Bearer\s+/i, '');
  if (!adminSecret || provided !== adminSecret) {
    return res.status(401).json({ error: 'unauthorized' });
  }

  let body;
  try { body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body; }
  catch { return res.status(400).json({ error: 'invalid_json' }); }
  const sunday_id = String(body?.sunday_id || '').trim();
  if (!sunday_id) return res.status(400).json({ error: 'sunday_id_required' });

  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey) return res.status(500).json({ error: 'service_role_missing' });
  const supa = createClient(SUPABASE_URL, serviceKey);

  // Look up the date for the message body.
  const { data: sundayRows, error: sErr } = await supa
    .from('sundays').select('id,date').eq('id', sunday_id).limit(1);
  if (sErr || !sundayRows || !sundayRows.length) {
    return res.status(404).json({ error: 'sunday_not_found' });
  }
  const sunday_date = sundayRows[0].date;

  const { data: signups, error: rErr } = await supa.rpc('get_signups_for_sunday', { p_sunday_id: sunday_id });
  if (rErr) return res.status(500).json({ error: rErr.message });

  let sent = 0, failed = 0;
  for (const row of signups || []) {
    if (!row.email) continue;
    const tpl = email.templates.cancellation({
      name: row.name, role_type: row.role_type, sunday_date
    });
    const r = await email.send(row.email, tpl);
    if (r && r.error) { failed++; continue; }
    sent++;
  }

  return res.status(200).json({ ok: true, sent, failed, total: (signups || []).length });
};

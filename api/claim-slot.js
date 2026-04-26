// POST /api/claim-slot
//
// Body: { role: 'teach'|'mc', sunday_id, name, email, title?, description? }
//
// Calls the SECURITY DEFINER Postgres RPC (claim_teach_open or claim_mc_open),
// which atomically reserves the slot and returns a cancel_token. Then sends a
// confirmation email best-effort. The slot is yours regardless of whether
// email succeeds — we never roll back the claim if Resend hiccups.

const { createClient } = require('@supabase/supabase-js');
const email = require('./_email');

const SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4c2JxcHRxZ3JleXd1dGJmYnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MDgyNjUsImV4cCI6MjA5MjE4NDI2NX0.bCle-Yg_fYj8V5HeZtHiXYxEqzufeS5KFWBssSeGKOM';

const ERR_HTTP = {
  email_required: 400, title_required: 400, sunday_not_found: 404,
  past_sunday: 410, sunday_cancelled: 410, teach_slot_taken: 409
};

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'method_not_allowed' });

  let body;
  try { body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body; }
  catch { return res.status(400).json({ error: 'invalid_json' }); }
  if (!body || typeof body !== 'object') return res.status(400).json({ error: 'invalid_body' });

  const role = String(body.role || '').toLowerCase();
  const sunday_id = String(body.sunday_id || '').trim();
  const name = String(body.name || '').trim().slice(0, 100);
  const inputEmail = String(body.email || '').trim().slice(0, 200);
  const title = String(body.title || '').trim().slice(0, 200);
  const description = String(body.description || '').trim().slice(0, 2000);

  if (!sunday_id) return res.status(400).json({ error: 'sunday_id_required' });
  if (!inputEmail) return res.status(400).json({ error: 'email_required' });
  if (!/^\S+@\S+\.\S+$/.test(inputEmail)) return res.status(400).json({ error: 'email_invalid' });
  if (role !== 'teach' && role !== 'mc') return res.status(400).json({ error: 'role_invalid' });
  if (role === 'teach' && !title) return res.status(400).json({ error: 'title_required' });

  const supa = createClient(SUPABASE_URL, ANON_KEY);

  let result;
  try {
    if (role === 'teach') {
      const { data, error } = await supa.rpc('claim_teach_open', {
        p_sunday_id: sunday_id, p_name: name, p_email: inputEmail,
        p_title: title, p_description: description
      });
      if (error) throw new Error(error.message || 'rpc_failed');
      result = Array.isArray(data) ? data[0] : data;
    } else {
      const { data, error } = await supa.rpc('claim_mc_open', {
        p_sunday_id: sunday_id, p_name: name, p_email: inputEmail
      });
      if (error) throw new Error(error.message || 'rpc_failed');
      result = Array.isArray(data) ? data[0] : data;
    }
  } catch (err) {
    const code = ERR_HTTP[err.message] || 500;
    return res.status(code).json({ error: err.message || 'unknown' });
  }

  if (!result || !result.cancel_token) {
    return res.status(500).json({ error: 'no_cancel_token' });
  }

  // Send confirmation email synchronously. Vercel kills the function as
  // soon as it responds, so a fire-and-forget .catch() never actually
  // completes the network call to Resend. Await so the email goes out.
  // We swallow errors — claim already succeeded; email is best-effort.
  try {
    await email.send(inputEmail, email.templates.confirmation({
      name, role_type: role === 'teach' ? 'teach' : 'hold_space',
      sunday_date: result.sunday_date, title, cancel_token: result.cancel_token
    }));
  } catch (e) {
    console.error('[claim-slot] confirmation email failed:', e);
  }

  return res.status(200).json({
    ok: true,
    sunday_id: result.sunday_id,
    sunday_date: result.sunday_date
    // cancel_token deliberately NOT returned to the client — it lives only
    // in the email so spoofers can't read someone else's cancel link from
    // a network response.
  });
};

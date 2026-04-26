// POST /api/resend-cancel-links
//
// Body: { email }
//
// "Lost your cancel link?" — looks up all upcoming claims for the given
// email and re-emails the cancel URLs in one summary message. Always
// returns 200 even when nothing matches, so the response can't be used
// to enumerate which addresses are signed up.
//
// Security model: cancel_tokens never leave the server unless the
// request matches the email that owns them. The token itself is the
// capability; it reaches the inbox owner via a side channel they
// already control. Same trust model as a magic link, scoped to one
// action (cancel) instead of a session.

const { createClient } = require('@supabase/supabase-js');
const email = require('./_email');

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
    console.error('[resend-cancel-links] rpc error:', error.message);
    return res.status(500).json({ error: 'server_error' });
  }

  // Don't reveal whether the email has signups; always 200.
  // Await synchronously — see api/claim-slot.js for the fire-and-forget trap.
  if (data && data.length) {
    try {
      await email.send(inputEmail, email.templates.resendLinks(data));
    } catch (e) {
      console.error('[resend-cancel-links] send failed:', e);
    }
  }

  return res.status(200).json({ ok: true });
};

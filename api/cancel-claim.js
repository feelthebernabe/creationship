// GET  /api/cancel-claim?token=...
// Cancels a slot via the per-signup cancel_token in the user's email.
// Returns JSON; the calendar.html page detects ?cancel= in URL,
// calls this, and shows a "you're dropped from <date>" toast.

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';
const ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4c2JxcHRxZ3JleXd1dGJmYnR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MDgyNjUsImV4cCI6MjA5MjE4NDI2NX0.bCle-Yg_fYj8V5HeZtHiXYxEqzufeS5KFWBssSeGKOM';

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });

  const token = String(req.query?.token || '').trim();
  if (!token) return res.status(400).json({ error: 'token_required' });

  const supa = createClient(SUPABASE_URL, ANON_KEY);
  const { data, error } = await supa.rpc('cancel_with_token', { p_token: token });

  if (error) {
    if (error.message === 'invalid_token' || error.code === 'P0001') {
      return res.status(404).json({ error: 'invalid_token' });
    }
    return res.status(500).json({ error: error.message || 'unknown' });
  }

  const row = Array.isArray(data) ? data[0] : data;
  if (!row) return res.status(404).json({ error: 'invalid_token' });

  return res.status(200).json({
    ok: true,
    sunday_date: row.sunday_date,
    role_type: row.role_type,
    name: row.name,
    title: row.title
  });
};

// GET /api/cron-reminders
//
// Vercel cron triggers this daily (see vercel.json). It calls
// get_due_reminders('day7') and get_due_reminders('day1'), sends an
// email per row via Resend, and marks each signup as notified so the
// next day's run skips it.
//
// Authentication: Vercel sets `Authorization: Bearer <CRON_SECRET>`
// when invoking cron endpoints if CRON_SECRET is set in env.
// See https://vercel.com/docs/cron-jobs/manage-cron-jobs#securing-cron-jobs

const { createClient } = require('@supabase/supabase-js');
const email = require('./_email');

const SUPABASE_URL = 'https://cxsbqptqgreywutbfbtx.supabase.co';

module.exports = async function handler(req, res) {
  if (req.method !== 'GET') return res.status(405).json({ error: 'method_not_allowed' });

  // Enforce cron auth in production (CRON_SECRET set on Vercel).
  // Locally without the env var, allow open access for dev/testing.
  const secret = process.env.CRON_SECRET;
  if (secret) {
    const auth = req.headers.authorization || '';
    if (auth !== `Bearer ${secret}`) {
      return res.status(401).json({ error: 'unauthorized' });
    }
  }

  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey) {
    return res.status(500).json({ error: 'service_role_missing' });
  }
  const supa = createClient(SUPABASE_URL, serviceKey);

  const summary = { day7: { found: 0, sent: 0, failed: 0 }, day1: { found: 0, sent: 0, failed: 0 } };

  for (const kind of ['day7', 'day1']) {
    const { data, error } = await supa.rpc('get_due_reminders', { p_kind: kind });
    if (error) {
      console.error('[cron] get_due_reminders error', kind, error.message);
      continue;
    }
    summary[kind].found = (data || []).length;

    for (const row of data || []) {
      try {
        const tpl = email.templates[kind]({
          name: row.name,
          role_type: row.role_type,
          sunday_date: row.sunday_date,
          title: row.sunday_title || (row.role_type === 'teach' ? '' : ''),
          cancel_token: row.cancel_token
        });
        const result = await email.send(row.email, tpl);
        if (result && result.error) {
          summary[kind].failed++;
          console.error('[cron] send error', kind, row.email, result.error);
          continue;
        }
        // Only mark as notified once Resend accepted (or skipped due to no key).
        await supa.rpc('mark_notified', { p_signup_id: row.signup_id, p_kind: kind });
        summary[kind].sent++;
      } catch (err) {
        summary[kind].failed++;
        console.error('[cron] exception', kind, row.email, err.message || err);
      }
    }
  }

  return res.status(200).json({ ok: true, ran_at: new Date().toISOString(), summary });
};

// Resend wrapper — graceful no-op when RESEND_API_KEY is missing.
// Claim/cancel endpoints call this best-effort; email failure never
// blocks the underlying state change.

const { Resend } = require('resend');

const FROM = 'the creationship <onboarding@resend.dev>';
const REPLY_TO = 'mailforbernabe@gmail.com';
const SITE = 'https://creationship.vercel.app';

let _client = null;
function client() {
  if (_client) return _client;
  const key = process.env.RESEND_API_KEY;
  if (!key) return null;
  _client = new Resend(key);
  return _client;
}

function fmtDate(iso) {
  // '2026-04-26' → 'sunday, april 26'
  const d = new Date(iso + 'T12:00:00Z');
  const wd = d.toLocaleDateString('en-US', { weekday: 'long', timeZone: 'UTC' }).toLowerCase();
  const md = d.toLocaleDateString('en-US', { month: 'long', day: 'numeric', timeZone: 'UTC' }).toLowerCase();
  return wd + ', ' + md;
}

function roleLabel(role_type) {
  return role_type === 'teach' ? 'teaching' : 'MCing';
}

function cancelUrl(token) {
  return SITE + '/calendar.html?cancel=' + encodeURIComponent(token);
}

function shell(bodyHtml) {
  return `<div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;max-width:560px;margin:0 auto;padding:24px;color:#2a2a28;line-height:1.6;">
${bodyHtml}
<hr style="border:none;border-top:1px solid #e8e3dc;margin:32px 0 16px;">
<p style="color:#a09890;font-size:0.8rem;">the creationship · sundays at caravan of dreams · east village</p>
</div>`;
}

// Templates ----------------------------------------------------------------

// IMPORTANT: Resend's tracking proxy wraps every URL in both HTML and
// plain-text emails (us-east-1.resend-clicks.com), and that proxy has
// had SSL issues that break clickable links entirely. Until a custom
// domain is verified in Resend (with click-tracking disabled), we make
// the cancel flow not depend on a clickable URL at all:
//   • show the cancel token as a copy-paste string (just text — never wrapped)
//   • point users to /calendar.html → the "have your cancel code?" form
//   • a wrapped URL appears as a fallback for users whose link works

function cancelInstructions(cancel_token) {
  return `to cancel:
  1. open https://creationship.vercel.app/calendar.html
  2. scroll to "have your cancel code?"
  3. paste this code: ${cancel_token}

(or if your email link works, click: ${cancelUrl(cancel_token)})`;
}

function tplConfirmation({ name, role_type, sunday_date, title, cancel_token }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  const topicLine = title ? `topic: ${title}\n` : '';
  return {
    subject: `you're ${role} on ${date}`,
    text: `hi ${name || 'there'},

you're confirmed as ${role} for ${date}.
${topicLine}noon at caravan of dreams (405 e 6th st, east village).

${cancelInstructions(cancel_token)}
`
  };
}

function tplDay7({ name, role_type, sunday_date, title, cancel_token }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  const topicLine = title ? `topic: ${title}\n` : '';
  return {
    subject: `you're ${role} this sunday in a week`,
    text: `hi ${name || 'there'},

heads up — you're ${role} on ${date}, one week from today.
${topicLine}
if anything has changed and you can't make it, drop out so someone else can claim the slot.

${cancelInstructions(cancel_token)}
`
  };
}

function tplDay1({ name, role_type, sunday_date, title, cancel_token }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  const topicLine = title ? `topic: ${title}\n` : '';
  return {
    subject: `tomorrow: you're ${role} at the creationship`,
    text: `hi ${name || 'there'},

tomorrow (${date}) at noon — you're ${role}.
${topicLine}caravan of dreams · 405 e 6th st, east village · doors at 11:50.

if something came up and you can't make it, please drop out so we can fill the slot.

${cancelInstructions(cancel_token)}
`
  };
}

function tplCancellation({ name, role_type, sunday_date }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  return {
    subject: `${date} sunday is cancelled`,
    text: `hi ${name || 'there'},

the ${date} sunday — where you were signed up for ${role} — has been cancelled.

nothing to do; we just wanted to let you know so you don't show up to a closed door. we'll be back the following week.
`
  };
}

// "lost your cancel link" — list every upcoming claim with cancel codes
// the user can copy-paste into the form on calendar.html. URLs included
// as fallback but the cancel codes are the primary path (work even when
// Resend's tracker domain is broken).
function tplResendLinks(signups) {
  const blocks = signups.map((s, i) => {
    const role = roleLabel(s.role_type);
    const date = fmtDate(s.sunday_date);
    const titleLine = s.title ? `  topic: ${s.title}\n` : '';
    return `${i + 1}. ${role} on ${date}\n${titleLine}   cancel code: ${s.cancel_token}\n   (or link: ${cancelUrl(s.cancel_token)})`;
  }).join('\n\n');
  return {
    subject: `your active sundays at the creationship`,
    text: `here's everything you're currently signed up for.

to cancel any of these:
  1. open https://creationship.vercel.app/calendar.html
  2. scroll to "have your cancel code?"
  3. paste the code for the slot you want to drop

${blocks}

if nothing here looks right, you may have signed up under a different email.
`
  };
}

function escapeHtml(s) {
  return String(s == null ? '' : s)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

// Send -----------------------------------------------------------------------

async function send(to, tpl) {
  const c = client();
  if (!c) {
    console.warn('[_email] RESEND_API_KEY missing — would have sent to', to, 'subject:', tpl.subject);
    return { skipped: true };
  }
  try {
    // text-only by design (for now). Resend's click tracking rewrites
    // every `<a href>` in HTML emails to route through a tracker domain
    // (us-east-1.resend-clicks.com), and that domain has had SSL issues
    // for the onboarding@resend.dev sandbox sender. Plain-text URLs
    // aren't wrapped, so cancel links work reliably.
    // Re-enable html once a custom domain is verified in Resend AND
    // click-tracking is disabled at the domain level.
    const r = await c.emails.send({
      from: FROM,
      to: Array.isArray(to) ? to : [to],
      reply_to: REPLY_TO,
      subject: tpl.subject,
      text: tpl.text
    });
    return { id: r.data && r.data.id, error: r.error };
  } catch (err) {
    console.error('[_email] send failed:', err.message || err);
    return { error: err.message || String(err) };
  }
}

module.exports = {
  send,
  templates: {
    confirmation: tplConfirmation,
    day7: tplDay7,
    day1: tplDay1,
    cancellation: tplCancellation,
    resendLinks: tplResendLinks
  }
};

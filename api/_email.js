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

function tplConfirmation({ name, role_type, sunday_date, title, cancel_token }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  const url = cancelUrl(cancel_token);
  const topicLine = title ? `<p>your topic: <em>${escapeHtml(title)}</em></p>` : '';
  return {
    subject: `you're ${role} on ${date}`,
    html: shell(`
      <p>hi ${escapeHtml(name || 'there')},</p>
      <p>you're confirmed as <strong>${role}</strong> for <strong>${date}</strong>.</p>
      ${topicLine}
      <p>noon at caravan of dreams (405 e 6th st, east village).</p>
      <p style="margin-top:24px;">
        if this wasn't you, or you can't make it, drop out here:<br>
        <a href="${url}" style="color:#c4654a;">${url}</a>
      </p>
    `),
    text: `you're confirmed as ${role} for ${date}.\n${title ? 'topic: ' + title + '\n' : ''}noon at caravan of dreams (405 e 6th st).\n\nif this wasn't you, cancel: ${url}\n`
  };
}

function tplDay7({ name, role_type, sunday_date, title, cancel_token }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  const url = cancelUrl(cancel_token);
  return {
    subject: `you're ${role} this sunday in a week`,
    html: shell(`
      <p>hi ${escapeHtml(name || 'there')},</p>
      <p>heads up — you're <strong>${role}</strong> on <strong>${date}</strong>, one week from today.</p>
      ${title ? `<p>your topic: <em>${escapeHtml(title)}</em></p>` : ''}
      <p>if anything has changed and you can't make it, drop out and someone else can claim the slot:<br>
        <a href="${url}" style="color:#c4654a;">${url}</a>
      </p>
    `),
    text: `you're ${role} on ${date}, one week from today.\n${title ? 'topic: ' + title + '\n' : ''}\ncan't make it? cancel: ${url}\n`
  };
}

function tplDay1({ name, role_type, sunday_date, title, cancel_token }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  const url = cancelUrl(cancel_token);
  return {
    subject: `tomorrow: you're ${role} at the creationship`,
    html: shell(`
      <p>hi ${escapeHtml(name || 'there')},</p>
      <p><strong>tomorrow</strong> (${date}) at noon — you're <strong>${role}</strong>.</p>
      ${title ? `<p>your topic: <em>${escapeHtml(title)}</em></p>` : ''}
      <p>caravan of dreams · 405 e 6th st, east village · doors at 11:50.</p>
      <p style="margin-top:24px;">if something came up and you can't make it, please drop out so we can fill the slot:<br>
        <a href="${url}" style="color:#c4654a;">${url}</a>
      </p>
    `),
    text: `tomorrow ${date} at noon, you're ${role}.\n${title ? 'topic: ' + title + '\n' : ''}caravan of dreams, 405 e 6th st.\n\ncan't make it? ${url}\n`
  };
}

function tplCancellation({ name, role_type, sunday_date }) {
  const role = roleLabel(role_type);
  const date = fmtDate(sunday_date);
  return {
    subject: `${date} sunday is cancelled`,
    html: shell(`
      <p>hi ${escapeHtml(name || 'there')},</p>
      <p>the <strong>${date}</strong> sunday — where you were signed up for <strong>${role}</strong> — has been cancelled.</p>
      <p>nothing to do; we just wanted to let you know so you don't show up to a closed door. we'll be back the following week.</p>
    `),
    text: `the ${date} sunday — where you were ${role} — has been cancelled.\nwe'll be back the following week.\n`
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
    const r = await c.emails.send({
      from: FROM,
      to: Array.isArray(to) ? to : [to],
      reply_to: REPLY_TO,
      subject: tpl.subject,
      html: tpl.html,
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
    cancellation: tplCancellation
  }
};

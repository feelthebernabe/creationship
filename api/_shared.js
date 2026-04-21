// Shared helpers for /api/extract-* and /api/admin-import-projects.
// Not a route (filename starts with _), just a common module.

const PROJECT_SCHEMA = {
  type: 'object',
  properties: {
    title: {
      type: 'string',
      description: "The project's name. If not explicitly named, invent a short best-guess title.",
    },
    description: {
      type: 'string',
      description: '1–2 sentence plain-language summary in the person\'s own voice where possible.',
    },
    stage: {
      type: 'string',
      enum: ['seed', 'project', 'company'],
      description: 'seed = idea or concept; project = actively building or shipped prototype; company = real launched entity, event, or product.',
    },
    github_url: {
      type: 'string',
      description: 'github.com/... URL if present, else empty string.',
    },
    website_url: {
      type: 'string',
      description: 'Canonical marketing / landing URL if present. Do NOT put hosted-app demos here — those go in demo_url. Empty string if none.',
    },
    demo_url: {
      type: 'string',
      description: 'Hosted app/demo URL — typical hosts: *.vercel.app, *.lovable.app, *.netlify.app, *.web.app, *.pages.dev, *.railway.app, *.up.railway.app, firebaseapp.com. Empty string if none.',
    },
    team_members: {
      type: 'array',
      description: 'Other people named as collaborators (not the primary author). Empty array if none.',
      items: {
        type: 'object',
        properties: { name: { type: 'string' } },
        required: ['name'],
      },
    },
    author_name: {
      type: 'string',
      description: 'Primary author / creator. Their display name as it appears in the source. Empty string if unclear.',
    },
  },
  required: ['title', 'description', 'stage', 'github_url', 'website_url', 'demo_url', 'team_members', 'author_name'],
};

const SINGLE_SYSTEM = `You extract a single project record from free-form text (a WhatsApp message, tweet, or rough notes).

Classify the stage carefully:
- seed: idea, concept, or half-formed sketch with no working artifact yet
- project: actively building OR has a shipped prototype / working demo
- company: launched entity, event, or product with an audience

Link classification rule:
- github.com/... → github_url
- Hosted app domains (*.vercel.app, *.lovable.app, *.netlify.app, *.web.app, *.pages.dev, *.railway.app, *.up.railway.app, firebaseapp.com) → demo_url
- Everything else → website_url

Always call the record_project tool with your extraction. If a field isn't present, return an empty string or empty array.`;

const BULK_SYSTEM = `You extract every distinct project from a WhatsApp chat export.

For each project, emit one record matching the schema. Rules:

1. ONLY extract messages where someone shares their creative work, an idea they're building, or a project they want others to know about. Skip pure logistics ("I'll be there Sunday", "who's bringing snacks", "what time does it start", "running late"), skip reactions, skip media forwards without project context.

2. Deduplicate: if the same project appears across multiple messages, merge into one record using the most complete version. Prefer later messages for descriptions (more refined) and earlier messages for the moment of first reveal.

3. Stage classification:
   - seed: idea, concept, half-formed sketch, no working artifact yet
   - project: actively building OR has a shipped prototype / working demo
   - company: launched entity, event, or product with an audience

4. Link classification rule:
   - github.com/... → github_url
   - Hosted app domains (*.vercel.app, *.lovable.app, *.netlify.app, *.web.app, *.pages.dev, *.railway.app, *.up.railway.app, firebaseapp.com) → demo_url
   - Everything else → website_url

5. Author vs team members: the author_name is whoever shared the project as their own. Anyone else they tag as co-builder goes in team_members. Skip social-media handles of uninvolved people.

6. If you can't tell whether something is a project at all, skip it.

Call the record_projects tool exactly once with an array of every extracted project.`;

function rateLimit() {
  const BUCKET = {};
  const LIMIT = 10;
  const WINDOW_MS = 60_000;
  return function check(ip) {
    const now = Date.now();
    const entry = BUCKET[ip] || { count: 0, resetAt: now + WINDOW_MS };
    if (now > entry.resetAt) {
      entry.count = 0;
      entry.resetAt = now + WINDOW_MS;
    }
    entry.count += 1;
    BUCKET[ip] = entry;
    return entry.count <= LIMIT;
  };
}

async function readJsonBody(req) {
  if (req.body) return typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  return new Promise((resolve, reject) => {
    let buf = '';
    req.on('data', chunk => { buf += chunk; });
    req.on('end', () => {
      try { resolve(buf ? JSON.parse(buf) : {}); } catch (e) { reject(e); }
    });
    req.on('error', reject);
  });
}

function clientIp(req) {
  const fwd = req.headers['x-forwarded-for'];
  if (fwd) return String(fwd).split(',')[0].trim();
  return req.socket?.remoteAddress || 'unknown';
}

module.exports = {
  PROJECT_SCHEMA,
  SINGLE_SYSTEM,
  BULK_SYSTEM,
  rateLimit,
  readJsonBody,
  clientIp,
};

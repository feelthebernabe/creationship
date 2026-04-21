// POST /api/extract-projects-bulk
// Body: { text: string, adminSecret: string }
// Returns: { projects: [...] }
// Admin-only — bulk parsing burns more tokens than the single endpoint.

const Anthropic = require('@anthropic-ai/sdk').default || require('@anthropic-ai/sdk');
const { PROJECT_SCHEMA, BULK_SYSTEM, rateLimit, readJsonBody, clientIp } = require('./_shared.js');

const MAX_INPUT_CHARS = 500_000;
const MODEL = 'claude-sonnet-4-6';
const check = rateLimit();

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method not allowed' });
    return;
  }

  if (!process.env.ANTHROPIC_API_KEY || !process.env.ADMIN_SECRET) {
    res.status(500).json({ error: 'server not configured' });
    return;
  }

  const ip = clientIp(req);
  if (!check(ip)) {
    res.status(429).json({ error: 'rate limit — try again in a minute' });
    return;
  }

  let body;
  try { body = await readJsonBody(req); }
  catch { res.status(400).json({ error: 'invalid json' }); return; }

  if (body?.adminSecret !== process.env.ADMIN_SECRET) {
    res.status(401).json({ error: 'unauthorized' });
    return;
  }

  const text = typeof body?.text === 'string' ? body.text.trim() : '';
  if (!text) { res.status(400).json({ error: 'missing text' }); return; }
  if (text.length > MAX_INPUT_CHARS) {
    res.status(400).json({ error: `text too long (max ${MAX_INPUT_CHARS} chars)` });
    return;
  }

  const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

  try {
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 16_000,
      // Caching the long system prompt means repeated bulk runs are cheap.
      system: [{ type: 'text', text: BULK_SYSTEM, cache_control: { type: 'ephemeral' } }],
      tools: [{
        name: 'record_projects',
        description: 'Record the full list of extracted projects.',
        input_schema: {
          type: 'object',
          properties: {
            projects: {
              type: 'array',
              items: PROJECT_SCHEMA,
            },
          },
          required: ['projects'],
        },
      }],
      tool_choice: { type: 'tool', name: 'record_projects' },
      messages: [{ role: 'user', content: text }],
    });

    const toolUse = response.content.find(c => c.type === 'tool_use' && c.name === 'record_projects');
    if (!toolUse) {
      console.error('no tool_use in response', response.stop_reason);
      res.status(502).json({ error: 'extraction failed' });
      return;
    }

    const projects = Array.isArray(toolUse.input?.projects) ? toolUse.input.projects : [];
    res.status(200).json({ projects });
  } catch (err) {
    console.error('anthropic error:', err?.message || err);
    res.status(500).json({ error: 'extraction failed' });
  }
};

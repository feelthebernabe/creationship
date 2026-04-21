// POST /api/extract-project
// Body: { text: string }
// Returns: { title, description, stage, github_url, website_url, demo_url, team_members, author_name }

const Anthropic = require('@anthropic-ai/sdk').default || require('@anthropic-ai/sdk');
const { PROJECT_SCHEMA, SINGLE_SYSTEM, rateLimit, readJsonBody, clientIp } = require('./_shared.js');

const MAX_INPUT_CHARS = 50_000;
const MODEL = 'claude-haiku-4-5-20251001';
const check = rateLimit();

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method not allowed' });
    return;
  }

  if (!process.env.ANTHROPIC_API_KEY) {
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
      max_tokens: 1024,
      system: SINGLE_SYSTEM,
      tools: [{
        name: 'record_project',
        description: 'Record the single extracted project.',
        input_schema: PROJECT_SCHEMA,
      }],
      tool_choice: { type: 'tool', name: 'record_project' },
      messages: [{ role: 'user', content: text }],
    });

    const toolUse = response.content.find(c => c.type === 'tool_use' && c.name === 'record_project');
    if (!toolUse) {
      console.error('no tool_use in response', response.stop_reason);
      res.status(502).json({ error: 'extraction failed' });
      return;
    }

    res.status(200).json(toolUse.input);
  } catch (err) {
    console.error('anthropic error:', err?.message || err);
    res.status(500).json({ error: 'extraction failed' });
  }
};

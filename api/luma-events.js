// Vercel serverless function — fetches Luma calendar via public iCal feed
// and returns upcoming "creationship" events. No API key required.
//
// GET /api/luma-events
// Returns upcoming creationship events parsed from the iCal feed.

const LUMA_ICS_URL = 'https://api2.luma.com/ics/get?entity=calendar&id=cal-Cv4SfxulyNrsjTM';

// Simple ICS parser — no dependencies needed
function parseICS(icsText) {
  const events = [];
  const blocks = icsText.split('BEGIN:VEVENT');

  for (let i = 1; i < blocks.length; i++) {
    const block = blocks[i].split('END:VEVENT')[0];
    const evt = {};

    // Parse unfolded lines (ICS uses line folding with leading space/tab)
    const unfoldedBlock = block.replace(/\r?\n[ \t]/g, '');

    const lines = unfoldedBlock.split(/\r?\n/);
    for (const line of lines) {
      const colonIdx = line.indexOf(':');
      if (colonIdx === -1) continue;

      // Handle property parameters (e.g., DTSTART;VALUE=DATE:20260426)
      let key = line.substring(0, colonIdx);
      const value = line.substring(colonIdx + 1);

      // Strip parameters from key
      const semiIdx = key.indexOf(';');
      if (semiIdx !== -1) key = key.substring(0, semiIdx);

      switch (key) {
        case 'SUMMARY':
          evt.summary = value;
          break;
        case 'DTSTART':
          evt.start = parseICSDate(value);
          break;
        case 'DTEND':
          evt.end = parseICSDate(value);
          break;
        case 'DESCRIPTION':
          evt.description = value;
          break;
        case 'LOCATION':
          evt.location = value;
          break;
        case 'UID':
          evt.uid = value;
          break;
      }
    }

    if (evt.summary && evt.start) {
      events.push(evt);
    }
  }

  return events;
}

function parseICSDate(str) {
  // Format: 20260426T160000Z or 20260426
  if (!str) return null;
  const clean = str.replace(/[^0-9TZ]/g, '');

  if (clean.length >= 15) {
    // Full datetime: YYYYMMDDTHHmmss(Z)
    const year = clean.substring(0, 4);
    const month = clean.substring(4, 6);
    const day = clean.substring(6, 8);
    const hour = clean.substring(9, 11);
    const min = clean.substring(11, 13);
    const sec = clean.substring(13, 15);
    const isUTC = clean.endsWith('Z');

    if (isUTC) {
      return new Date(`${year}-${month}-${day}T${hour}:${min}:${sec}Z`).toISOString();
    }
    // Assume UTC if no timezone marker
    return new Date(`${year}-${month}-${day}T${hour}:${min}:${sec}Z`).toISOString();
  }

  if (clean.length >= 8) {
    // Date only
    const year = clean.substring(0, 4);
    const month = clean.substring(4, 6);
    const day = clean.substring(6, 8);
    return new Date(`${year}-${month}-${day}T00:00:00Z`).toISOString();
  }

  return null;
}

function extractLumaUrl(description) {
  if (!description) return '';
  // Luma URLs in description look like: https://luma.com/slug or https://lu.ma/slug
  const match = description.match(/https?:\/\/(?:luma\.com|lu\.ma)\/([a-z0-9]+)/i);
  if (match) return `https://lu.ma/${match[1]}`;
  return '';
}

module.exports = async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).json({ error: 'Method not allowed' });

  try {
    const response = await fetch(LUMA_ICS_URL);
    if (!response.ok) {
      console.error('Luma ICS fetch error:', response.status);
      return res.status(502).json({ error: 'Failed to fetch Luma calendar' });
    }

    const icsText = await response.text();
    const allEvents = parseICS(icsText);
    const now = new Date();

    // Filter: only creationship events, in the future, sorted by date
    const creationshipEvents = allEvents
      .filter(evt => {
        const name = (evt.summary || '').toLowerCase();
        return name.includes('creationship');
      })
      .filter(evt => new Date(evt.start) > now)
      .sort((a, b) => new Date(a.start) - new Date(b.start))
      .slice(0, 5)
      .map(evt => ({
        name: evt.summary,
        start_at: evt.start,
        end_at: evt.end || '',
        url: extractLumaUrl(evt.description),
        location: evt.location || '',
      }));

    // Cache for 30 minutes
    res.setHeader('Cache-Control', 's-maxage=1800, stale-while-revalidate=600');
    return res.status(200).json({ events: creationshipEvents });

  } catch (err) {
    console.error('Luma proxy error:', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
};

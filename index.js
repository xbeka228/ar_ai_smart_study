const openaiApiKey = process.env.OPENAI_API_KEY || '';
const openaiModel = process.env.OPENAI_MODEL || 'gpt-5.4-mini';

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify(payload));
}

async function readJson(request) {
  if (request.body && typeof request.body === 'object') {
    return request.body;
  }

  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }

  const body = Buffer.concat(chunks).toString('utf8');
  if (!body.trim()) return {};
  return JSON.parse(body);
}

function extractText(data) {
  if (typeof data?.output_text === 'string' && data.output_text.trim()) {
    return data.output_text;
  }

  const text = data?.output
    ?.flatMap((item) => item.content ?? [])
    ?.filter((content) => content.type === 'output_text')
    ?.map((content) => content.text)
    ?.join('\n')
    ?.trim();

  if (!text) {
    throw new Error('AI provider returned an empty response');
  }

  return text;
}

async function callOpenAI(prompt) {
  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${openaiApiKey}`,
    },
    body: JSON.stringify({
      model: openaiModel,
      input: prompt,
      max_output_tokens: 3000,
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    const message = data?.error?.message || 'AI provider request failed';
    throw new Error(message);
  }

  return extractText(data);
}

module.exports = async function handler(request, response) {
  const path = request.url.split('?')[0];

  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }

  if (request.method === 'GET' && (path === '/' || path === '/health')) {
    sendJson(response, 200, {
      ok: true,
      aiConfigured: openaiApiKey.length > 0,
      model: openaiModel,
    });
    return;
  }

  if (request.method !== 'POST' || path !== '/ai') {
    sendJson(response, 404, {error: 'Not found'});
    return;
  }

  if (!openaiApiKey) {
    sendJson(response, 500, {error: 'OPENAI_API_KEY is not configured'});
    return;
  }

  try {
    const body = await readJson(request);
    const prompt = typeof body.prompt === 'string' ? body.prompt.trim() : '';

    if (!prompt) {
      sendJson(response, 400, {error: 'prompt is required'});
      return;
    }

    const text = await callOpenAI(prompt);
    sendJson(response, 200, {text});
  } catch (error) {
    sendJson(response, 500, {
      error: error instanceof Error ? error.message : 'Unknown server error',
    });
  }
};

const openaiApiKey = process.env.OPENAI_API_KEY || '';
const openaiModel = process.env.OPENAI_MODEL || 'gpt-5.4-mini';

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify(payload));
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

module.exports = {
  callOpenAI,
  openaiApiKey,
  openaiModel,
  sendJson,
};

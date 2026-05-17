const {callOpenAI, openaiApiKey, sendJson} = require('./_openai');

module.exports = async function handler(request, response) {
  response.setHeader('Access-Control-Allow-Origin', '*');
  response.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS');
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method === 'OPTIONS') {
    response.status(204).end();
    return;
  }

  if (request.method !== 'POST') {
    sendJson(response, 405, {error: 'Method not allowed'});
    return;
  }

  if (!openaiApiKey) {
    sendJson(response, 500, {error: 'OPENAI_API_KEY is not configured'});
    return;
  }

  try {
    const body = typeof request.body === 'object' ? request.body : {};
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

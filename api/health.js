const {openaiApiKey, openaiModel, sendJson} = require('./_openai');

module.exports = function handler(request, response) {
  if (request.method !== 'GET') {
    sendJson(response, 405, {error: 'Method not allowed'});
    return;
  }

  sendJson(response, 200, {
    ok: true,
    aiConfigured: openaiApiKey.length > 0,
    model: openaiModel,
  });
};

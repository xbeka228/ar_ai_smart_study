module.exports = function handler(request, response) {
  response.writeHead(200, {
    'Content-Type': 'application/json; charset=utf-8',
  });
  response.end(JSON.stringify({
    ok: true,
    service: 'AR Smart Study AI Backend',
    endpoints: ['/health', '/ai'],
  }));
};

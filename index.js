module.exports = function handler(request, response) {
  response.status(200).json({
    ok: true,
    service: 'AR Smart Study AI Backend',
    endpoints: ['/health', '/ai'],
  });
};

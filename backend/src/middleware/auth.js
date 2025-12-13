export async function authMiddleware(request, reply) {
  const installId = request.headers['x-install-id'];
  
  if (!installId || typeof installId !== 'string') {
    return reply.code(401).send({ error: 'Missing or invalid X-Install-Id header' });
  }

  request.installId = installId;
}


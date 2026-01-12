/**
 * JWT authentication middleware
 * Verifies JWT token from Authorization header
 */
export async function jwtAuthMiddleware(request, reply) {
  try {
    const authHeader = request.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return reply.code(401).send({
        error: 'Missing or invalid authorization header',
      });
    }

    const token = authHeader.substring(7);
    
    try {
      const decoded = await request.server.jwt.verify(token);
      request.user = decoded;
    } catch (error) {
      return reply.code(401).send({
        error: 'Invalid or expired token',
      });
    }
  } catch (error) {
    return reply.code(401).send({
      error: 'Authentication failed',
    });
  }
}

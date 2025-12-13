import redis from '../config/redis.js';

const RATE_LIMIT = 100; // requests per hour
const RATE_LIMIT_WINDOW = 3600; // 1 hour in seconds

export async function rateLimitMiddleware(request, reply) {
  const installId = request.installId;
  if (!installId) {
    return reply.code(401).send({ error: 'Unauthorized' });
  }

  const key = `ratelimit:${installId}`;
  const multi = redis.multi();
  multi.incr(key);
  multi.expire(key, RATE_LIMIT_WINDOW);
  const results = await multi.exec();
  const count = parseInt(results[0][1], 10);

  if (count > RATE_LIMIT) {
    return reply.code(429).send({ error: 'Rate limit exceeded' });
  }

  reply.header('X-RateLimit-Remaining', Math.max(0, RATE_LIMIT - count));
}


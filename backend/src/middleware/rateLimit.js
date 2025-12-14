import redis from '../config/redis.js';
import crypto from 'crypto';

// Configuration
const RATE_LIMITS = {
  // Per-user rate limits
  user: {
    requestsPerMinute: 20,    // Max requests per minute per user
    requestsPerHour: 100,     // Max requests per hour per user
  },
  // Per-IP rate limits (more generous for shared IPs)
  ip: {
    requestsPerMinute: 60,    // Max requests per minute per IP
    requestsPerHour: 300,     // Max requests per hour per IP
  },
  // Scan-specific limits (stricter - these cost money)
  scan: {
    requestsPerMinute: 5,     // Max scans per minute per user
    concurrentLimit: 2,       // Max concurrent scans per user
  },
};

/**
 * Hash IP address for privacy
 */
function hashIP(ip) {
  return crypto.createHash('sha256').update(ip || 'unknown').digest('hex').substring(0, 16);
}

/**
 * Get client IP from request
 */
function getClientIP(request) {
  return request.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
         request.headers['x-real-ip'] ||
         request.ip ||
         'unknown';
}

/**
 * Check rate limit and return result
 */
async function checkRateLimit(key, limit, windowSeconds) {
  const multi = redis.multi();
  multi.incr(key);
  multi.expire(key, windowSeconds);
  const results = await multi.exec();
  const count = parseInt(results[0][1], 10);
  
  return {
    allowed: count <= limit,
    count,
    limit,
    remaining: Math.max(0, limit - count),
  };
}

/**
 * Main rate limit middleware
 */
export async function rateLimitMiddleware(request, reply) {
  const installId = request.installId;
  if (!installId) {
    return reply.code(401).send({ error: 'Unauthorized' });
  }

  const ipHash = hashIP(getClientIP(request));
  const now = Math.floor(Date.now() / 1000);
  const minuteWindow = Math.floor(now / 60);
  const hourWindow = Math.floor(now / 3600);

  try {
    // Check user rate limits
    const userMinuteResult = await checkRateLimit(
      `ratelimit:user:minute:${installId}:${minuteWindow}`,
      RATE_LIMITS.user.requestsPerMinute,
      120 // 2 minutes expiry for safety
    );

    if (!userMinuteResult.allowed) {
      reply.header('X-RateLimit-Limit', RATE_LIMITS.user.requestsPerMinute);
      reply.header('X-RateLimit-Remaining', 0);
      reply.header('Retry-After', 60);
      return reply.code(429).send({
        error: 'Rate limit exceeded',
        message: 'Too many requests. Please wait a minute.',
        retryAfter: 60,
      });
    }

    const userHourResult = await checkRateLimit(
      `ratelimit:user:hour:${installId}:${hourWindow}`,
      RATE_LIMITS.user.requestsPerHour,
      7200 // 2 hours expiry for safety
    );

    if (!userHourResult.allowed) {
      reply.header('X-RateLimit-Limit', RATE_LIMITS.user.requestsPerHour);
      reply.header('X-RateLimit-Remaining', 0);
      reply.header('Retry-After', 3600);
      return reply.code(429).send({
        error: 'Rate limit exceeded',
        message: 'Hourly limit reached. Please try again later.',
        retryAfter: 3600,
      });
    }

    // Check IP rate limits
    const ipMinuteResult = await checkRateLimit(
      `ratelimit:ip:minute:${ipHash}:${minuteWindow}`,
      RATE_LIMITS.ip.requestsPerMinute,
      120
    );

    if (!ipMinuteResult.allowed) {
      return reply.code(429).send({
        error: 'Rate limit exceeded',
        message: 'Too many requests from this network.',
        retryAfter: 60,
      });
    }

    // Set headers
    reply.header('X-RateLimit-Limit', RATE_LIMITS.user.requestsPerMinute);
    reply.header('X-RateLimit-Remaining', userMinuteResult.remaining);

  } catch (error) {
    // If Redis fails, allow the request but log the error
    console.error('Rate limit check failed:', error.message);
  }
}

/**
 * Scan-specific rate limiting (stricter limits)
 */
export async function scanRateLimitMiddleware(request, reply) {
  const installId = request.installId;
  if (!installId) {
    return reply.code(401).send({ error: 'Unauthorized' });
  }

  const minuteWindow = Math.floor(Date.now() / 60000);

  try {
    // Check scan-specific per-minute limit
    const scanMinuteResult = await checkRateLimit(
      `ratelimit:scan:minute:${installId}:${minuteWindow}`,
      RATE_LIMITS.scan.requestsPerMinute,
      120
    );

    if (!scanMinuteResult.allowed) {
      return reply.code(429).send({
        error: 'Scan rate limit exceeded',
        message: 'You are scanning too quickly. Please wait a moment.',
        retryAfter: 30,
      });
    }

    // Check concurrent scan limit
    const concurrentKey = `concurrent:scan:${installId}`;
    const concurrent = await redis.incr(concurrentKey);
    await redis.expire(concurrentKey, 120); // 2 minute timeout

    if (concurrent > RATE_LIMITS.scan.concurrentLimit) {
      await redis.decr(concurrentKey);
      return reply.code(429).send({
        error: 'Too many concurrent scans',
        message: 'Please wait for your current scan to complete.',
        retryAfter: 10,
      });
    }

    // Store key for cleanup after response
    request.concurrentScanKey = concurrentKey;

  } catch (error) {
    console.error('Scan rate limit check failed:', error.message);
  }
}

/**
 * Release concurrent scan slot (call after scan completes)
 */
export async function releaseScanSlot(installId) {
  try {
    const concurrentKey = `concurrent:scan:${installId}`;
    await redis.decr(concurrentKey);
  } catch (error) {
    console.error('Failed to release scan slot:', error.message);
  }
}

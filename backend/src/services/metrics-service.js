import redis from '../config/redis.js';

/**
 * Simple metrics service for tracking usage and performance
 * Uses Redis for persistent, distributed metrics
 */

const METRICS_TTL = 30 * 24 * 3600; // 30 days retention

/**
 * Get current date keys for different granularities
 */
function getDateKeys() {
  const now = new Date();
  return {
    minute: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}-${String(now.getMinutes()).padStart(2, '0')}`,
    hour: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}`,
    day: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`,
    month: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
  };
}

/**
 * Increment a counter metric
 */
export async function incrementCounter(name, tags = {}) {
  try {
    const dateKeys = getDateKeys();
    const tagStr = Object.entries(tags).map(([k, v]) => `${k}:${v}`).join(':');
    const baseKey = `metrics:${name}${tagStr ? ':' + tagStr : ''}`;
    
    const multi = redis.multi();
    
    // Increment hourly counter
    const hourKey = `${baseKey}:hour:${dateKeys.hour}`;
    multi.incr(hourKey);
    multi.expire(hourKey, METRICS_TTL);
    
    // Increment daily counter
    const dayKey = `${baseKey}:day:${dateKeys.day}`;
    multi.incr(dayKey);
    multi.expire(dayKey, METRICS_TTL);
    
    await multi.exec();
  } catch (error) {
    // Don't fail requests due to metrics errors
    console.error('Metrics increment failed:', error.message);
  }
}

/**
 * Record a timing metric (histogram)
 */
export async function recordTiming(name, durationMs, tags = {}) {
  try {
    const dateKeys = getDateKeys();
    const tagStr = Object.entries(tags).map(([k, v]) => `${k}:${v}`).join(':');
    const baseKey = `metrics:timing:${name}${tagStr ? ':' + tagStr : ''}`;
    
    // Store timing in a sorted set for percentile calculations
    const hourKey = `${baseKey}:hour:${dateKeys.hour}`;
    
    const multi = redis.multi();
    multi.zadd(hourKey, durationMs, `${Date.now()}-${Math.random()}`);
    multi.expire(hourKey, METRICS_TTL);
    // Trim to last 1000 samples per hour
    multi.zremrangebyrank(hourKey, 0, -1001);
    
    await multi.exec();
  } catch (error) {
    console.error('Metrics timing failed:', error.message);
  }
}

/**
 * Track scan metrics
 */
export async function trackScan(result, durationMs, isPremium) {
  const status = result === 'success' ? 'success' : result === 'quota_exceeded' ? 'quota_exceeded' : 'error';
  
  await incrementCounter('scans', { status, premium: isPremium ? 'true' : 'false' });
  
  if (status === 'success') {
    await recordTiming('scan_duration', durationMs, { premium: isPremium ? 'true' : 'false' });
  }
}

/**
 * Track API error
 */
export async function trackError(errorType, path) {
  await incrementCounter('errors', { type: errorType, path: path.replace(/[^a-zA-Z0-9]/g, '_') });
}

/**
 * Track rate limit hits
 */
export async function trackRateLimit(type) {
  await incrementCounter('rate_limits', { type });
}

/**
 * Get metrics summary (for admin/monitoring)
 */
export async function getMetricsSummary() {
  try {
    const dateKeys = getDateKeys();
    
    const [
      scansSuccessToday,
      scansErrorToday,
      rateLimitsToday,
    ] = await Promise.all([
      redis.get(`metrics:scans:status:success:day:${dateKeys.day}`),
      redis.get(`metrics:scans:status:error:day:${dateKeys.day}`),
      redis.get(`metrics:rate_limits:day:${dateKeys.day}`),
    ]);
    
    return {
      date: dateKeys.day,
      scans: {
        success: parseInt(scansSuccessToday || '0', 10),
        error: parseInt(scansErrorToday || '0', 10),
      },
      rateLimits: parseInt(rateLimitsToday || '0', 10),
    };
  } catch (error) {
    console.error('Failed to get metrics summary:', error.message);
    return null;
  }
}


import Redis from 'ioredis';

let redisHealthy = false;
let lastErrorLogAt = 0;

const redis = new Redis(process.env.REDIS_URL, {
  lazyConnect: true,
  enableOfflineQueue: false,
  maxRetriesPerRequest: 1,
  connectTimeout: 8000,
  retryStrategy(times) {
    // Stop infinite reconnect loops on bad DNS/configuration.
    if (times > 5) {
      return null;
    }
    const delay = Math.min(times * 250, 3000);
    return delay;
  },
});

redis.on('connect', () => {
  redisHealthy = true;
  console.log('Redis connected');
});

redis.on('ready', () => {
  redisHealthy = true;
});

redis.on('error', (err) => {
  redisHealthy = false;
  // Throttle repetitive connection errors to avoid log flooding.
  const now = Date.now();
  if (now - lastErrorLogAt > 30000) {
    lastErrorLogAt = now;
    console.error('Redis connection error:', err.message);
  }
});

redis.on('end', () => {
  redisHealthy = false;
});

export default redis;
export function isRedisHealthy() {
  return redisHealthy;
}


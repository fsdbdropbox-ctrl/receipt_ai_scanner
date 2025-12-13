import redis from '../config/redis.js';

const DAILY_FREE_LIMIT = parseInt(process.env.DAILY_FREE_LIMIT || '5', 10);

export async function checkQuota(installId) {
  const key = `quota:${installId}:${getTodayKey()}`;
  const count = await redis.get(key);
  return parseInt(count || '0', 10);
}

export async function consumeQuota(installId) {
  const key = `quota:${installId}:${getTodayKey()}`;
  const multi = redis.multi();
  multi.incr(key);
  multi.expire(key, 86400); // 24 hours
  const results = await multi.exec();
  return parseInt(results[0][1], 10);
}

export async function getScansLeft(installId, isPremium) {
  if (isPremium) {
    return -1; // Unlimited
  }
  const used = await checkQuota(installId);
  return Math.max(0, DAILY_FREE_LIMIT - used);
}

function getTodayKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}


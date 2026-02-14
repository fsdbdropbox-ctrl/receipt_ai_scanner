import redis from '../config/redis.js';

export async function getUserPlan(installId) {
  const key = `user:${installId}:plan`;
  try {
    const plan = await redis.get(key);
    return plan === 'premium';
  } catch {
    // Fail-open as free plan if Redis is unavailable.
    return false;
  }
}

export async function setUserPlan(installId, isPremium) {
  const key = `user:${installId}:plan`;
  try {
    if (isPremium) {
      await redis.set(key, 'premium');
    } else {
      await redis.del(key);
    }
  } catch {
    // Non-critical write failure; plan remains in source of truth elsewhere.
  }
}


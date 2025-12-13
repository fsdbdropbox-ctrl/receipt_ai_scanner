import redis from '../config/redis.js';

export async function getUserPlan(installId) {
  const key = `user:${installId}:plan`;
  const plan = await redis.get(key);
  return plan === 'premium';
}

export async function setUserPlan(installId, isPremium) {
  const key = `user:${installId}:plan`;
  if (isPremium) {
    await redis.set(key, 'premium');
  } else {
    await redis.del(key);
  }
}


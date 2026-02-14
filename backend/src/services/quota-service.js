import redis from '../config/redis.js';

// Quota limits (hardcoded - no longer configurable via env vars)
const DAILY_FREE_LIMIT = 5;
const MONTHLY_PREMIUM_LIMIT = 1000;
// IP-based limits to prevent incognito/private browsing abuse
const DAILY_IP_FREE_LIMIT = 15;

async function safeGetCount(key) {
  try {
    const count = await redis.get(key);
    return parseInt(count || '0', 10);
  } catch {
    return 0;
  }
}

/**
 * Get today's key in YYYY-MM-DD format
 */
function getTodayKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

/**
 * Get current month key in YYYY-MM format
 */
function getMonthKey() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

/**
 * Get days until month reset
 */
function getDaysUntilReset() {
  const now = new Date();
  const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  return lastDay.getDate() - now.getDate();
}

/**
 * Check daily quota usage for free users
 */
export async function checkDailyQuota(installId) {
  const key = `quota:daily:${installId}:${getTodayKey()}`;
  return safeGetCount(key);
}

/**
 * Check daily quota usage by IP (prevents incognito abuse)
 */
export async function checkDailyIpQuota(ip) {
  if (!ip) return 0;
  // Normalize IP (remove port if present, handle IPv6)
  const normalizedIp = ip.replace(/:\d+$/, '').replace(/^::ffff:/, '');
  const key = `quota:ip:daily:${normalizedIp}:${getTodayKey()}`;
  return safeGetCount(key);
}

/**
 * Consume IP-based quota
 */
export async function consumeIpQuota(ip) {
  if (!ip) return 0;
  const normalizedIp = ip.replace(/:\d+$/, '').replace(/^::ffff:/, '');
  const key = `quota:ip:daily:${normalizedIp}:${getTodayKey()}`;
  try {
    const multi = redis.multi();
    multi.incr(key);
    multi.expire(key, 86400); // 24 hours
    const results = await multi.exec();
    return parseInt(results[0][1], 10);
  } catch {
    return 0;
  }
}

/**
 * Check monthly quota usage for premium users
 */
export async function checkMonthlyQuota(installId) {
  const key = `quota:monthly:${installId}:${getMonthKey()}`;
  return safeGetCount(key);
}

/**
 * Consume quota (call AFTER successful processing)
 * @param {string} installId - User identifier
 * @param {boolean} isPremium - Whether user is premium
 * @param {string} ip - User IP address (for anti-abuse tracking)
 * @returns {Object} - Updated quota info
 */
export async function consumeQuota(installId, isPremium = false, ip = null) {
  try {
    const multi = redis.multi();

    if (isPremium) {
      // Track monthly usage for premium
      const monthKey = `quota:monthly:${installId}:${getMonthKey()}`;
      multi.incr(monthKey);
      // Expire at end of month + buffer (35 days)
      multi.expire(monthKey, 35 * 24 * 3600);
    } else {
      // Track daily usage for free (by installId)
      const dayKey = `quota:daily:${installId}:${getTodayKey()}`;
      multi.incr(dayKey);
      multi.expire(dayKey, 86400);

      // Also track by IP to prevent incognito abuse
      if (ip) {
        const normalizedIp = ip.replace(/:\d+$/, '').replace(/^::ffff:/, '');
        const ipKey = `quota:ip:daily:${normalizedIp}:${getTodayKey()}`;
        multi.incr(ipKey);
        multi.expire(ipKey, 86400);
      }
    }

    const results = await multi.exec();
    return parseInt(results[0][1], 10);
  } catch {
    return 0;
  }
}

/**
 * Get remaining scans and quota info
 * @param {string} installId - User identifier
 * @param {boolean} isPremium - Whether user is premium
 * @returns {Object} - Quota details
 */
export async function getQuotaInfo(installId, isPremium) {
  if (isPremium) {
    const used = await checkMonthlyQuota(installId);
    const remaining = Math.max(0, MONTHLY_PREMIUM_LIMIT - used);
    return {
      scansLeft: remaining,
      scansUsed: used,
      limit: MONTHLY_PREMIUM_LIMIT,
      period: 'monthly',
      daysUntilReset: getDaysUntilReset(),
      isPremium: true,
      limitReached: remaining <= 0,
    };
  }
  
  const used = await checkDailyQuota(installId);
  const remaining = Math.max(0, DAILY_FREE_LIMIT - used);
  return {
    scansLeft: remaining,
    scansUsed: used,
    limit: DAILY_FREE_LIMIT,
    period: 'daily',
    isPremium: false,
    limitReached: remaining <= 0,
  };
}

/**
 * Check if user can scan (BEFORE processing)
 * @param {string} installId - User identifier
 * @param {boolean} isPremium - Whether user is premium
 * @param {string} ip - User IP address (for anti-abuse)
 * @returns {Object} - Can scan + quota info
 */
export async function canScan(installId, isPremium, ip = null) {
  const quotaInfo = await getQuotaInfo(installId, isPremium);
  
  // For free users, also check IP-based limit (prevents incognito abuse)
  if (!isPremium && ip) {
    const ipUsed = await checkDailyIpQuota(ip);
    const ipLimitReached = ipUsed >= DAILY_IP_FREE_LIMIT;
    
    if (ipLimitReached) {
      return {
        allowed: false,
        ...quotaInfo,
        limitReached: true,
        ipLimitReached: true,
        ipUsed,
        ipLimit: DAILY_IP_FREE_LIMIT,
        message: 'Daily limit reached for this network. Upgrade for unlimited scans.',
      };
    }
  }
  
  return {
    allowed: !quotaInfo.limitReached,
    ...quotaInfo,
  };
}

// Legacy exports for backwards compatibility
export async function getScansLeft(installId, isPremium) {
  const info = await getQuotaInfo(installId, isPremium);
  // Return -1 for "unlimited" display but we still enforce monthly cap
  if (isPremium && info.scansLeft > 100) {
    return -1; // Show as unlimited in UI
  }
  return info.scansLeft;
}

// Legacy - kept for backwards compatibility
export async function checkQuota(installId) {
  return await checkDailyQuota(installId);
}

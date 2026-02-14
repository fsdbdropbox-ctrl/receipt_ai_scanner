import redis from '../config/redis.js';

/**
 * Webhook idempotency middleware
 * Prevents duplicate processing of Stripe webhook events
 */

const PROCESSED_EVENT_TTL = 7 * 24 * 3600; // 7 days

/**
 * Check if event was already processed
 * @param {string} eventId - Stripe event ID
 * @returns {boolean} - True if already processed
 */
export async function isEventProcessed(eventId) {
  const key = `webhook:processed:${eventId}`;
  try {
    const exists = await redis.exists(key);
    return exists === 1;
  } catch {
    return false;
  }
}

/**
 * Mark event as processed
 * @param {string} eventId - Stripe event ID
 * @param {Object} metadata - Optional metadata to store
 */
export async function markEventProcessed(eventId, metadata = {}) {
  const key = `webhook:processed:${eventId}`;
  const value = JSON.stringify({
    processedAt: new Date().toISOString(),
    ...metadata,
  });
  try {
    await redis.setex(key, PROCESSED_EVENT_TTL, value);
  } catch {
    // Non-critical; idempotency cache can be skipped when Redis is down.
  }
}

/**
 * Get processed event info (for debugging)
 * @param {string} eventId - Stripe event ID
 * @returns {Object|null} - Event metadata or null
 */
export async function getProcessedEventInfo(eventId) {
  const key = `webhook:processed:${eventId}`;
  let value = null;
  try {
    value = await redis.get(key);
  } catch {
    return null;
  }
  if (value) {
    try {
      return JSON.parse(value);
    } catch (e) {
      return { raw: value };
    }
  }
  return null;
}

/**
 * Middleware wrapper for idempotent webhook processing
 * @param {Function} handler - The actual webhook handler
 * @returns {Function} - Wrapped handler
 */
export function withIdempotency(handler) {
  return async (event, fastify) => {
    const eventId = event.id;
    
    // Check if already processed
    if (await isEventProcessed(eventId)) {
      fastify.log.info({ eventId, type: event.type }, 'Webhook event already processed, skipping');
      return { skipped: true, reason: 'already_processed' };
    }
    
    // Process the event
    const result = await handler(event, fastify);
    
    // Mark as processed
    await markEventProcessed(eventId, {
      type: event.type,
      result: result?.success ? 'success' : 'handled',
    });
    
    return result;
  };
}


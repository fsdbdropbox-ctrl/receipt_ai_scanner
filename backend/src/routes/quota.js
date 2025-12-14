import { getQuotaInfo } from '../services/quota-service.js';
import { getUserPlan } from '../services/user-service.js';

/**
 * GET /api/quota - Get current quota status
 * Allows frontend to refresh quota without scanning
 */
export async function quotaRoute(fastify) {
  fastify.get('/api/quota', async (request, reply) => {
    const installId = request.installId;
    
    try {
      const isPremium = await getUserPlan(installId);
      const quotaInfo = await getQuotaInfo(installId, isPremium);
      
      return {
        quota: {
          scansLeft: quotaInfo.scansLeft,
          scansUsed: quotaInfo.scansUsed,
          limit: quotaInfo.limit,
          period: quotaInfo.period,
          daysUntilReset: quotaInfo.daysUntilReset,
          isPremium,
          limitReached: quotaInfo.limitReached,
        },
      };
    } catch (error) {
      fastify.log.error({ err: error.message }, 'Failed to get quota info');
      return reply.code(500).send({
        error: 'Failed to get quota',
        message: 'Unable to retrieve quota information',
      });
    }
  });
}


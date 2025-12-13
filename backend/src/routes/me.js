import { getUserPlan } from '../services/user-service.js';
import { getScansLeft } from '../services/quota-service.js';

export async function meRoute(fastify) {
  fastify.get('/api/me', async (request, reply) => {
    const installId = request.installId;
    const isPremium = await getUserPlan(installId);
    const scansLeft = await getScansLeft(installId, isPremium);

    return reply.send({
      isPremium,
      scansLeft,
    });
  });
}


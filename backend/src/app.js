import Fastify from 'fastify';
import cors from '@fastify/cors';
import multipart from '@fastify/multipart';
import rawBody from '@fastify/raw-body';
import { authMiddleware } from './middleware/auth.js';
import { rateLimitMiddleware } from './middleware/rateLimit.js';
import { scanInvoiceRoute } from './routes/scan-invoice.js';
import { meRoute } from './routes/me.js';
import { createCheckoutSessionRoute } from './routes/create-checkout-session.js';
import { stripeWebhookRoute } from './routes/stripe-webhook.js';
import { logRequest, logError } from './utils/logger.js';

const fastify = Fastify({
  logger: true,
});

// CORS
const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];
if (allowedOrigins.length === 0) {
  throw new Error('ALLOWED_ORIGINS must be configured');
}

await fastify.register(cors, {
  origin: allowedOrigins,
  credentials: true,
});

// Raw body parser (for Stripe webhooks)
await fastify.register(rawBody, {
  field: 'rawBody',
  global: false,
  encoding: false, // Buffer (necesario para Stripe)
  runFirst: true,
});

// Multipart
await fastify.register(multipart);

// Middleware
fastify.addHook('onRequest', async (request, reply) => {
  const start = Date.now();
  reply.addHook('onSend', async (request, reply) => {
    const duration = Date.now() - start;
    logRequest(request, reply, duration);
  });
});

fastify.addHook('onError', async (request, reply, error) => {
  logError(error, { path: request.url, method: request.method });
});

// Routes
await fastify.register(async (fastify) => {
  fastify.addHook('preHandler', authMiddleware);
  fastify.addHook('preHandler', rateLimitMiddleware);
  
  await fastify.register(scanInvoiceRoute);
  await fastify.register(meRoute);
  await fastify.register(createCheckoutSessionRoute);
});

// Stripe webhook (no auth, uses signature verification)
await fastify.register(stripeWebhookRoute);

// Health check
fastify.get('/health', async (request, reply) => {
  return { status: 'ok' };
});

// Start server
const start = async () => {
  try {
    const port = parseInt(process.env.PORT || '3000', 10);
    await fastify.listen({ port, host: '0.0.0.0' });
    console.log(`Server listening on port ${port}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();


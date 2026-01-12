// #region External Dependencies
import Fastify from 'fastify';
import cors from '@fastify/cors';
import multipart from '@fastify/multipart';
import jwt from '@fastify/jwt';
// #endregion

// #region Config
import { initSentry, default as Sentry } from './config/sentry.js';
// #endregion

// #region Middleware
import { authMiddleware } from './middleware/auth.js';
import { rateLimitMiddleware } from './middleware/rateLimit.js';
import { getUploadLimits } from './middleware/uploadValidation.js';
import { jwtAuthMiddleware } from './middleware/jwt-auth.js';
// #endregion

// #region Routes
import { scanInvoiceRoute } from './routes/scan-invoice.js';
import { meRoute } from './routes/me.js';
import { createCheckoutSessionRoute } from './routes/create-checkout-session.js';
import { stripeWebhookRoute } from './routes/stripe-webhook.js';
import { quotaRoute } from './routes/quota.js';
import { authRoute } from './routes/auth.js';
import { fiscalProfileRoute } from './routes/fiscal-profile.js';
import { scanInvoiceV2Route, autoFixRoute } from './routes/scan-invoice-v2.js';
import { dashboardRoute } from './routes/dashboard.js';
// #endregion

// #region Utils
import { logRequest, logError } from './utils/logger.js';
// #endregion

// Initialize Sentry early
initSentry();

const fastify = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    // Redact sensitive fields from logs
    redact: {
      paths: [
        'req.headers.authorization',
        'req.headers["x-install-id"]',
        'req.headers.cookie',
        'req.body.password',
        'req.body.token',
      ],
      censor: '[REDACTED]',
    },
  },
});

// Security headers - register BEFORE other hooks
fastify.addHook('onRequest', async (request, reply) => {
  // Security headers to prevent common attacks
  reply.header('X-Content-Type-Options', 'nosniff');
  reply.header('X-Frame-Options', 'DENY');
  reply.header('X-XSS-Protection', '1; mode=block');
  reply.header('Referrer-Policy', 'strict-origin-when-cross-origin');

  // Only add HSTS in production with HTTPS
  if (process.env.NODE_ENV === 'production' && request.protocol === 'https') {
    reply.header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  }

  request.requestStartTime = Date.now();
});

fastify.addHook('onResponse', async (request, reply) => {
  if (request.requestStartTime) {
    const duration = Date.now() - request.requestStartTime;
    logRequest(request, reply, duration);
  }
});

fastify.addHook('onError', async (request, reply, error) => {
  // Sanitize error before logging
  logError(error, {
    path: request.url,
    method: request.method,
    // Don't log installId in full
    installId: request.installId ? request.installId.substring(0, 8) + '...' : undefined,
  });

  // Report to Sentry
  if (process.env.SENTRY_DSN) {
    Sentry.captureException(error, {
      tags: {
        path: request.url,
        method: request.method,
      },
      // Don't include full installId
      extra: {
        installIdPrefix: request.installId?.substring(0, 8),
      },
    });
  }
});

// CORS Configuration (strict in production)
const isProduction = process.env.NODE_ENV === 'production';
const allowedOriginsEnv = process.env.ALLOWED_ORIGINS || '';

let corsOrigin;
if (isProduction && allowedOriginsEnv) {
  // Production: only allow specified origins
  corsOrigin = allowedOriginsEnv.split(',').map(o => o.trim()).filter(Boolean);
  if (corsOrigin.length === 0) {
    console.warn('Warning: ALLOWED_ORIGINS is empty in production. CORS will be restrictive.');
    corsOrigin = false; // Deny all cross-origin requests
  }
} else if (isProduction) {
  // Production without ALLOWED_ORIGINS: deny CORS
  console.warn('Warning: ALLOWED_ORIGINS not set in production. Cross-origin requests will be denied.');
  corsOrigin = false;
} else {
  // Development: allow all
  corsOrigin = true;
}

await fastify.register(cors, {
  origin: corsOrigin,
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'X-Install-Id', 'Authorization', 'X-Requested-With'],
  maxAge: 86400, // Cache preflight for 24 hours
});

// JWT plugin - SECURITY: Require JWT_SECRET in production
const jwtSecret = process.env.JWT_SECRET;
if (!jwtSecret) {
  if (process.env.NODE_ENV === 'production') {
    console.error('CRITICAL: JWT_SECRET is required in production. Exiting.');
    process.exit(1);
  }
  console.warn('WARNING: JWT_SECRET not set. Using insecure default. DO NOT USE IN PRODUCTION.');
}

await fastify.register(jwt, {
  secret: jwtSecret || 'change-me-in-production',
});

// Multipart with limits
const uploadLimits = getUploadLimits();
await fastify.register(multipart, {
  limits: {
    fileSize: uploadLimits.maxSizeBytes,
    files: 1, // Only allow 1 file per request
    fields: 5, // Limit form fields
  },
});

// Public OAuth route (no auth required)
await fastify.register(authRoute);

// Protected routes v1 (legacy - Install ID based)
await fastify.register(async (fastify) => {
  fastify.addHook('preHandler', authMiddleware);
  fastify.addHook('preHandler', rateLimitMiddleware);

  await fastify.register(scanInvoiceRoute);
  await fastify.register(meRoute);
  await fastify.register(createCheckoutSessionRoute);
  await fastify.register(quotaRoute);
});

// Protected routes v2 (JWT-based, OAuth required)
await fastify.register(async (fastify) => {
  fastify.addHook('preHandler', jwtAuthMiddleware);

  await fastify.register(fiscalProfileRoute);
  await fastify.register(scanInvoiceV2Route);
  await fastify.register(autoFixRoute);
  await fastify.register(dashboardRoute);
});

// Stripe webhook (no auth, uses signature verification)
await fastify.register(stripeWebhookRoute);

// Root endpoint (public)
fastify.get('/', async (request, reply) => {
  return {
    service: 'AuditReady API',
    version: process.env.npm_package_version || '1.0.0',
    status: 'running',
    endpoints: {
      health: '/health',
      auth: '/api/auth/oauth',
      docs: 'See README.md for API documentation',
    },
  };
});

// Health check (public)
fastify.get('/health', async (request, reply) => {
  return {
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
  };
});

// 404 handler - provide helpful error messages
fastify.setNotFoundHandler(async (request, reply) => {
  return reply.code(404).send({
    error: 'Route not found',
    message: `Route ${request.method}:${request.url} not found`,
    availableRoutes: {
      health: 'GET /health',
      root: 'GET /',
      oauth: 'POST /api/auth/oauth',
      fiscalProfile: 'GET /api/fiscal-profile',
      dashboard: 'GET /api/dashboard/metrics',
    },
  });
});

// Upload limits endpoint (public, for frontend reference)
fastify.get('/api/upload-limits', async (request, reply) => {
  return getUploadLimits();
});

// Validate required environment variables
const requiredEnvVars = ['GEMINI_API_KEY', 'REDIS_URL', 'STRIPE_SECRET_KEY', 'DATABASE_URL', 'JWT_SECRET'];
const missingVars = requiredEnvVars.filter(v => !process.env[v]);

if (missingVars.length > 0) {
  console.error('Missing required environment variables:', missingVars.join(', '));
  process.exit(1);
}

// Warn about recommended env vars
const recommendedEnvVars = ['STRIPE_WEBHOOK_SECRET', 'ALLOWED_ORIGINS', 'SENTRY_DSN', 'GOOGLE_CLIENT_ID'];
const missingRecommended = recommendedEnvVars.filter(v => !process.env[v]);
if (missingRecommended.length > 0) {
  console.warn('Missing recommended environment variables:', missingRecommended.join(', '));
  if (missingRecommended.includes('GOOGLE_CLIENT_ID')) {
    console.warn('  Note: GOOGLE_CLIENT_ID is required for Google OAuth verification');
  }
}

// Start server
const start = async () => {
  try {
    const port = Number(process.env.PORT || 8080);
    await fastify.listen({
      port,
      host: '0.0.0.0',
    });
    console.log(`Server listening on port ${port}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`CORS origins: ${typeof corsOrigin === 'boolean' ? (corsOrigin ? 'all' : 'none') : corsOrigin.join(', ')}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();

import { hashIP } from './crypto.js';

export function logRequest(req, res, responseTime) {
  const ipHash = req.ip ? hashIP(req.ip) : 'unknown';
  console.log({
    method: req.method,
    path: req.url,
    statusCode: res.statusCode,
    responseTime: `${responseTime}ms`,
    ipHash,
    timestamp: new Date().toISOString(),
  });
}

export function logError(error, context = {}) {
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  // Only expose stack traces in development
  // In production, log minimal information to prevent information leakage
  console.error({
    error: error.message,
    stack: isDevelopment ? error.stack : undefined,
    context: isDevelopment ? context : {
      // Only include safe context in production
      path: context.path,
      method: context.method,
      // Don't log sensitive data
    },
    timestamp: new Date().toISOString(),
  });
}


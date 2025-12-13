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
  console.error({
    error: error.message,
    stack: error.stack,
    context,
    timestamp: new Date().toISOString(),
  });
}


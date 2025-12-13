import crypto from 'crypto';

export function hashIP(ip) {
  if (!ip) return null;
  return crypto.createHash('sha256').update(ip).digest('hex');
}

export function generateInstallId() {
  return crypto.randomUUID();
}


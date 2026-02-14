import pg from 'pg';
const { Pool } = pg;

// PostgreSQL connection pool
let pool = null;

export function getPool() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    
    if (!connectionString) {
      throw new Error('DATABASE_URL environment variable is required');
    }

    pool = new Pool({
      connectionString,
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
      // Prefer IPv4 on platforms with partial IPv6 connectivity.
      family: 4,
      max: 20, // Maximum number of clients in the pool
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
    });

    // Handle pool errors
    pool.on('error', (err) => {
      // Log error without exposing connection details
      console.error('Database pool error:', err.message);
      process.exit(-1);
    });
  }

  return pool;
}

export async function query(text, params) {
  const pool = getPool();
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    // Only log queries in development (security: don't expose SQL in production logs)
    if (process.env.NODE_ENV === 'development') {
      console.log('Executed query', { text: text.substring(0, 100) + '...', duration, rows: res.rowCount });
    }
    return res;
  } catch (error) {
    // Always log errors, but sanitize SQL in production
    const isDevelopment = process.env.NODE_ENV === 'development';
    console.error('Database query error', { 
      text: isDevelopment ? text : '[REDACTED]', 
      error: error?.message || String(error),
      code: error?.code,
      detail: isDevelopment ? error?.detail : undefined,
      hint: isDevelopment ? error?.hint : undefined,
    });
    throw error;
  }
}

export async function closePool() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

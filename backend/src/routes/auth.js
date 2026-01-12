import { query } from '../db/pool.js';
import { verifyOAuthToken } from '../services/oauth-verification.js';

/**
 * OAuth authentication routes
 * POST /api/auth/oauth - Verify OAuth token and create/update user
 */
export async function authRoute(fastify) {
  // Main route with /api/ prefix
  fastify.post('/api/auth/oauth', async (request, reply) => {
    return handleOAuth(request, reply, fastify);
  });
  
  // Alternative route without /api/ prefix (for Cloudflare/proxy compatibility)
  fastify.post('/auth/oauth', async (request, reply) => {
    return handleOAuth(request, reply, fastify);
  });
}

async function handleOAuth(request, reply, fastify) {
    try {
      const { provider, token, email, oauthId } = request.body;

      if (!provider || !token || !email || !oauthId) {
        return reply.code(400).send({
          error: 'Missing required fields: provider, token, email, oauthId',
        });
      }

      if (!['apple', 'google'].includes(provider)) {
        return reply.code(400).send({
          error: 'Invalid provider. Must be "apple" or "google"',
        });
      }

      // Validate email format
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return reply.code(400).send({
          error: 'Invalid email format',
        });
      }

      // Validate oauthId (should be alphanumeric, max 255 chars)
      if (typeof oauthId !== 'string' || oauthId.length > 255 || !/^[a-zA-Z0-9._-]+$/.test(oauthId)) {
        return reply.code(400).send({
          error: 'Invalid oauthId format',
        });
      }

      // SECURITY: Verify OAuth token with provider (Apple/Google)
      // This ensures the token is valid and hasn't been tampered with
      let verifiedPayload;
      try {
        // Debug: Log token info (first 20 chars only)
        fastify.log.info({ 
          provider,
          tokenPrefix: token ? `${token.substring(0, 20)}...` : 'null',
          hasGoogleClientId: !!process.env.GOOGLE_CLIENT_ID,
          googleClientIdPrefix: process.env.GOOGLE_CLIENT_ID ? `${process.env.GOOGLE_CLIENT_ID.substring(0, 20)}...` : 'NOT SET',
        }, 'Attempting OAuth token verification');
        
        verifiedPayload = await verifyOAuthToken(provider, token, oauthId, email);
      } catch (verificationError) {
        fastify.log.warn({ 
          provider, 
          error: verificationError.message,
          errorStack: verificationError.stack,
          hasGoogleClientId: !!process.env.GOOGLE_CLIENT_ID,
          googleClientIdPrefix: process.env.GOOGLE_CLIENT_ID ? `${process.env.GOOGLE_CLIENT_ID.substring(0, 20)}...` : 'NOT SET',
        }, 'OAuth token verification failed');
        
        // Provide more helpful error message
        const isDevelopment = process.env.NODE_ENV === 'development';
        let errorMessage = 'Token verification failed. Please sign in again.';
        
        if (verificationError.message.includes('GOOGLE_CLIENT_ID')) {
          errorMessage = 'Server configuration error: GOOGLE_CLIENT_ID not configured. Please contact support.';
        } else if (verificationError.message.includes('Invalid audience') || verificationError.message.includes('audience')) {
          errorMessage = 'Client ID mismatch: The token was issued for a different Client ID. Please verify GOOGLE_CLIENT_ID in Railway matches the one used in the app.';
        } else if (isDevelopment) {
          errorMessage = `Token verification failed: ${verificationError.message}`;
        }
        
        return reply.code(401).send({
          error: 'Invalid OAuth token',
          message: errorMessage,
        });
      }
      
      // Use verified email from token if available (more trustworthy)
      // For Apple, email might be null, so we use the one from request body
      const verifiedEmail = verifiedPayload.email || email;

      // Find or create user
      let userResult = await query(
        `SELECT * FROM users WHERE oauth_provider = $1 AND oauth_id = $2`,
        [provider, oauthId]
      );

      let user;
      if (userResult.rows.length === 0) {
        // Create new user with verified email
        const result = await query(
          `INSERT INTO users (email, oauth_provider, oauth_id)
           VALUES ($1, $2, $3)
           RETURNING *`,
          [verifiedEmail, provider, oauthId]
        );
        user = result.rows[0];
      } else {
        // Update existing user with verified email
        const result = await query(
          `UPDATE users SET email = $1, updated_at = CURRENT_TIMESTAMP
           WHERE oauth_provider = $2 AND oauth_id = $3
           RETURNING *`,
          [verifiedEmail, provider, oauthId]
        );
        user = result.rows[0];
      }

      // Check if user has fiscal profile
      const profileResult = await query(
        `SELECT * FROM fiscal_profiles WHERE user_id = $1`,
        [user.id]
      );

      const hasProfile = profileResult.rows.length > 0;

      // Generate JWT token
      const jwtToken = fastify.jwt.sign({
        userId: user.id,
        email: user.email,
        provider: user.oauth_provider,
      });

      return reply.send({
        token: jwtToken,
        user: {
          id: user.id,
          email: user.email,
          provider: user.oauth_provider,
          hasFiscalProfile: hasProfile,
        },
      });
    } catch (error) {
      fastify.log.error({ error, path: '/api/auth/oauth' }, 'Authentication error');
      // Don't expose internal error details to client
      const isDevelopment = process.env.NODE_ENV === 'development';
      return reply.code(500).send({
        error: 'Authentication failed',
        message: isDevelopment ? error.message : 'An error occurred during authentication. Please try again.',
      });
    }
}

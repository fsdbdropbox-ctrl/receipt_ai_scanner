import { query } from '../db/pool.js';
import { getFiscalRules } from '../services/fiscal-rules.js';

/**
 * Fiscal profile routes
 * GET /api/fiscal-profile - Get user's fiscal profile
 * POST /api/fiscal-profile - Create/update fiscal profile
 */
export async function fiscalProfileRoute(fastify) {
  // Get fiscal profile
  fastify.get('/api/fiscal-profile', async (request, reply) => {
    try {
      const userId = request.user.userId;

      const result = await query(
        `SELECT * FROM fiscal_profiles WHERE user_id = $1`,
        [userId]
      );

      if (result.rows.length === 0) {
        return reply.code(404).send({
          error: 'Fiscal profile not found',
        });
      }

      const profile = result.rows[0];
      const rules = getFiscalRules(profile.country_code);

      return reply.send({
        ...profile,
        rules: rules || null,
      });
    } catch (error) {
      fastify.log.error({ error, path: '/api/fiscal-profile', userId: request.user?.userId }, 'Get fiscal profile error');
      const isDevelopment = process.env.NODE_ENV === 'development';
      return reply.code(500).send({
        error: 'Failed to get fiscal profile',
        message: isDevelopment ? error.message : 'An error occurred. Please try again.',
      });
    }
  });

  // Create or update fiscal profile
  fastify.post('/api/fiscal-profile', async (request, reply) => {
    try {
      const userId = request.user.userId;
      const { country_code, tax_id, tax_regime, activity_sector } = request.body;

      if (!country_code || !tax_id || !tax_regime) {
        return reply.code(400).send({
          error: 'Missing required fields: country_code, tax_id, tax_regime',
        });
      }

      // Validate country code format (ISO 3166-1 alpha-2: exactly 2 uppercase letters)
      if (typeof country_code !== 'string' || !/^[A-Z]{2}$/.test(country_code.toUpperCase())) {
        return reply.code(400).send({
          error: 'Invalid country code format. Must be ISO 3166-1 alpha-2 (e.g., ES, MX, DE)',
        });
      }

      // Validate tax_id (alphanumeric, max 50 chars)
      if (typeof tax_id !== 'string' || tax_id.length === 0 || tax_id.length > 50) {
        return reply.code(400).send({
          error: 'Invalid tax_id. Must be between 1 and 50 characters',
        });
      }

      // Validate tax_regime (alphanumeric with underscores/hyphens, max 50 chars)
      if (typeof tax_regime !== 'string' || tax_regime.length === 0 || tax_regime.length > 50 || !/^[a-zA-Z0-9_-]+$/.test(tax_regime)) {
        return reply.code(400).send({
          error: 'Invalid tax_regime format',
        });
      }

      // Validate country code
      const rules = getFiscalRules(country_code.toUpperCase());
      if (!rules) {
        return reply.code(400).send({
          error: `Unsupported country code: ${country_code}`,
        });
      }

      // Check if profile exists
      const existingResult = await query(
        `SELECT * FROM fiscal_profiles WHERE user_id = $1`,
        [userId]
      );

      let profile;
      if (existingResult.rows.length === 0) {
        // Create new profile
        const result = await query(
          `INSERT INTO fiscal_profiles (user_id, country_code, tax_id, tax_regime, activity_sector)
           VALUES ($1, $2, $3, $4, $5)
           RETURNING *`,
          [userId, country_code.toUpperCase(), tax_id.toUpperCase(), tax_regime, activity_sector || null]
        );
        profile = result.rows[0];
      } else {
        // Update existing profile
        const result = await query(
          `UPDATE fiscal_profiles
           SET country_code = $2, tax_id = $3, tax_regime = $4, activity_sector = $5, updated_at = CURRENT_TIMESTAMP
           WHERE user_id = $1
           RETURNING *`,
          [userId, country_code.toUpperCase(), tax_id.toUpperCase(), tax_regime, activity_sector || null]
        );
        profile = result.rows[0];
      }

      return reply.send({
        ...profile,
        rules: rules,
      });
    } catch (error) {
      fastify.log.error({ error, path: '/api/fiscal-profile', userId: request.user?.userId }, 'Create/update fiscal profile error');
      const isDevelopment = process.env.NODE_ENV === 'development';
      return reply.code(500).send({
        error: 'Failed to save fiscal profile',
        message: isDevelopment ? error.message : 'An error occurred. Please try again.',
      });
    }
  });
}

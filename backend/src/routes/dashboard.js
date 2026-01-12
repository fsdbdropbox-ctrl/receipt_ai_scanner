import { query } from '../db/pool.js';

/**
 * Dashboard routes - Get user's fiscal health metrics
 * GET /api/dashboard/metrics
 */
export async function dashboardRoute(fastify) {
  fastify.get('/api/dashboard/metrics', async (request, reply) => {
    const userId = request.user.userId;

    try {
      // Get document statistics
      const statsResult = await query(
        `SELECT 
          COUNT(*) as total_documents,
          COUNT(*) FILTER (WHERE validation_status = 'valid') as valid_documents,
          COUNT(*) FILTER (WHERE validation_status = 'invalid') as invalid_documents,
          COUNT(*) FILTER (WHERE validation_status = 'quarantine') as quarantine_documents,
          COUNT(*) FILTER (WHERE validation_status = 'pending') as pending_documents,
          SUM(total) as total_amount,
          AVG(confidence) as avg_confidence
         FROM documents
         WHERE user_id = $1`,
        [userId]
      );

      const stats = statsResult.rows[0];

      // Calculate integrity percentage
      const total = parseInt(stats.total_documents) || 0;
      const valid = parseInt(stats.valid_documents) || 0;
      const integrityPercentage = total > 0 ? Math.round((valid / total) * 100) : 100;

      // Get recent documents with validation issues
      const issuesResult = await query(
        `SELECT d.*, 
          (SELECT COUNT(*) FROM validation_flags vf 
           WHERE vf.document_id = d.id AND vf.fixed_at IS NULL) as open_flags
         FROM documents d
         WHERE d.user_id = $1 
           AND d.validation_status IN ('invalid', 'quarantine')
           AND d.archived_at IS NULL
         ORDER BY d.created_at DESC
         LIMIT 10`,
        [userId]
      );

      // Get validation flags summary
      const flagsResult = await query(
        `SELECT 
          vf.flag_code,
          vf.severity,
          COUNT(*) as count
         FROM validation_flags vf
         JOIN documents d ON vf.document_id = d.id
         WHERE d.user_id = $1 AND vf.fixed_at IS NULL
         GROUP BY vf.flag_code, vf.severity
         ORDER BY count DESC`,
        [userId]
      );

      return reply.send({
        integrity: {
          percentage: integrityPercentage,
          total: total,
          valid: valid,
          invalid: parseInt(stats.invalid_documents) || 0,
          quarantine: parseInt(stats.quarantine_documents) || 0,
          pending: parseInt(stats.pending_documents) || 0,
        },
        financial: {
          totalAmount: parseFloat(stats.total_amount) || 0,
          currency: 'EUR', // NOTE: Currency from fiscal profile pending - using EUR as default
        },
        quality: {
          avgConfidence: parseFloat(stats.avg_confidence) || 0,
        },
        issues: issuesResult.rows.map(doc => ({
          id: doc.id,
          vendor: doc.vendor,
          total: doc.total,
          date: doc.invoice_date,
          status: doc.validation_status,
          openFlags: parseInt(doc.open_flags) || 0,
        })),
        flags: flagsResult.rows.map(flag => ({
          code: flag.flag_code,
          severity: flag.severity,
          count: parseInt(flag.count),
        })),
      });
    } catch (error) {
      fastify.log.error({ err: error.message }, 'Dashboard metrics error');
      const isDevelopment = process.env.NODE_ENV === 'development';
      return reply.code(500).send({
        error: 'Failed to get dashboard metrics',
        message: isDevelopment ? error.message : 'An error occurred. Please try again.',
      });
    }
  });
}

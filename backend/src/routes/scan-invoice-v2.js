import { processImage } from '../services/image-processor.js';
import { scanInvoice } from '../services/gemini-service.js';
import { validateDocument, autoFixDocument } from '../services/fiscal-validation.js';
import { query } from '../db/pool.js';
import crypto from 'crypto';
import { validateUpload } from '../middleware/uploadValidation.js';

/**
 * Enhanced scan invoice route with PostgreSQL storage and fiscal validation
 * POST /api/v2/scan-invoice
 */
export async function scanInvoiceV2Route(fastify) {
  fastify.post('/api/v2/scan-invoice', async (request, reply) => {
    const userId = request.user.userId;
    let imageBuffer = null;
    let locale = 'en';

    try {
      // Get user's fiscal profile (required)
      const profileResult = await query(
        `SELECT * FROM fiscal_profiles WHERE user_id = $1`,
        [userId]
      );

      if (profileResult.rows.length === 0) {
        return reply.code(400).send({
          error: 'Fiscal profile required',
          message: 'Please complete your fiscal profile setup before scanning documents.',
        });
      }

      const fiscalProfile = profileResult.rows[0];

      // Parse multipart form
      for await (const part of request.parts()) {
        if (part.type === 'file') {
          const chunks = [];
          for await (const chunk of part.file) {
            chunks.push(chunk);
          }
          imageBuffer = Buffer.concat(chunks);
        } else if (part.type === 'field' && part.fieldname === 'locale') {
          locale = String(part.value).substring(0, 10);
        }
      }

      if (!imageBuffer) {
        return reply.code(400).send({
          error: 'No image provided',
        });
      }

      // Validate upload
      const uploadValidation = validateUpload(imageBuffer, null, fastify.log);
      if (!uploadValidation.valid) {
        return reply.code(uploadValidation.statusCode).send({
          error: uploadValidation.error,
        });
      }

      // Process image
      const processedImage = await processImage(imageBuffer);

      // Calculate file hash for deduplication
      const fileHash = crypto.createHash('sha256').update(imageBuffer).digest('hex');

      // Check for duplicate
      const duplicateResult = await query(
        `SELECT * FROM documents WHERE file_hash = $1 AND user_id = $2`,
        [fileHash, userId]
      );

      if (duplicateResult.rows.length > 0) {
        const existing = duplicateResult.rows[0];
        return reply.send({
          data: {
            id: existing.id,
            total: existing.total,
            tax: existing.tax,
            vendor: existing.vendor,
            date: existing.invoice_date,
            currency: existing.currency,
            category: existing.category,
            tax_id: null, // Will be populated from validation
          },
          validation: {
            status: existing.validation_status,
            errors: existing.validation_errors,
            warnings: existing.semantic_warnings,
          },
          duplicate: true,
        });
      }

      // Scan with contextual AI
      const scanResult = await scanInvoice(processedImage, locale, fiscalProfile);
      const extractedData = scanResult.data;

      // Validate document
      const validation = await validateDocument(extractedData, fiscalProfile);

      // NOTE: File upload to S3/R2 is pending implementation
      // Currently using placeholder URL - implement when cloud storage is configured
      const fileUrl = `s3://auditready-docs/${userId}/${Date.now()}.jpg`;

      // Save document to database
      const docResult = await query(
        `INSERT INTO documents (
          user_id, fiscal_profile_id, total, tax, vendor, invoice_date,
          currency, category, validation_status, validation_errors,
          semantic_warnings, file_url, file_hash, mime_type, confidence
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
        RETURNING *`,
        [
          userId,
          fiscalProfile.id,
          extractedData.total || null,
          extractedData.tax || null,
          extractedData.vendor || null,
          extractedData.date ? new Date(extractedData.date) : null,
          extractedData.currency || 'EUR',
          extractedData.category || 'other',
          validation.valid ? 'valid' : 'invalid',
          JSON.stringify(validation.errors.map(e => e.code)),
          JSON.stringify(validation.warnings.map(w => w.code)),
          fileUrl,
          fileHash,
          uploadValidation.detectedMime || 'image/jpeg',
          extractedData.confidence || 0.8,
        ]
      );

      const document = docResult.rows[0];

      // Save validation flags
      for (const flag of validation.validationFlags) {
        await query(
          `INSERT INTO validation_flags (
            document_id, flag_type, flag_code, severity, message, auto_fixable
          ) VALUES ($1, $2, $3, $4, $5, $6)`,
          [
            document.id,
            flag.flag_type,
            flag.flag_code,
            flag.severity,
            flag.message,
            flag.auto_fixable,
          ]
        );
      }

      return reply.send({
        data: {
          id: document.id,
          total: document.total,
          tax: document.tax,
          vendor: document.vendor,
          date: document.invoice_date,
          currency: document.currency,
          category: document.category,
          tax_id: extractedData.tax_id || null,
        },
        validation: {
          status: document.validation_status,
          errors: validation.errors,
          warnings: validation.warnings,
          flags: validation.validationFlags,
        },
      });
    } catch (error) {
      fastify.log.error({ err: error.message }, 'Scan invoice error');
      const isDevelopment = process.env.NODE_ENV === 'development';
      return reply.code(500).send({
        error: 'Scan failed',
        message: isDevelopment ? error.message : 'An unexpected error occurred. Please try again.',
      });
    }
  });
}

/**
 * Auto-fix document validation error
 * POST /api/v2/documents/:id/fix
 */
export async function autoFixRoute(fastify) {
  fastify.post('/api/v2/documents/:id/fix', async (request, reply) => {
    const userId = request.user.userId;
    const documentId = request.params.id;
    const { flagCode } = request.body;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(documentId)) {
      return reply.code(400).send({
        error: 'Invalid document ID format',
      });
    }

    if (!flagCode || typeof flagCode !== 'string') {
      return reply.code(400).send({
        error: 'Missing or invalid flagCode',
      });
    }

    try {
      // Verify document belongs to user and get fiscal profile
      const docResult = await query(
        `SELECT d.*, 
         fp.id as fp_id, fp.country_code as fp_country_code, 
         fp.tax_id as fp_tax_id, fp.tax_regime as fp_tax_regime
         FROM documents d
         JOIN fiscal_profiles fp ON d.fiscal_profile_id = fp.id
         WHERE d.id = $1 AND d.user_id = $2`,
        [documentId, userId]
      );

      if (docResult.rows.length === 0) {
        return reply.code(404).send({
          error: 'Document not found',
        });
      }

      const document = docResult.rows[0];
      // Get fiscal profile from the JOIN result
      const fiscalProfile = {
        id: document.fp_id,
        country_code: document.fp_country_code,
        tax_id: document.fp_tax_id,
        tax_regime: document.fp_tax_regime,
      };

      // Auto-fix
      const fixed = await autoFixDocument(documentId, flagCode, fiscalProfile);

      return reply.send({
        data: fixed,
        fixed: true,
      });
    } catch (error) {
      fastify.log.error({ err: error.message }, 'Auto-fix error');
      const isDevelopment = process.env.NODE_ENV === 'development';
      return reply.code(500).send({
        error: 'Auto-fix failed',
        message: isDevelopment ? error.message : 'An unexpected error occurred. Please try again.',
      });
    }
  });
}

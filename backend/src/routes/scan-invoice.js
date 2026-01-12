import { processImage } from '../services/image-processor.js';
import { scanInvoice } from '../services/gemini-service.js';
import { canScan, consumeQuota, getQuotaInfo } from '../services/quota-service.js';
import { getUserPlan } from '../services/user-service.js';
import { validateUpload } from '../middleware/uploadValidation.js';
import { scanRateLimitMiddleware, releaseScanSlot } from '../middleware/rateLimit.js';

export async function scanInvoiceRoute(fastify) {
  // Add scan-specific rate limiting
  fastify.addHook('preHandler', scanRateLimitMiddleware);

  fastify.post('/api/scan-invoice', async (request, reply) => {
    const installId = request.installId;
    // Get client IP for anti-abuse tracking (incognito prevention)
    const clientIp = request.headers['x-forwarded-for']?.split(',')[0]?.trim() || 
                     request.headers['x-real-ip'] || 
                     request.ip;
    let scanSlotAcquired = false;

    try {
      fastify.log.info('=== SCAN-INVOICE START ===');
      fastify.log.info({ 
        installId: installId?.substring(0, 8) + '...',
        ip: clientIp?.substring(0, 10) + '...',
      }, 'stage: auth');

      // Get user plan
      const isPremium = await getUserPlan(installId);
      fastify.log.info({ isPremium }, 'stage: getUserPlan done');

      // Check quota BEFORE processing (critical for cost control)
      // Also checks IP-based limits for free users (prevents incognito abuse)
      const quotaCheck = await canScan(installId, isPremium, clientIp);
      fastify.log.info({ 
        allowed: quotaCheck.allowed, 
        scansLeft: quotaCheck.scansLeft,
        period: quotaCheck.period,
      }, 'stage: quota check done');

      if (!quotaCheck.allowed) {
        const message = isPremium
          ? `Monthly limit reached (${quotaCheck.limit} scans). Resets in ${quotaCheck.daysUntilReset} days.`
          : 'Daily limit reached. Upgrade for more scans.';
        
        return reply.code(429).send({
          error: 'Quota exceeded',
          message,
          quota: {
            scansLeft: 0,
            scansUsed: quotaCheck.scansUsed,
            limit: quotaCheck.limit,
            period: quotaCheck.period,
            daysUntilReset: quotaCheck.daysUntilReset,
            isPremium,
            limitReached: true,
          },
        });
      }

      scanSlotAcquired = true;

      // Parse multipart form
      let imageBuffer = null;
      let locale = 'en';
      let declaredMimeType = null;

      try {
        fastify.log.info('stage: multipart parse start');
        for await (const part of request.parts()) {
          if (part.type === 'file') {
            declaredMimeType = part.mimetype;
            const chunks = [];
            for await (const chunk of part.file) {
              chunks.push(chunk);
            }
            imageBuffer = Buffer.concat(chunks);
            fastify.log.info({ 
              imageSize: imageBuffer.length,
              mimeType: declaredMimeType,
            }, 'stage: file received');
          } else if (part.type === 'field' && part.fieldname === 'locale') {
            locale = String(part.value).substring(0, 10); // Sanitize locale
          }
        }
        fastify.log.info({ locale, hasImage: !!imageBuffer }, 'stage: multipart parse done');
      } catch (parseError) {
        fastify.log.error({ err: parseError.message }, 'FAILED: multipart parse');
        return reply.code(400).send({
          error: 'Invalid request format',
          message: 'Failed to parse image data. Please ensure you are sending a valid image file.',
        });
      }

      // Validate upload (size, MIME, magic bytes)
      const uploadValidation = validateUpload(imageBuffer, declaredMimeType, fastify.log);
      if (!uploadValidation.valid) {
        fastify.log.warn({ 
          error: uploadValidation.error,
          size: uploadValidation.size,
          declaredMime: uploadValidation.declaredMime,
          detectedMime: uploadValidation.detectedMime,
          statusCode: uploadValidation.statusCode,
        }, 'FAILED: upload validation');
        
        const responseBody = {
          error: uploadValidation.statusCode === 415 ? 'Unsupported media type' : 'Invalid file',
          message: uploadValidation.error,
        };
        
        // Include supported types for 415 errors
        if (uploadValidation.supportedTypes) {
          responseBody.supportedTypes = uploadValidation.supportedTypes;
          responseBody.receivedType = uploadValidation.detectedMime || uploadValidation.declaredMime;
        }
        
        return reply.code(uploadValidation.statusCode).send(responseBody);
      }

      fastify.log.info({ 
        detectedMime: uploadValidation.detectedMime,
        size: uploadValidation.size,
      }, 'stage: upload validation passed');

      // Process image with Sharp
      let processedImage;
      try {
        fastify.log.info('stage: sharp start');
        processedImage = await processImage(imageBuffer);
        fastify.log.info({ processedSize: processedImage.length }, 'stage: sharp done');
      } catch (sharpError) {
        fastify.log.error({ err: sharpError.message }, 'FAILED: sharp');
        return reply.code(400).send({ error: 'Invalid image format' });
      }

      // Scan invoice with Gemini
      let result;
      try {
        fastify.log.info('stage: gemini start');
        result = await scanInvoice(processedImage, locale);
        fastify.log.info('stage: gemini done');
      } catch (geminiError) {
        fastify.log.error({ err: geminiError.message }, 'FAILED: gemini');
        // Don't consume quota on Gemini failure
        return reply.code(502).send({
          error: 'AI processing failed',
          message: 'Unable to process image. Please try again.',
        });
      }

      // Consume quota AFTER successful processing
      // Also tracks IP usage for free users (anti-incognito abuse)
      try {
        fastify.log.info('stage: consumeQuota start');
        await consumeQuota(installId, isPremium, clientIp);
        fastify.log.info('stage: consumeQuota done');
      } catch (quotaError) {
        // Log but don't fail - the user already got their result
        fastify.log.error({ err: quotaError.message }, 'FAILED: consumeQuota (continuing anyway)');
      }

      // Get updated quota info
      let updatedQuota;
      try {
        updatedQuota = await getQuotaInfo(installId, isPremium);
      } catch (quotaError) {
        fastify.log.error({ err: quotaError.message }, 'FAILED: getQuotaInfo update');
        updatedQuota = {
          scansLeft: quotaCheck.scansLeft - 1,
          isPremium,
        };
      }

      fastify.log.info('=== SCAN-INVOICE SUCCESS ===');
      return reply.send({
        data: result.data,
        quota: {
          scansLeft: updatedQuota.scansLeft,
          scansUsed: updatedQuota.scansUsed,
          limit: updatedQuota.limit,
          period: updatedQuota.period,
          isPremium,
        },
      });

    } catch (error) {
      // Sanitize error message (don't leak internal details)
      fastify.log.error({ 
        err: error.message,
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
      }, 'UNEXPECTED ERROR in scan-invoice');
      
      return reply.code(500).send({
        error: 'Internal server error',
        message: 'An unexpected error occurred. Please try again.',
      });
    } finally {
      // Always release scan slot
      if (scanSlotAcquired) {
        await releaseScanSlot(installId);
      }
    }
  });
}

import { processImage } from '../services/image-processor.js';
import { scanInvoice } from '../services/gemini-service.js';
import { consumeQuota, getScansLeft } from '../services/quota-service.js';
import { getUserPlan } from '../services/user-service.js';

export async function scanInvoiceRoute(fastify) {
  fastify.post('/api/scan-invoice', async (request, reply) => {
    try {
      fastify.log.info('=== SCAN-INVOICE START ===');
      
      const installId = request.installId;
      fastify.log.info({ installId, hasGeminiKey: !!process.env.GEMINI_API_KEY }, 'stage: auth');
      
      const isPremium = await getUserPlan(installId);
      fastify.log.info({ isPremium }, 'stage: getUserPlan done');

      // Check quota before processing
      const scansLeft = await getScansLeft(installId, isPremium);
      fastify.log.info({ scansLeft }, 'stage: getScansLeft done');
      
      if (scansLeft <= 0 && !isPremium) {
        return reply.code(429).send({
          error: 'Quota exceeded',
          message: 'Daily limit reached. Upgrade for unlimited scans.',
          quota: { scansLeft: 0, isPremium: false },
        });
      }

      // Parse multipart form
      let imageBuffer = null;
      let locale = 'en';

      try {
        fastify.log.info('stage: multipart parse start');
        for await (const part of request.parts()) {
          if (part.type === 'file') {
            const chunks = [];
            for await (const chunk of part.file) {
              chunks.push(chunk);
            }
            imageBuffer = Buffer.concat(chunks);
            fastify.log.info({ imageSize: imageBuffer.length }, 'stage: file received');
          } else if (part.type === 'field' && part.fieldname === 'locale') {
            locale = part.value.toString('utf-8');
          }
        }
        fastify.log.info({ locale, hasImage: !!imageBuffer }, 'stage: multipart parse done');
      } catch (parseError) {
        fastify.log.error({ err: parseError }, 'FAILED: multipart parse');
        return reply.code(400).send({ 
          error: 'Invalid request format', 
          message: 'Failed to parse image data. Please ensure you are sending a valid image file.' 
        });
      }

      if (!imageBuffer || imageBuffer.length === 0) {
        fastify.log.warn('FAILED: No image provided');
        return reply.code(400).send({ error: 'No image provided' });
      }

      // Process image with Sharp
      let processedImage;
      try {
        fastify.log.info('stage: sharp start');
        processedImage = await processImage(imageBuffer);
        fastify.log.info({ processedSize: processedImage.length }, 'stage: sharp done');
      } catch (sharpError) {
        fastify.log.error({ err: sharpError }, 'FAILED: sharp');
        return reply.code(400).send({ error: 'Invalid image format' });
      }
      
      // Consume quota
      if (!isPremium) {
        try {
          fastify.log.info('stage: consumeQuota start');
          await consumeQuota(installId);
          fastify.log.info('stage: consumeQuota done');
        } catch (quotaError) {
          fastify.log.error({ err: quotaError }, 'FAILED: consumeQuota (continuing anyway)');
          // Continue anyway - don't block user if quota tracking fails
        }
      }

      // Scan invoice with Gemini
      let result;
      try {
        fastify.log.info('stage: gemini start');
        result = await scanInvoice(processedImage, locale);
        fastify.log.info('stage: gemini done');
      } catch (geminiError) {
        fastify.log.error({ err: geminiError, message: geminiError.message }, 'FAILED: gemini');
        return reply.code(502).send({ 
          error: 'AI processing failed', 
          message: geminiError.message 
        });
      }
      
      // Get updated quota
      let updatedScansLeft = scansLeft - 1;
      try {
        fastify.log.info('stage: getScansLeft update start');
        updatedScansLeft = await getScansLeft(installId, isPremium);
        fastify.log.info({ updatedScansLeft }, 'stage: getScansLeft update done');
      } catch (quotaError) {
        fastify.log.error({ err: quotaError }, 'FAILED: getScansLeft update (using estimate)');
      }

      fastify.log.info('=== SCAN-INVOICE SUCCESS ===');
      return reply.send({
        data: result.data,
        quota: {
          scansLeft: updatedScansLeft,
          isPremium,
        },
      });

    } catch (error) {
      fastify.log.error({ err: error, message: error.message, stack: error.stack }, 'UNEXPECTED ERROR in scan-invoice');
      return reply.code(500).send({ 
        error: 'Internal server error', 
        message: error.message 
      });
    }
  });
}


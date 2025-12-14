import { processImage } from '../services/image-processor.js';
import { scanInvoice } from '../services/gemini-service.js';
import { consumeQuota, getScansLeft } from '../services/quota-service.js';
import { getUserPlan } from '../services/user-service.js';

export async function scanInvoiceRoute(fastify) {
  fastify.post('/api/scan-invoice', async (request, reply) => {
    try {
      const installId = request.installId;
      const isPremium = await getUserPlan(installId);

      // Check quota before processing
      const scansLeft = await getScansLeft(installId, isPremium);
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
        for await (const part of request.parts()) {
          if (part.type === 'file') {
            const chunks = [];
            for await (const chunk of part.file) {
              chunks.push(chunk);
            }
            imageBuffer = Buffer.concat(chunks);
          } else if (part.type === 'field' && part.fieldname === 'locale') {
            // For text fields, use part.value directly
            locale = part.value.toString('utf-8');
          }
        }
      } catch (parseError) {
        fastify.log.error({ err: parseError }, 'Error parsing multipart form');
        return reply.code(400).send({ 
          error: 'Invalid request format', 
          message: 'Failed to parse image data. Please ensure you are sending a valid image file.' 
        });
      }

      if (!imageBuffer || imageBuffer.length === 0) {
        return reply.code(400).send({ error: 'No image provided' });
      }

      // Validate and process image
      try {
        const processedImage = await processImage(imageBuffer);
        
        // Consume quota
        if (!isPremium) {
          await consumeQuota(installId);
        }

        // Scan invoice
        const result = await scanInvoice(processedImage, locale);
        
        // Get updated quota
        const updatedScansLeft = await getScansLeft(installId, isPremium);

        return reply.send({
          data: result.data,
          quota: {
            scansLeft: updatedScansLeft,
            isPremium,
          },
        });
      } catch (processingError) {
        fastify.log.error({ err: processingError }, 'Error processing invoice scan');
        
        if (processingError.message.includes('too large')) {
          return reply.code(400).send({ error: 'File too large' });
        }
        
        return reply.code(500).send({ 
          error: 'Processing failed', 
          message: processingError.message 
        });
      }
    } catch (error) {
      fastify.log.error({ err: error }, 'Unexpected error in scan-invoice route');
      return reply.code(500).send({ 
        error: 'Internal server error', 
        message: error.message 
      });
    }
  });
}


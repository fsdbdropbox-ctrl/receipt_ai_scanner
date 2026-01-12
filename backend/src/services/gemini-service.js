import { model } from '../config/gemini.js';
import { parseJSON } from '../utils/parser.js';
import redis from '../config/redis.js';
import crypto from 'crypto';
import { generateContextualPrompt } from './fiscal-rules.js';

// #region Constants
const PROMPTS = {
  en: `Extract invoice/receipt data from this image. Return ONLY valid JSON with this structure:
{
  "total": number or null,
  "tax": number or null,
  "base": number or null,
  "vendor": string or null,
  "date": "YYYY-MM-DD" or null,
  "currency": "USD" or null,
  "category": "food" | "travel" | "office" | "utilities" | "healthcare" | "retail" | "other" or null,
  "tax_id": string or null,
  "tax_rate": number or null
}`,
  es: `Extrae datos de factura/recibo de esta imagen. Devuelve SOLO JSON válido con esta estructura:
{
  "total": número o null,
  "tax": número o null,
  "base": número o null,
  "vendor": string o null,
  "date": "YYYY-MM-DD" o null,
  "currency": "USD" o null,
  "category": "food" | "travel" | "office" | "utilities" | "healthcare" | "retail" | "other" o null,
  "tax_id": string o null,
  "tax_rate": number o null
}`,
};

// #region Cache Configuration
const CACHE_TTL = 86400; // 24 hours
const REDIS_PREFIX = 'gemini:scan:';

// #region Helpers
function getPromptForLocale(locale, fiscalProfile = null) {
  // If fiscal profile exists, use contextual prompt
  if (fiscalProfile) {
    return generateContextualPrompt(fiscalProfile);
  }
  
  // Fallback to locale-based prompt
  const lang = locale?.substring(0, 2) || 'en';
  return PROMPTS[lang] || PROMPTS.en;
}

function getCacheKey(imageBuffer) {
  const hash = crypto.createHash('sha256').update(imageBuffer).digest('hex');
  return `${REDIS_PREFIX}${hash}`;
}

// #region Cache Operations
async function getCachedResult(cacheKey) {
  try {
    const cached = await redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }
  } catch (error) {
    // Cache errors are non-critical, log silently
    // console.error('Cache read error:', error.message);
  }
  return null;
}

async function setCachedResult(cacheKey, result) {
  try {
    await redis.setex(cacheKey, CACHE_TTL, JSON.stringify(result));
  } catch (error) {
    // Cache errors are non-critical, log silently
    // console.error('Cache write error:', error.message);
  }
}

// #region Public API
/**
 * Scan invoice with contextual AI based on fiscal profile
 * @param {Buffer} imageBuffer - Processed image buffer
 * @param {string} locale - User locale
 * @param {object|null} fiscalProfile - User's fiscal profile for contextual validation
 * @returns {Promise<object>} Extracted invoice data
 */
export async function scanInvoice(imageBuffer, locale, fiscalProfile = null) {
  const cacheKey = getCacheKey(imageBuffer);

  // Try cache first
  const cached = await getCachedResult(cacheKey);
  if (cached) {
    return cached;
  }

  // Cache miss - call Gemini API
  try {
    const prompt = getPromptForLocale(locale, fiscalProfile);

    const result = await model.generateContent([
      {
        inlineData: {
          data: imageBuffer.toString('base64'),
          mimeType: 'image/jpeg',
        },
      },
      { text: prompt },
    ]);

    const responseText = result.response.text();
    const json = parseJSON(responseText);

    const response = {
      data: json,
      rawResponse: responseText,
    };

    // Cache the result
    await setCachedResult(cacheKey, response);

    return response;
  } catch (error) {
    throw new Error(`Gemini processing failed: ${error.message}`);
  }
}
// #endregion

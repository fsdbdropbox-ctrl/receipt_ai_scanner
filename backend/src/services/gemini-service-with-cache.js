import { model } from '../config/gemini.js';
import { parseJSON } from '../utils/parser.js';
import redis from '../config/redis.js';
import crypto from 'crypto';

const PROMPTS = {
  en: `Extract invoice/receipt data from this image. Return ONLY valid JSON with this structure:
{
  "total": number or null,
  "tax": number or null,
  "vendor": string or null,
  "date": "YYYY-MM-DD" or null,
  "currency": "USD" or null,
  "category": "food" | "travel" | "office" | "utilities" | "healthcare" | "retail" | "other" or null
}`,
  es: `Extrae datos de factura/recibo de esta imagen. Devuelve SOLO JSON válido con esta estructura:
{
  "total": número o null,
  "tax": número o null,
  "vendor": string o null,
  "date": "YYYY-MM-DD" o null,
  "currency": "USD" o null,
  "category": "food" | "travel" | "office" | "utilities" | "healthcare" | "retail" | "other" o null
}`,
  de: `Extrahiere Rechnungs-/Belegdaten aus diesem Bild. Gib NUR gültiges JSON mit dieser Struktur zurück:
{
  "total": Zahl oder null,
  "tax": Zahl oder null,
  "vendor": String oder null,
  "date": "YYYY-MM-DD" oder null,
  "currency": "USD" oder null,
  "category": "food" | "travel" | "office" | "utilities" | "healthcare" | "retail" | "other" oder null
}`,
  fr: `Extrayez les données de facture/reçu de cette image. Renvoyez UNIQUEMENT du JSON valide avec cette structure:
{
  "total": nombre ou null,
  "tax": nombre ou null,
  "vendor": string ou null,
  "date": "YYYY-MM-DD" ou null,
  "currency": "USD" ou null,
  "category": "food" | "travel" | "office" | "utilities" | "healthcare" | "retail" | "other" ou null
}`,
  it: `Estrai i dati della fattura/scontrino da questa immagine. Restituisci SOLO JSON valido con questa struttura:
{
  "total": numero o null,
  "tax": numero o null,
  "vendor": string o null,
  "date": "YYYY-MM-DD" o null,
  "currency": "USD" o null,
  "category": "food" | "travel" | "office" | "utilities" | "healthcare" | "retail" | "other" o null
}`,
};

const CACHE_TTL = 86400; // 24 hours
const CACHE_ENABLED = process.env.ENABLE_GEMINI_CACHE !== 'false';

function getPromptForLocale(locale) {
  const lang = String(locale).split('_')[0]?.toLowerCase() || 'en';
  return PROMPTS[lang] || PROMPTS.en;
}

/**
 * Generate cache key from image buffer
 */
function getCacheKey(imageBuffer) {
  const hash = crypto.createHash('sha256').update(imageBuffer).digest('hex');
  return `gemini:cache:${hash}`;
}

/**
 * Get cached result from Redis
 */
async function getCachedResult(cacheKey) {
  if (!CACHE_ENABLED) return null;
  
  try {
    const cached = await redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }
  } catch (error) {
    // Cache miss or error - continue with API call
    console.warn('Cache read error:', error.message);
  }
  return null;
}

/**
 * Store result in cache
 */
async function setCachedResult(cacheKey, result) {
  if (!CACHE_ENABLED) return;
  
  try {
    await redis.setex(cacheKey, CACHE_TTL, JSON.stringify(result));
  } catch (error) {
    // Cache write error - non-fatal, continue
    console.warn('Cache write error:', error.message);
  }
}

/**
 * Scan invoice with caching support
 */
export async function scanInvoice(imageBuffer, locale) {
  const cacheKey = getCacheKey(imageBuffer);
  
  // Try cache first
  const cached = await getCachedResult(cacheKey);
  if (cached) {
    return cached;
  }
  
  // Cache miss - call Gemini API
  try {
    const prompt = getPromptForLocale(locale);
    
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


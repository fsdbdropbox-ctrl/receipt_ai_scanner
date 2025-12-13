import { model } from '../config/gemini.js';
import { parseJSON } from '../utils/parser.js';

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

function getPromptForLocale(locale) {
  const lang = String(locale).split('_')[0]?.toLowerCase() || 'en';
  return PROMPTS[lang] || PROMPTS.en;
}

export async function scanInvoice(imageBuffer, locale) {
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

    return {
      data: json,
      rawResponse: responseText,
    };
  } catch (error) {
    throw new Error(`Gemini processing failed: ${error.message}`);
  }
}


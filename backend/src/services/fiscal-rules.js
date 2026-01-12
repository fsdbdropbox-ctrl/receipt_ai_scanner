// Fiscal validation rules by country
// These rules are injected into AI prompts for contextual validation

export const FISCAL_RULES = {
  ES: {
    // Spain (España)
    countryName: 'España',
    taxAuthority: 'Agencia Tributaria',
    taxIdLabel: 'NIF/CIF',
    taxIdFormat: '8 dígitos + letra (NIF) o letra + 8 dígitos (CIF)',
    dateFormat: 'DD/MM/YYYY',
    currency: 'EUR',
    requiredFields: ['tax_id', 'vendor', 'date', 'total', 'tax_rate'],
    taxLabels: ['IVA', 'IGIC', 'IPS'],
    taxRates: [0.04, 0.10, 0.21], // 4%, 10%, 21%
    validationRules: {
      nifFormat: /^[A-Z]?\d{8}[A-Z]$/,
      minAmountForFullInvoice: 400, // EUR - requires full invoice, not ticket
      dateRange: {
        maxDaysPast: 365, // Documents older than 1 year are suspicious
        maxDaysFuture: 0, // No future dates allowed
      },
    },
    errorCodes: {
      'ES-01': 'Importe > 400€ requiere Factura Completa (no Ticket)',
      'ES-02': 'NIF Receptor debe coincidir con el NIF del usuario',
      'ES-03': 'Falta NIF Receptor (obligatorio para deducción)',
      'ES-21': 'Falta tu NIF en la factura recibida',
      'ES-22': 'Error matemático: Base + IVA ≠ Total',
      'ES-23': 'Fecha inválida o fuera de rango permitido',
    },
  },
  MX: {
    // Mexico
    countryName: 'México',
    taxAuthority: 'SAT',
    taxIdLabel: 'RFC',
    taxIdFormat: '12-13 caracteres alfanuméricos',
    dateFormat: 'DD/MM/YYYY',
    currency: 'MXN',
    requiredFields: ['tax_id', 'vendor', 'date', 'total', 'tax_rate'],
    taxLabels: ['IVA'],
    taxRates: [0.00, 0.08, 0.16], // 0%, 8%, 16%
    validationRules: {
      rfcFormat: /^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$/,
      minAmountForFullInvoice: 2000, // MXN
      dateRange: {
        maxDaysPast: 365,
        maxDaysFuture: 0,
      },
    },
    errorCodes: {
      'MX-01': 'Importe > $2,000 MXN requiere Factura con RFC',
      'MX-02': 'RFC Receptor debe coincidir con el RFC del usuario',
      'MX-21': 'Falta tu RFC en la factura recibida',
    },
  },
  DE: {
    // Germany
    countryName: 'Deutschland',
    taxAuthority: 'Finanzamt',
    taxIdLabel: 'USt-IdNr / VAT ID',
    taxIdFormat: 'DE + 9 dígitos',
    dateFormat: 'DD.MM.YYYY',
    currency: 'EUR',
    requiredFields: ['tax_id', 'vendor', 'date', 'total', 'tax_rate'],
    taxLabels: ['MwSt', 'USt'],
    taxRates: [0.00, 0.07, 0.19], // 0%, 7%, 19%
    validationRules: {
      vatFormat: /^DE\d{9}$/,
      minAmountForFullInvoice: 250, // EUR
      dateRange: {
        maxDaysPast: 365,
        maxDaysFuture: 0,
      },
    },
    errorCodes: {
      'DE-01': 'Betrag > 250€ erfordert vollständige Rechnung',
      'DE-21': 'Fehlende USt-IdNr in der erhaltenen Rechnung',
    },
  },
};

/**
 * Get fiscal rules for a country code
 * @param {string} countryCode - ISO 3166-1 alpha-2 country code
 * @returns {object|null} Fiscal rules object or null if not found
 */
export function getFiscalRules(countryCode) {
  return FISCAL_RULES[countryCode?.toUpperCase()] || null;
}

/**
 * Generate contextual prompt for AI based on fiscal profile
 * @param {object} fiscalProfile - User's fiscal profile
 * @returns {string} Contextual prompt string
 */
export function generateContextualPrompt(fiscalProfile) {
  const rules = getFiscalRules(fiscalProfile.country_code);
  if (!rules) {
    return 'Extract invoice data from the image.';
  }

  return `
Extract invoice data from the image. The user is located in ${rules.countryName} (${fiscalProfile.country_code}).

IMPORTANT CONTEXT:
- Tax Authority: ${rules.taxAuthority}
- User's Tax ID: ${fiscalProfile.tax_id} (${rules.taxIdLabel})
- Tax Regime: ${fiscalProfile.tax_regime}
- Currency: ${rules.currency}
- Date Format: ${rules.dateFormat}

VALIDATION RULES:
${Object.entries(rules.errorCodes).map(([code, msg]) => `- ${code}: ${msg}`).join('\n')}

REQUIRED FIELDS:
${rules.requiredFields.join(', ')}

Extract all fields and validate against these rules. If the user's Tax ID (${fiscalProfile.tax_id}) is missing from the invoice, mark it as an error (code: ${Object.keys(rules.errorCodes)[0]}).
`.trim();
}

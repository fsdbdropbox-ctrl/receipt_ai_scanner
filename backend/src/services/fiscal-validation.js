import { getFiscalRules } from './fiscal-rules.js';
import { query } from '../db/pool.js';

/**
 * Validate a document against fiscal rules
 * @param {object} document - Document data
 * @param {object} fiscalProfile - User's fiscal profile
 * @returns {object} Validation result with errors and warnings
 */
export async function validateDocument(document, fiscalProfile) {
  const rules = getFiscalRules(fiscalProfile.country_code);
  if (!rules) {
    return {
      valid: true,
      errors: [],
      warnings: [],
    };
  }

  const errors = [];
  const warnings = [];
  const validationFlags = [];

  // Rule ES-01 / MX-01 / DE-01: Amount threshold for full invoice
  if (document.total && document.total > rules.validationRules.minAmountForFullInvoice) {
    // Check if it's a full invoice (has tax_id, vendor, etc.)
    if (!document.tax_id || !document.vendor) {
      const errorCode = Object.keys(rules.errorCodes)[0];
      errors.push({
        code: errorCode,
        message: rules.errorCodes[errorCode],
        severity: 'error',
        autoFixable: false,
      });
      validationFlags.push({
        flag_type: 'amount_threshold',
        flag_code: errorCode,
        severity: 'error',
        message: rules.errorCodes[errorCode],
        auto_fixable: false,
      });
    }
  }

  // Rule ES-02 / MX-02: Tax ID must match user's tax ID
  if (document.tax_id && document.tax_id !== fiscalProfile.tax_id) {
    const errorCode = Object.keys(rules.errorCodes)[1] || 'TAX_ID_MISMATCH';
    errors.push({
      code: errorCode,
      message: rules.errorCodes[errorCode] || 'Tax ID mismatch',
      severity: 'error',
      autoFixable: true, // Can auto-fix by replacing with user's tax ID
    });
    validationFlags.push({
      flag_type: 'tax_id_mismatch',
      flag_code: errorCode,
      severity: 'error',
      message: rules.errorCodes[errorCode] || 'Tax ID mismatch',
      auto_fixable: true,
    });
  }

  // Rule ES-21 / MX-21 / DE-21: Missing user's tax ID
  if (!document.tax_id || document.tax_id.trim() === '') {
    const errorCode = Object.keys(rules.errorCodes).find(
      (code) => code.includes('21') || code.includes('NIF') || code.includes('RFC')
    ) || 'MISSING_TAX_ID';
    errors.push({
      code: errorCode,
      message: rules.errorCodes[errorCode] || 'Missing tax ID',
      severity: 'error',
      autoFixable: true, // Can auto-fix by adding user's tax ID
    });
    validationFlags.push({
      flag_type: 'missing_nif',
      flag_code: errorCode,
      severity: 'error',
      message: rules.errorCodes[errorCode] || 'Missing tax ID',
      auto_fixable: true,
    });
  }

  // Rule ES-22: Math validation (Base + Tax = Total)
  if (document.total && document.tax && document.base) {
    const calculatedTotal = document.base + document.tax;
    const tolerance = 0.01; // Allow 1 cent difference
    if (Math.abs(calculatedTotal - document.total) > tolerance) {
      const errorCode = Object.keys(rules.errorCodes).find(
        (code) => code.includes('22') || code.includes('math')
      ) || 'MATH_ERROR';
      errors.push({
        code: errorCode,
        message: rules.errorCodes[errorCode] || 'Mathematical error: Base + Tax ≠ Total',
        severity: 'error',
        autoFixable: false,
      });
      validationFlags.push({
        flag_type: 'math_error',
        flag_code: errorCode,
        severity: 'error',
        message: rules.errorCodes[errorCode] || 'Mathematical error',
        auto_fixable: false,
      });
    }
  }

  // Rule ES-23: Date validation
  if (document.invoice_date) {
    const invoiceDate = new Date(document.invoice_date);
    const now = new Date();
    const daysDiff = Math.floor((now - invoiceDate) / (1000 * 60 * 60 * 24));
    
    if (daysDiff > rules.validationRules.dateRange.maxDaysPast) {
      warnings.push({
        code: 'DATE_TOO_OLD',
        message: 'Document date is more than 1 year old',
        severity: 'warning',
      });
    }
    
    if (daysDiff < -rules.validationRules.dateRange.maxDaysFuture) {
      errors.push({
        code: 'DATE_FUTURE',
        message: 'Document date is in the future',
        severity: 'error',
        autoFixable: false,
      });
    }
  }

  const valid = errors.length === 0;

  return {
    valid,
    errors,
    warnings,
    validationFlags,
  };
}

/**
 * Auto-fix a document validation error
 * @param {string} documentId - Document ID
 * @param {string} flagCode - Validation flag code to fix
 * @param {object} fiscalProfile - User's fiscal profile
 * @returns {object} Updated document
 */
export async function autoFixDocument(documentId, flagCode, fiscalProfile) {
  // Get the document
  const docResult = await query(
    'SELECT * FROM documents WHERE id = $1',
    [documentId]
  );

  if (docResult.rows.length === 0) {
    throw new Error('Document not found');
  }

  const document = docResult.rows[0];
  const updates = {};
  const flagsToMarkFixed = [];

  // Auto-fix: Missing NIF
  if (flagCode.includes('21') || flagCode.includes('NIF') || flagCode.includes('RFC')) {
    updates.tax_id = fiscalProfile.tax_id;
    flagsToMarkFixed.push(flagCode);
  }

  // Auto-fix: Tax ID mismatch
  if (flagCode.includes('02') || flagCode.includes('MISMATCH')) {
    updates.tax_id = fiscalProfile.tax_id;
    flagsToMarkFixed.push(flagCode);
  }

  // Update document if there are changes
  if (Object.keys(updates).length > 0) {
    const setClause = Object.keys(updates)
      .map((key, index) => `${key} = $${index + 2}`)
      .join(', ');
    
    await query(
      `UPDATE documents SET ${setClause}, updated_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [documentId, ...Object.values(updates)]
    );

    // Mark validation flags as fixed
    for (const flagCodeToFix of flagsToMarkFixed) {
      await query(
        `UPDATE validation_flags SET fixed_at = CURRENT_TIMESTAMP WHERE document_id = $1 AND flag_code = $2`,
        [documentId, flagCodeToFix]
      );
    }

    // Re-validate the document
    const updatedDoc = await query(
      'SELECT * FROM documents WHERE id = $1',
      [documentId]
    );

    const validation = await validateDocument(updatedDoc.rows[0], fiscalProfile);
    
    // Update validation status
    const newStatus = validation.errors.length === 0 ? 'valid' : 'invalid';
    await query(
      'UPDATE documents SET validation_status = $1, validation_errors = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3',
      [newStatus, JSON.stringify(validation.errors.map(e => e.code)), documentId]
    );

    return {
      ...updatedDoc.rows[0],
      ...updates,
      validation_status: newStatus,
    };
  }

  return document;
}

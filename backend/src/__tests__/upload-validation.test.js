import { test, describe, it } from 'node:test';
import assert from 'node:assert';
import { validateUpload, getUploadLimits } from '../middleware/uploadValidation.js';

// Mock logger for tests
const mockLogger = {
  info: () => {},
  warn: () => {},
  error: () => {},
};

describe('Upload Validation', () => {
  describe('validateUpload', () => {
    it('should reject empty buffer', () => {
      const result = validateUpload(null, 'image/jpeg', mockLogger);
      
      assert.strictEqual(result.valid, false);
      assert.strictEqual(result.error, 'No file provided');
      assert.strictEqual(result.statusCode, 400);
    });

    it('should reject buffer with zero length', () => {
      const result = validateUpload(Buffer.alloc(0), 'image/jpeg', mockLogger);
      
      assert.strictEqual(result.valid, false);
      assert.strictEqual(result.error, 'No file provided');
      assert.strictEqual(result.statusCode, 400);
    });

    it('should reject file exceeding size limit with 413', () => {
      // Create 11MB buffer (over 10MB limit)
      const largeBuffer = Buffer.alloc(11 * 1024 * 1024);
      const result = validateUpload(largeBuffer, 'image/jpeg', mockLogger);
      
      assert.strictEqual(result.valid, false);
      assert.ok(result.error.includes('too large'));
      assert.strictEqual(result.statusCode, 413);
    });

    it('should accept valid JPEG with correct magic bytes', () => {
      // JPEG magic bytes: FF D8 FF
      const jpegBuffer = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      const result = validateUpload(jpegBuffer, 'image/jpeg', mockLogger);
      
      assert.strictEqual(result.valid, true);
      assert.strictEqual(result.detectedMime, 'image/jpeg');
      assert.strictEqual(result.statusCode, null);
    });

    it('should accept valid PNG with correct magic bytes', () => {
      // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
      const pngBuffer = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      const result = validateUpload(pngBuffer, 'image/png', mockLogger);
      
      assert.strictEqual(result.valid, true);
      assert.strictEqual(result.detectedMime, 'image/png');
    });

    it('should reject GIF with 415 (unsupported)', () => {
      // GIF89a magic bytes
      const gifBuffer = Buffer.from([0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x00, 0x00]);
      const result = validateUpload(gifBuffer, 'image/gif', mockLogger);
      
      assert.strictEqual(result.valid, false);
      assert.strictEqual(result.statusCode, 415);
      assert.ok(result.error.includes('GIF'));
    });

    it('should reject PDF with 415 and helpful message', () => {
      // PDF magic bytes: %PDF
      const pdfBuffer = Buffer.from([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
      const result = validateUpload(pdfBuffer, 'application/pdf', mockLogger);
      
      assert.strictEqual(result.valid, false);
      assert.strictEqual(result.statusCode, 415);
      assert.ok(result.error.includes('PDF'));
      assert.ok(result.error.includes('photo') || result.error.includes('image'));
    });

    it('should reject unknown type with 415', () => {
      // Random bytes that don't match any format
      const randomBuffer = Buffer.from([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
      const result = validateUpload(randomBuffer, 'application/octet-stream', mockLogger);
      
      assert.strictEqual(result.valid, false);
      assert.strictEqual(result.statusCode, 415);
    });

    it('should detect MIME from magic bytes even with wrong declared type', () => {
      // JPEG bytes but declared as PNG
      const jpegBuffer = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      const result = validateUpload(jpegBuffer, 'image/png', mockLogger);
      
      // Should still accept because detected MIME is valid
      assert.strictEqual(result.valid, true);
      assert.strictEqual(result.detectedMime, 'image/jpeg');
    });

    it('should accept pjpeg (progressive JPEG)', () => {
      // JPEG bytes with pjpeg declared type
      const jpegBuffer = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46]);
      const result = validateUpload(jpegBuffer, 'image/pjpeg', mockLogger);
      
      // Magic bytes detect as jpeg, which is allowed
      assert.strictEqual(result.valid, true);
    });
  });

  describe('getUploadLimits', () => {
    it('should return correct limits', () => {
      const limits = getUploadLimits();
      
      assert.strictEqual(limits.maxSizeBytes, 10 * 1024 * 1024);
      assert.strictEqual(limits.maxSizeMB, 10);
      assert.ok(Array.isArray(limits.allowedTypes));
      assert.ok(limits.allowedTypes.includes('image/jpeg'));
      assert.ok(limits.allowedTypes.includes('image/png'));
      // PDF should NOT be in allowed types
      assert.ok(!limits.allowedTypes.includes('application/pdf'));
      // GIF should NOT be in allowed types
      assert.ok(!limits.allowedTypes.includes('image/gif'));
    });
  });
});

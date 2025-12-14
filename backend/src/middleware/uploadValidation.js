/**
 * Upload validation middleware
 * Validates file size, MIME type, and magic bytes
 */

// Configuration
const UPLOAD_LIMITS = {
  maxFileSizeBytes: 10 * 1024 * 1024, // 10MB
  maxFileSizeMB: 10,
  // Only image formats that Sharp/Gemini process well
  // No PDF (requires rasterization), no GIF (animations)
  allowedMimeTypes: new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    // Legacy/alternative MIME types
    'image/pjpeg',   // Progressive JPEG (IE legacy)
    'image/x-png',   // Old PNG MIME
  ]),
};

// Magic bytes for common image formats
const MAGIC_BYTES = {
  'image/jpeg': [
    [0xFF, 0xD8, 0xFF],
  ],
  'image/png': [
    [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
  ],
  'image/webp': [
    // RIFF....WEBP (bytes 0-3 = RIFF, bytes 8-11 = WEBP)
    [0x52, 0x49, 0x46, 0x46],
  ],
  // HEIC has complex structure, relax validation for it
  'image/heic': null,
  'image/heif': null,
  // Legacy types map to standard types
  'image/pjpeg': null,  // Trust declared type
  'image/x-png': null,  // Trust declared type
};

/**
 * Check if buffer starts with magic bytes
 */
function checkMagicBytes(buffer, mimeType) {
  const signatures = MAGIC_BYTES[mimeType];
  
  // If no signature defined (like HEIC), trust the MIME type
  if (!signatures) {
    return true;
  }
  
  for (const sig of signatures) {
    if (buffer.length >= sig.length) {
      let match = true;
      for (let i = 0; i < sig.length; i++) {
        if (buffer[i] !== sig[i]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
  }
  
  return false;
}

/**
 * Detect MIME type from magic bytes
 */
function detectMimeFromBytes(buffer) {
  if (buffer.length < 8) return null;
  
  // JPEG (also handles JFIF, EXIF - all start with FF D8 FF)
  if (buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF) {
    return 'image/jpeg';
  }
  
  // PNG
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47) {
    return 'image/png';
  }
  
  // WebP (RIFF....WEBP)
  if (buffer[0] === 0x52 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x46) {
    if (buffer.length >= 12 && buffer[8] === 0x57 && buffer[9] === 0x45 && buffer[10] === 0x42 && buffer[11] === 0x50) {
      return 'image/webp';
    }
  }
  
  // HEIC/HEIF (ftyp box) - check for ftyp at offset 4
  if (buffer.length >= 12) {
    if (buffer[4] === 0x66 && buffer[5] === 0x74 && buffer[6] === 0x79 && buffer[7] === 0x70) {
      // Check brand: heic, heix, hevc, hevx, mif1
      const brand = buffer.slice(8, 12).toString('ascii');
      if (['heic', 'heix', 'hevc', 'hevx', 'mif1'].includes(brand)) {
        return 'image/heic';
      }
    }
  }
  
  // PDF (%PDF) - detect for better error message, but NOT allowed
  if (buffer[0] === 0x25 && buffer[1] === 0x50 && buffer[2] === 0x44 && buffer[3] === 0x46) {
    return 'application/pdf';
  }
  
  // GIF - detect for better error message, but NOT allowed
  if (buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) {
    return 'image/gif';
  }
  
  return null;
}

/**
 * Validate uploaded image
 * @param {Buffer} buffer - Image buffer
 * @param {string} declaredMimeType - MIME type declared by client
 * @param {Object} logger - Optional logger for debugging
 * @returns {Object} - Validation result with statusCode for HTTP response
 */
export function validateUpload(buffer, declaredMimeType, logger = console) {
  const result = {
    valid: false,
    error: null,
    statusCode: 400, // Default to 400, will be 415 for unsupported type
    detectedMime: null,
    declaredMime: declaredMimeType,
    size: buffer?.length || 0,
  };
  
  // Check if buffer exists
  if (!buffer || buffer.length === 0) {
    result.error = 'No file provided';
    result.statusCode = 400;
    return result;
  }
  
  // Check file size
  if (buffer.length > UPLOAD_LIMITS.maxFileSizeBytes) {
    result.error = `File too large. Maximum size is ${UPLOAD_LIMITS.maxFileSizeMB}MB`;
    result.statusCode = 413; // Payload Too Large
    return result;
  }
  
  // Detect MIME from magic bytes (primary source)
  const detectedMime = detectMimeFromBytes(buffer);
  result.detectedMime = detectedMime;
  
  // Log for debugging
  logger.info?.({ declaredMimeType, detectedMime, size: buffer.length }, 'Upload validation');
  
  // If we detected a MIME type, use it; otherwise trust declared type
  const effectiveMime = detectedMime || declaredMimeType?.toLowerCase();
  
  // Check if MIME type is allowed
  if (!effectiveMime || !UPLOAD_LIMITS.allowedMimeTypes.has(effectiveMime)) {
    // Specific message for known unsupported types
    if (effectiveMime === 'application/pdf') {
      result.error = 'PDF files are not supported yet. Please take a photo of your receipt or export as an image.';
    } else if (effectiveMime === 'image/gif') {
      result.error = 'GIF files are not supported. Please use JPG, PNG, or WebP.';
    } else if (effectiveMime?.startsWith('image/tiff') || effectiveMime === 'image/tiff') {
      result.error = 'TIFF files are not supported. Please use JPG, PNG, or WebP.';
    } else {
      result.error = 'Unsupported file type. Only images are allowed (JPG, PNG, WebP, HEIC).';
    }
    result.statusCode = 415; // Unsupported Media Type
    result.supportedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
    logger.warn?.({ declaredMimeType, detectedMime, effectiveMime }, 'Unsupported media type');
    return result;
  }
  
  // If declared MIME doesn't match detected, log warning but allow
  // (some browsers send wrong MIME types like image/pjpeg)
  if (detectedMime && declaredMimeType && detectedMime !== declaredMimeType.toLowerCase()) {
    logger.warn?.({ declaredMimeType, detectedMime }, 'MIME mismatch (allowing based on magic bytes)');
  }
  
  // Verify magic bytes match for known types
  if (detectedMime && !checkMagicBytes(buffer, detectedMime)) {
    result.error = 'File content does not match declared type';
    result.statusCode = 400;
    return result;
  }
  
  result.valid = true;
  result.statusCode = null; // No error
  return result;
}

/**
 * Get upload limits (for documentation/frontend)
 */
export function getUploadLimits() {
  return {
    maxSizeBytes: UPLOAD_LIMITS.maxFileSizeBytes,
    maxSizeMB: UPLOAD_LIMITS.maxFileSizeMB,
    allowedTypes: Array.from(UPLOAD_LIMITS.allowedMimeTypes),
  };
}

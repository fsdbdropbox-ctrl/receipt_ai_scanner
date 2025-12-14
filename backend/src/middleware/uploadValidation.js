/**
 * Upload validation middleware
 * Validates file size, MIME type, and magic bytes
 */

// Configuration
const UPLOAD_LIMITS = {
  maxFileSizeBytes: 10 * 1024 * 1024, // 10MB
  maxFileSizeMB: 10,
  allowedMimeTypes: [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'image/heif',
  ],
};

// Magic bytes for common image formats
const MAGIC_BYTES = {
  'image/jpeg': [
    [0xFF, 0xD8, 0xFF],
  ],
  'image/png': [
    [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
  ],
  'image/gif': [
    [0x47, 0x49, 0x46, 0x38, 0x37, 0x61], // GIF87a
    [0x47, 0x49, 0x46, 0x38, 0x39, 0x61], // GIF89a
  ],
  'image/webp': [
    // RIFF....WEBP (bytes 0-3 = RIFF, bytes 8-11 = WEBP)
    // We check first 4 bytes for RIFF
    [0x52, 0x49, 0x46, 0x46],
  ],
  // HEIC has complex structure, relax validation for it
  'image/heic': null,
  'image/heif': null,
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
  
  // JPEG
  if (buffer[0] === 0xFF && buffer[1] === 0xD8 && buffer[2] === 0xFF) {
    return 'image/jpeg';
  }
  
  // PNG
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4E && buffer[3] === 0x47) {
    return 'image/png';
  }
  
  // GIF
  if (buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) {
    return 'image/gif';
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
  
  return null;
}

/**
 * Validate uploaded image
 * @param {Buffer} buffer - Image buffer
 * @param {string} declaredMimeType - MIME type declared by client
 * @returns {Object} - Validation result
 */
export function validateUpload(buffer, declaredMimeType) {
  const result = {
    valid: false,
    error: null,
    detectedMime: null,
    size: buffer?.length || 0,
  };
  
  // Check if buffer exists
  if (!buffer || buffer.length === 0) {
    result.error = 'No file provided';
    return result;
  }
  
  // Check file size
  if (buffer.length > UPLOAD_LIMITS.maxFileSizeBytes) {
    result.error = `File too large. Maximum size is ${UPLOAD_LIMITS.maxFileSizeMB}MB`;
    return result;
  }
  
  // Detect MIME from magic bytes
  const detectedMime = detectMimeFromBytes(buffer);
  result.detectedMime = detectedMime;
  
  // If we detected a MIME type, use it; otherwise trust declared type
  const effectiveMime = detectedMime || declaredMimeType?.toLowerCase();
  
  // Check if MIME type is allowed
  if (!effectiveMime || !UPLOAD_LIMITS.allowedMimeTypes.includes(effectiveMime)) {
    result.error = `Invalid file type. Allowed: JPEG, PNG, GIF, WebP, HEIC`;
    return result;
  }
  
  // If declared MIME doesn't match detected, log warning but allow
  // (some browsers send wrong MIME types)
  if (detectedMime && declaredMimeType && detectedMime !== declaredMimeType.toLowerCase()) {
    console.warn(`MIME mismatch: declared=${declaredMimeType}, detected=${detectedMime}`);
  }
  
  // Verify magic bytes match for known types
  if (detectedMime && !checkMagicBytes(buffer, detectedMime)) {
    result.error = 'File content does not match declared type';
    return result;
  }
  
  result.valid = true;
  return result;
}

/**
 * Get upload limits (for documentation/frontend)
 */
export function getUploadLimits() {
  return {
    maxSizeBytes: UPLOAD_LIMITS.maxFileSizeBytes,
    maxSizeMB: UPLOAD_LIMITS.maxFileSizeMB,
    allowedTypes: UPLOAD_LIMITS.allowedMimeTypes,
  };
}


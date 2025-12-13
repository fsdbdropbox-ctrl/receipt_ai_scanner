import sharp from 'sharp';

const MAX_DIMENSION = 2048;
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

export async function processImage(buffer) {
  // Check file size
  if (buffer.length > MAX_FILE_SIZE) {
    throw new Error('File too large');
  }

  // Get image metadata
  const metadata = await sharp(buffer).metadata();
  
  // Resize if needed
  let processed = sharp(buffer);
  
  if (metadata.width > MAX_DIMENSION || metadata.height > MAX_DIMENSION) {
    processed = processed.resize(MAX_DIMENSION, MAX_DIMENSION, {
      fit: 'inside',
      withoutEnlargement: true,
    });
  }

  // Convert to JPEG, remove EXIF
  const jpegBuffer = await processed
    .jpeg({ quality: 90 })
    .toBuffer();

  return jpegBuffer;
}


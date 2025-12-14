enum ScanErrorCode {
  networkError,
  quotaExceeded,
  invalidImage,
  unsupportedFileType,
  processingError,
  fileTooLarge,
  unknown;

  String getMessage(String locale) {
    final isSpanish = locale.startsWith('es');
    switch (this) {
      case ScanErrorCode.networkError:
        return isSpanish
            ? 'Error de conexión. Verifica tu internet.'
            : 'Connection error. Check your internet.';
      case ScanErrorCode.quotaExceeded:
        return isSpanish
            ? 'Límite diario alcanzado. Actualiza para escaneos ilimitados.'
            : 'Daily limit reached. Upgrade for unlimited scans.';
      case ScanErrorCode.invalidImage:
        return isSpanish
            ? 'Imagen inválida. Intenta con otra foto.'
            : 'Invalid image. Try another photo.';
      case ScanErrorCode.unsupportedFileType:
        return isSpanish
            ? 'Tipo de archivo no soportado. Usa JPG, PNG o WebP.'
            : 'Unsupported file type. Use JPG, PNG, or WebP.';
      case ScanErrorCode.fileTooLarge:
        return isSpanish
            ? 'Archivo demasiado grande. Máximo 10MB.'
            : 'File too large. Maximum 10MB.';
      case ScanErrorCode.processingError:
        return isSpanish
            ? 'Error al procesar. Intenta de nuevo.'
            : 'Processing error. Please try again.';
      case ScanErrorCode.unknown:
        return isSpanish
            ? 'Error inesperado. Intenta más tarde.'
            : 'Unexpected error. Please try again later.';
    }
  }
}

class ScanError implements Exception {
  final ScanErrorCode code;
  final String message;

  ScanError({
    required this.code,
    required this.message,
  });

  factory ScanError.fromApiResponse(int statusCode, Map<String, dynamic>? body) {
    final apiMessage = body?['message']?.toString();
    
    if (statusCode == 429) {
      return ScanError(
        code: ScanErrorCode.quotaExceeded,
        message: apiMessage ?? 'Quota exceeded',
      );
    }
    if (statusCode == 415) {
      // Unsupported Media Type
      return ScanError(
        code: ScanErrorCode.unsupportedFileType,
        message: apiMessage ?? 'Unsupported file type',
      );
    }
    if (statusCode == 413) {
      // Payload Too Large
      return ScanError(
        code: ScanErrorCode.fileTooLarge,
        message: apiMessage ?? 'File too large',
      );
    }
    if (statusCode == 400) {
      return ScanError(
        code: ScanErrorCode.invalidImage,
        message: apiMessage ?? 'Invalid image',
      );
    }
    if (statusCode >= 500) {
      return ScanError(
        code: ScanErrorCode.processingError,
        message: apiMessage ?? 'Processing error',
      );
    }
    return ScanError(
      code: ScanErrorCode.unknown,
      message: apiMessage ?? 'Unknown error',
    );
  }

  @override
  String toString() => 'ScanError($code): $message';
}

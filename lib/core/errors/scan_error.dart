enum ScanErrorCode {
  networkError,
  quotaExceeded,
  invalidImage,
  processingError,
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

class ScanError {
  final ScanErrorCode code;
  final String message;

  ScanError({
    required this.code,
    required this.message,
  });

  factory ScanError.fromApiResponse(int statusCode, Map<String, dynamic>? body) {
    if (statusCode == 429) {
      return ScanError(
        code: ScanErrorCode.quotaExceeded,
        message: body?['message']?.toString() ?? 'Quota exceeded',
      );
    }
    if (statusCode == 400) {
      return ScanError(
        code: ScanErrorCode.invalidImage,
        message: body?['message']?.toString() ?? 'Invalid image',
      );
    }
    if (statusCode >= 500) {
      return ScanError(
        code: ScanErrorCode.processingError,
        message: body?['message']?.toString() ?? 'Processing error',
      );
    }
    return ScanError(
      code: ScanErrorCode.unknown,
      message: body?['message']?.toString() ?? 'Unknown error',
    );
  }
}


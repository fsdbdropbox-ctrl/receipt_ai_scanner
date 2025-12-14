import 'package:flutter/services.dart';

/// Implementación para mobile/desktop: copia al portapapeles
class CsvHelperIO {
  static Future<void> copyCSV(String csvContent) async {
    await Clipboard.setData(ClipboardData(text: csvContent));
  }
}


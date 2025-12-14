import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports: platform-specific implementations
import 'csv_helper_web.dart' if (dart.library.io) 'csv_helper_web_stub.dart';
import 'csv_helper_io.dart' if (dart.library.html) 'csv_helper_io_stub.dart';

/// Helper para exportar datos a CSV
class CsvHelper {
  /// Descarga o copia CSV según la plataforma
  static Future<void> exportCSV(String csvContent, String filename) async {
    if (kIsWeb) {
      await CsvHelperWeb.downloadCSV(csvContent, filename);
    } else {
      await CsvHelperIO.copyCSV(csvContent);
    }
  }
}


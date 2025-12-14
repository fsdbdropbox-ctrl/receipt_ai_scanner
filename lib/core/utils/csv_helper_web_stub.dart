/// Stub implementation for non-web platforms
class CsvHelperWeb {
  static Future<void> downloadCSV(String csvContent, String filename) async {
    throw UnsupportedError('CsvHelperWeb is only available on web');
  }
}


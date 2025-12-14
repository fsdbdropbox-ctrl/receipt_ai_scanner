import 'dart:convert';
import 'dart:html' as html;

/// Implementación para web: descarga el CSV como archivo
class CsvHelperWeb {
  static Future<void> downloadCSV(String csvContent, String filename) async {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}


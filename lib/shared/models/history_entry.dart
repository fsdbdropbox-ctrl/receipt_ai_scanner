import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';

/// Represents a saved scan entry in history
class HistoryEntry {
  final String id;
  final DateTime scannedAt;
  final DateTime? invoiceDate;
  final double? total;
  final double? tax;
  final String? vendor;
  final InvoiceCategory category;
  final String? currency;
  final double confidence;

  HistoryEntry({
    required this.id,
    required this.scannedAt,
    this.invoiceDate,
    this.total,
    this.tax,
    this.vendor,
    required this.category,
    this.currency,
    required this.confidence,
  });

  /// Create from InvoiceData after scan
  factory HistoryEntry.fromInvoiceData(InvoiceData data) {
    return HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scannedAt: DateTime.now(),
      invoiceDate: data.date,
      total: data.total,
      tax: data.tax,
      vendor: data.vendor,
      category: data.category,
      currency: data.currency,
      confidence: data.confidence,
    );
  }

  /// Create from JSON (for storage)
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.tryParse(json['invoiceDate'] as String)
          : null,
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      tax: json['tax'] != null ? (json['tax'] as num).toDouble() : null,
      vendor: json['vendor'] as String?,
      category: InvoiceCategory.fromString(json['category'] as String?),
      currency: json['currency'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scannedAt': scannedAt.toIso8601String(),
      'invoiceDate': invoiceDate?.toIso8601String(),
      'total': total,
      'tax': tax,
      'vendor': vendor,
      'category': category.name,
      'currency': currency,
      'confidence': confidence,
    };
  }

  /// Convert to CSV row
  String toCsvRow() {
    final dateStr = invoiceDate?.toIso8601String().split('T').first ?? '';
    final vendorStr = vendor?.replaceAll(',', ';') ?? '';
    final totalStr = total?.toStringAsFixed(2) ?? '';
    final taxStr = tax?.toStringAsFixed(2) ?? '';
    final currencyStr = currency ?? '';
    final categoryStr = category.name;

    return '$dateStr,$vendorStr,$totalStr,$taxStr,$currencyStr,$categoryStr';
  }

  /// Convert to TSV row (for Excel paste)
  /// Columns: date, vendor, total, tax, currency, category, confidence
  String toTsvRow() {
    final dateStr = invoiceDate?.toIso8601String().split('T').first ?? '';
    final vendorStr = vendor?.replaceAll('\t', ' ') ?? '';
    final totalStr = total?.toStringAsFixed(2) ?? '';
    final taxStr = tax?.toStringAsFixed(2) ?? '';
    final currencyStr = currency ?? '';
    final categoryStr = category.name;
    final confidenceStr = confidence.toStringAsFixed(2);

    return '$dateStr\t$vendorStr\t$totalStr\t$taxStr\t$currencyStr\t$categoryStr\t$confidenceStr';
  }

  /// TSV header (English, for data consistency)
  static String get tsvHeader => 'date\tvendor\ttotal\ttax\tcurrency\tcategory\tconfidence';

  /// Get formatted display amount
  String getFormattedAmount(String locale) {
    if (total == null) return '-';
    final currencySymbol = currency ?? '\$';
    return '$currencySymbol${total!.toStringAsFixed(2)}';
  }

  /// Get formatted date for display
  String getFormattedDate(String locale) {
    final date = invoiceDate ?? scannedAt;
    final isSpanish = locale.startsWith('es');
    final months = isSpanish
        ? ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}


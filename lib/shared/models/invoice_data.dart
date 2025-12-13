enum InvoiceCategory {
  food,
  travel,
  office,
  utilities,
  healthcare,
  retail,
  other;

  static InvoiceCategory fromString(String? value) {
    if (value == null) return InvoiceCategory.other;
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'food':
      case 'restaurant':
      case 'dining':
        return InvoiceCategory.food;
      case 'travel':
      case 'hotel':
      case 'transport':
        return InvoiceCategory.travel;
      case 'office':
      case 'supplies':
      case 'stationery':
        return InvoiceCategory.office;
      case 'utilities':
      case 'electricity':
      case 'water':
      case 'gas':
        return InvoiceCategory.utilities;
      case 'healthcare':
      case 'medical':
      case 'pharmacy':
        return InvoiceCategory.healthcare;
      case 'retail':
      case 'shopping':
        return InvoiceCategory.retail;
      default:
        return InvoiceCategory.other;
    }
  }

  String getDisplayName(String locale) {
    switch (this) {
      case InvoiceCategory.food:
        return locale.startsWith('es') ? 'Comida' : 'Food';
      case InvoiceCategory.travel:
        return locale.startsWith('es') ? 'Viajes' : 'Travel';
      case InvoiceCategory.office:
        return locale.startsWith('es') ? 'Oficina' : 'Office';
      case InvoiceCategory.utilities:
        return locale.startsWith('es') ? 'Servicios' : 'Utilities';
      case InvoiceCategory.healthcare:
        return locale.startsWith('es') ? 'Salud' : 'Healthcare';
      case InvoiceCategory.retail:
        return locale.startsWith('es') ? 'Compras' : 'Retail';
      case InvoiceCategory.other:
        return locale.startsWith('es') ? 'Otro' : 'Other';
    }
  }
}

class InvoiceData {
  final DateTime? date;
  final double? total;
  final double? tax;
  final String? vendor;
  final InvoiceCategory category;
  final String? currency;
  final double confidence;
  final String? rawResponse;

  InvoiceData({
    this.date,
    this.total,
    this.tax,
    this.vendor,
    required this.category,
    this.currency,
    required this.confidence,
    this.rawResponse,
  });

  factory InvoiceData.fromJson(Map<String, dynamic> json, String rawResponse) {
    // Calculate confidence based on extracted fields
    int fieldsFound = 0;
    if (json['total'] != null) fieldsFound++;
    if (json['vendor'] != null) fieldsFound++;
    if (json['date'] != null) fieldsFound++;
    
    final confidence = fieldsFound / 3.0; // 0.0 to 1.0

    return InvoiceData(
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      total: json['total'] != null ? (json['total'] is num ? json['total'].toDouble() : double.tryParse(json['total'].toString())) : null,
      tax: json['tax'] != null ? (json['tax'] is num ? json['tax'].toDouble() : double.tryParse(json['tax'].toString())) : null,
      vendor: json['vendor']?.toString(),
      category: InvoiceCategory.fromString(json['category']?.toString()),
      currency: json['currency']?.toString(),
      confidence: confidence,
      rawResponse: rawResponse,
    );
  }
}


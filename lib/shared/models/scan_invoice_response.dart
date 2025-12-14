import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';

class QuotaInfo {
  final int scansLeft;
  final bool isPremium;

  QuotaInfo({
    required this.scansLeft,
    required this.isPremium,
  });

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      scansLeft: json['scansLeft'] as int? ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}

class ScanInvoiceResponse {
  final InvoiceData invoiceData;
  final QuotaInfo quotaInfo;

  ScanInvoiceResponse({
    required this.invoiceData,
    required this.quotaInfo,
  });

  factory ScanInvoiceResponse.fromJson(Map<String, dynamic> json, String rawResponse) {
    // Safely extract data and quota, handling null cases
    final dataJson = json['data'];
    final quotaJson = json['quota'];
    
    if (dataJson == null || quotaJson == null) {
      throw FormatException(
        'Missing required fields in response: data=${dataJson != null}, quota=${quotaJson != null}',
      );
    }
    
    return ScanInvoiceResponse(
      invoiceData: InvoiceData.fromJson(dataJson as Map<String, dynamic>, rawResponse),
      quotaInfo: QuotaInfo.fromJson(quotaJson as Map<String, dynamic>),
    );
  }
}


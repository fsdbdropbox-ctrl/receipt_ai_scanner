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
    return ScanInvoiceResponse(
      invoiceData: InvoiceData.fromJson(json['data'] as Map<String, dynamic>, rawResponse),
      quotaInfo: QuotaInfo.fromJson(json['quota'] as Map<String, dynamic>),
    );
  }
}


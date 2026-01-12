class DashboardMetrics {
  final IntegrityMetrics integrity;
  final FinancialMetrics financial;
  final QualityMetrics quality;
  final List<DocumentIssue> issues;
  final List<ValidationFlag> flags;

  DashboardMetrics({
    required this.integrity,
    required this.financial,
    required this.quality,
    required this.issues,
    required this.flags,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    try {
      return DashboardMetrics(
        integrity: IntegrityMetrics.fromJson(
          json['integrity'] as Map<String, dynamic>? ?? {},
        ),
        financial: FinancialMetrics.fromJson(
          json['financial'] as Map<String, dynamic>? ?? {},
        ),
        quality: QualityMetrics.fromJson(
          json['quality'] as Map<String, dynamic>? ?? {},
        ),
        issues: (json['issues'] as List<dynamic>?)
                ?.map((e) => DocumentIssue.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        flags: (json['flags'] as List<dynamic>?)
                ?.map((e) => ValidationFlag.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      throw FormatException('Failed to parse DashboardMetrics: $e');
    }
  }
}

class IntegrityMetrics {
  final int percentage;
  final int total;
  final int valid;
  final int invalid;
  final int quarantine;
  final int pending;

  IntegrityMetrics({
    required this.percentage,
    required this.total,
    required this.valid,
    required this.invalid,
    required this.quarantine,
    required this.pending,
  });

  factory IntegrityMetrics.fromJson(Map<String, dynamic> json) {
    return IntegrityMetrics(
      percentage: (json['percentage'] as num?)?.toInt() ?? 100,
      total: (json['total'] as num?)?.toInt() ?? 0,
      valid: (json['valid'] as num?)?.toInt() ?? 0,
      invalid: (json['invalid'] as num?)?.toInt() ?? 0,
      quarantine: (json['quarantine'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinancialMetrics {
  final double totalAmount;
  final String currency;

  FinancialMetrics({
    required this.totalAmount,
    required this.currency,
  });

  factory FinancialMetrics.fromJson(Map<String, dynamic> json) {
    return FinancialMetrics(
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'EUR',
    );
  }
}

class QualityMetrics {
  final double avgConfidence;

  QualityMetrics({
    required this.avgConfidence,
  });

  factory QualityMetrics.fromJson(Map<String, dynamic> json) {
    return QualityMetrics(
      avgConfidence: (json['avgConfidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DocumentIssue {
  final String id;
  final String? vendor;
  final double? total;
  final DateTime? date;
  final String status;
  final int openFlags;

  DocumentIssue({
    required this.id,
    this.vendor,
    this.total,
    this.date,
    required this.status,
    required this.openFlags,
  });

  factory DocumentIssue.fromJson(Map<String, dynamic> json) {
    return DocumentIssue(
      id: json['id'] as String? ?? '',
      vendor: json['vendor'] as String?,
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      status: json['status'] as String? ?? 'unknown',
      openFlags: (json['openFlags'] as num?)?.toInt() ?? 0,
    );
  }
}

class ValidationFlag {
  final String code;
  final String severity;
  final int count;

  ValidationFlag({
    required this.code,
    required this.severity,
    required this.count,
  });

  factory ValidationFlag.fromJson(Map<String, dynamic> json) {
    return ValidationFlag(
      code: json['code'] as String? ?? '',
      severity: json['severity'] as String? ?? 'error',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

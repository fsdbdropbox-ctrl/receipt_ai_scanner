class FiscalProfile {
  final String id;
  final String userId;
  final String countryCode;
  final String taxId;
  final String taxRegime;
  final String? activitySector;
  final DateTime createdAt;
  final DateTime updatedAt;

  FiscalProfile({
    required this.id,
    required this.userId,
    required this.countryCode,
    required this.taxId,
    required this.taxRegime,
    this.activitySector,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FiscalProfile.fromJson(Map<String, dynamic> json) {
    try {
      return FiscalProfile(
        id: json['id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        countryCode: json['country_code'] as String? ?? '',
        taxId: json['tax_id'] as String? ?? '',
        taxRegime: json['tax_regime'] as String? ?? '',
        activitySector: json['activity_sector'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Failed to parse FiscalProfile: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'country_code': countryCode,
      'tax_id': taxId,
      'tax_regime': taxRegime,
      'activity_sector': activitySector,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum TaxRegime {
  autonomo,
  empresa,
  simplificado;

  String getDisplayName(String locale) {
    switch (this) {
      case TaxRegime.autonomo:
        return locale.startsWith('es') ? 'Autónomo' : 'Freelancer';
      case TaxRegime.empresa:
        return locale.startsWith('es') ? 'Empresa' : 'Company';
      case TaxRegime.simplificado:
        return locale.startsWith('es') ? 'Simplificado' : 'Simplified';
    }
  }

  static TaxRegime fromString(String value) {
    switch (value.toLowerCase()) {
      case 'autonomo':
      case 'freelancer':
        return TaxRegime.autonomo;
      case 'empresa':
      case 'company':
        return TaxRegime.empresa;
      case 'simplificado':
      case 'simplified':
        return TaxRegime.simplificado;
      default:
        return TaxRegime.autonomo;
    }
  }
}

enum SupportedCountry {
  es('ES', 'España', '🇪🇸'),
  mx('MX', 'México', '🇲🇽'),
  de('DE', 'Deutschland', '🇩🇪');

  final String code;
  final String name;
  final String flag;

  const SupportedCountry(this.code, this.name, this.flag);
}

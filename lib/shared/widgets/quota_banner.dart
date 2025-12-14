import 'package:flutter/material.dart';

enum QuotaStatus {
  normal,
  low,
  exhausted,
}

/// Enhanced quota info from backend
class QuotaInfo {
  final int scansLeft;
  final int? scansUsed;
  final int? limit;
  final String period; // 'daily' or 'monthly'
  final int? daysUntilReset;
  final bool isPremium;
  final bool limitReached;

  const QuotaInfo({
    required this.scansLeft,
    this.scansUsed,
    this.limit,
    this.period = 'daily',
    this.daysUntilReset,
    required this.isPremium,
    this.limitReached = false,
  });

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      scansLeft: json['scansLeft'] as int? ?? 0,
      scansUsed: json['scansUsed'] as int?,
      limit: json['limit'] as int?,
      period: json['period'] as String? ?? 'daily',
      daysUntilReset: json['daysUntilReset'] as int?,
      isPremium: json['isPremium'] as bool? ?? false,
      limitReached: json['limitReached'] as bool? ?? false,
    );
  }

  /// Simple constructor for backwards compatibility
  factory QuotaInfo.simple({
    required int scansLeft,
    required bool isPremium,
  }) {
    return QuotaInfo(
      scansLeft: scansLeft,
      isPremium: isPremium,
      limitReached: scansLeft <= 0,
    );
  }
}

class QuotaBanner extends StatelessWidget {
  final int scansLeft;
  final bool isPremium;
  final VoidCallback? onUpgrade;
  final QuotaInfo? quotaInfo; // Enhanced quota info (optional)

  const QuotaBanner({
    super.key,
    required this.scansLeft,
    required this.isPremium,
    this.onUpgrade,
    this.quotaInfo,
  });

  QuotaStatus get _status {
    if (scansLeft <= 0) return QuotaStatus.exhausted;
    if (scansLeft == 1) return QuotaStatus.low;
    return QuotaStatus.normal;
  }

  @override
  Widget build(BuildContext context) {
    // For unlimited premium users (scansLeft = -1), don't show banner
    if (isPremium && scansLeft < 0) return const SizedBox.shrink();
    
    // For premium users with plenty of scans left, show a subtle indicator
    if (isPremium && scansLeft > 100) {
      return _buildPremiumBanner(context);
    }

    final status = _status;
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String message;
    String? secondaryMessage;

    switch (status) {
      case QuotaStatus.exhausted:
        backgroundColor = const Color(0xFFFFF7ED);
        borderColor = const Color(0xFFF97316);
        textColor = const Color(0xFF9A3412);
        icon = Icons.warning_amber_rounded;
        
        if (isPremium && quotaInfo?.daysUntilReset != null) {
          message = isSpanish
              ? 'Límite mensual alcanzado'
              : 'Monthly limit reached';
          secondaryMessage = isSpanish
              ? 'Se reinicia en ${quotaInfo!.daysUntilReset} días'
              : 'Resets in ${quotaInfo!.daysUntilReset} days';
        } else {
          message = isSpanish
              ? 'Límite alcanzado'
              : 'Limit reached';
          secondaryMessage = isSpanish
              ? 'Actualiza para escaneos ilimitados'
              : 'Upgrade for unlimited scans';
        }
        break;
        
      case QuotaStatus.low:
        backgroundColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFF92400E);
        icon = Icons.info_outline;
        message = isSpanish
            ? 'Te queda 1 escaneo'
            : '1 scan left';
        secondaryMessage = isPremium ? null : (isSpanish
            ? 'Actualiza para ilimitados'
            : 'Upgrade for unlimited');
        break;
        
      case QuotaStatus.normal:
        backgroundColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        textColor = const Color(0xFF1E3A8A);
        icon = Icons.check_circle_outline;
        
        final period = quotaInfo?.period ?? 'daily';
        if (period == 'monthly' && quotaInfo?.limit != null) {
          final used = quotaInfo?.scansUsed ?? 0;
          message = isSpanish
              ? '$used / ${quotaInfo!.limit} escaneos usados'
              : '$used / ${quotaInfo!.limit} scans used';
        } else {
          message = isSpanish
              ? '$scansLeft escaneos restantes hoy'
              : '$scansLeft scans remaining today';
        }
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (secondaryMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondaryMessage,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isPremium && (status == QuotaStatus.exhausted || status == QuotaStatus.low))
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                backgroundColor: borderColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSpanish ? 'Actualizar' : 'Upgrade',
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // green-50
        border: Border.all(color: const Color(0xFF86EFAC), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFF22C55E), size: 18),
          const SizedBox(width: 8),
          Text(
            isSpanish ? 'Premium activo' : 'Premium active',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

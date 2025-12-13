import 'package:flutter/material.dart';

enum QuotaStatus {
  normal,
  low,
  exhausted,
}

class QuotaBanner extends StatelessWidget {
  final int scansLeft;
  final bool isPremium;
  final VoidCallback? onUpgrade;

  const QuotaBanner({
    super.key,
    required this.scansLeft,
    required this.isPremium,
    this.onUpgrade,
  });

  QuotaStatus get _status {
    if (scansLeft <= 0) return QuotaStatus.exhausted;
    if (scansLeft == 1) return QuotaStatus.low;
    return QuotaStatus.normal;
  }

  @override
  Widget build(BuildContext context) {
    if (isPremium) return const SizedBox.shrink();

    final status = _status;
    final locale = Localizations.localeOf(context).toString();

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String message;

    switch (status) {
      case QuotaStatus.exhausted:
        backgroundColor = const Color(0xFFFFF7ED); // orange bg
        borderColor = const Color(0xFFF97316); // orange border
        textColor = const Color(0xFF9A3412); // orange text
        message = locale.startsWith('es')
            ? 'Límite alcanzado. Actualiza para escaneos ilimitados.'
            : 'Limit reached. Upgrade for unlimited scans.';
        break;
      case QuotaStatus.low:
        backgroundColor = const Color(0xFFFEF3C7); // amber bg
        borderColor = const Color(0xFFF59E0B); // amber border
        textColor = const Color(0xFF92400E); // amber text
        message = locale.startsWith('es')
            ? 'Te queda 1 escaneo. Actualiza para ilimitados.'
            : '1 scan left. Upgrade for unlimited.';
        break;
      case QuotaStatus.normal:
        backgroundColor = const Color(0xFFEFF6FF); // blue bg
        borderColor = const Color(0xFF93C5FD); // blue border
        textColor = const Color(0xFF1E3A8A); // blue text
        message = locale.startsWith('es')
            ? 'Escaneos restantes: $scansLeft'
            : 'Scans remaining: $scansLeft';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (status == QuotaStatus.exhausted || status == QuotaStatus.low)
            TextButton(
              onPressed: onUpgrade,
              child: Text(
                locale.startsWith('es') ? 'Actualizar' : 'Upgrade',
                style: TextStyle(color: borderColor, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}


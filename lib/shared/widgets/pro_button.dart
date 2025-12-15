import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_ai_scanner/core/locale/locale_provider.dart';
import 'package:receipt_ai_scanner/core/quota/quota_provider.dart';

/// Subtle Pro button for AppBar - always visible for discovery
/// Shows "⭐ Pro" for free users, "✓ Premium" for premium users
class ProButton extends StatelessWidget {
  final VoidCallback onTap;

  const ProButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isSpanish = localeProvider.isSpanish(context);

    return Consumer<QuotaProvider>(
      builder: (context, quotaProvider, _) {
        final isPremium = quotaProvider.isPremium;

        if (isPremium) {
          // Premium user: show non-actionable badge
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // green-100
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Color(0xFF16A34A), // green-600
                ),
                const SizedBox(width: 4),
                Text(
                  'Premium',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          );
        }

        // Free user: show clickable Pro button
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // amber-100
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFCD34D), // amber-300
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Color(0xFFD97706), // amber-600
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pro',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_ai_scanner/core/locale/locale_provider.dart';

/// Simple language selector widget (can be used in AppBar or Settings)
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final isSpanish = localeProvider.isSpanish(context);
        
        return PopupMenuButton<String>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSpanish ? '🇪🇸' : '🇬🇧',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
          onSelected: (value) {
            localeProvider.setLocale(Locale(value));
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'es',
              child: Row(
                children: [
                  const Text('🇪🇸', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    'Español',
                    style: TextStyle(
                      fontWeight: isSpanish ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isSpanish) ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 18),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: 'en',
              child: Row(
                children: [
                  const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(
                    'English',
                    style: TextStyle(
                      fontWeight: !isSpanish ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (!isSpanish) ...[
                    const Spacer(),
                    const Icon(Icons.check, size: 18),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}


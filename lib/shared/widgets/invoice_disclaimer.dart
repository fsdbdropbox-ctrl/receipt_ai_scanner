import 'package:flutter/material.dart';

class InvoiceDisclaimer extends StatelessWidget {
  const InvoiceDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isSpanish
            ? 'Esta información se extrae automáticamente y puede contener errores. '
                'Siempre verifica los datos importantes antes de usarlos para fines legales o fiscales.'
            : 'This information is automatically extracted and may contain errors. '
                'Always verify important data before using it for legal or tax purposes.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';
import 'package:receipt_ai_scanner/shared/utils/regional_formatter.dart';
import 'package:receipt_ai_scanner/shared/widgets/invoice_disclaimer.dart';

class ResultView extends StatelessWidget {
  final InvoiceData invoiceData;

  const ResultView({
    super.key,
    required this.invoiceData,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Resultado' : 'Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyToClipboard(context, locale),
            tooltip: isSpanish ? 'Copiar' : 'Copy',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalCard(context, locale),
            const SizedBox(height: 16),
            _buildDetailsCard(context, locale),
            const SizedBox(height: 16),
            _buildConfidenceBadge(context, locale),
            const SizedBox(height: 24),
            const InvoiceDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, String locale) {
    final total = invoiceData.total;
    final currency = invoiceData.currency ?? 'USD';
    final formattedTotal = RegionalFormatter.formatCurrency(total, currency, locale);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedTotal,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, String locale) {
    final isSpanish = locale.startsWith('es');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (invoiceData.vendor != null) ...[
              _buildDetailRow(
                context,
                isSpanish ? 'Vendedor' : 'Vendor',
                invoiceData.vendor!,
              ),
              const Divider(),
            ],
            if (invoiceData.date != null) ...[
              _buildDetailRow(
                context,
                isSpanish ? 'Fecha' : 'Date',
                RegionalFormatter.formatDate(invoiceData.date, locale),
              ),
              const Divider(),
            ],
            if (invoiceData.tax != null) ...[
              _buildDetailRow(
                context,
                isSpanish ? 'Impuesto' : 'Tax',
                RegionalFormatter.formatCurrency(
                  invoiceData.tax,
                  invoiceData.currency,
                  locale,
                ),
              ),
              const Divider(),
            ],
            _buildDetailRow(
              context,
              isSpanish ? 'Categoría' : 'Category',
              invoiceData.category.getDisplayName(locale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, String locale) {
    final isSpanish = locale.startsWith('es');
    final confidence = invoiceData.confidence;
    
    String label;
    Color color;
    
    if (confidence >= 0.8) {
      label = isSpanish ? 'Alta confianza' : 'High confidence';
      color = Colors.green;
    } else if (confidence >= 0.5) {
      label = isSpanish ? 'Confianza media' : 'Medium confidence';
      color = Colors.orange;
    } else {
      label = isSpanish ? 'Revisar manualmente' : 'Needs review';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String locale) {
    final isSpanish = locale.startsWith('es');
    final buffer = StringBuffer();
    
    buffer.writeln('Total: ${RegionalFormatter.formatCurrency(invoiceData.total, invoiceData.currency, locale)}');
    if (invoiceData.vendor != null) {
      buffer.writeln('${isSpanish ? "Vendedor" : "Vendor"}: ${invoiceData.vendor}');
    }
    if (invoiceData.date != null) {
      buffer.writeln('${isSpanish ? "Fecha" : "Date"}: ${RegionalFormatter.formatDate(invoiceData.date, locale)}');
    }
    if (invoiceData.tax != null) {
      buffer.writeln('${isSpanish ? "Impuesto" : "Tax"}: ${RegionalFormatter.formatCurrency(invoiceData.tax, invoiceData.currency, locale)}');
    }
    buffer.writeln('${isSpanish ? "Categoría" : "Category"}: ${invoiceData.category.getDisplayName(locale)}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSpanish ? 'Copiado al portapapeles' : 'Copied to clipboard'),
      ),
    );
  }
}


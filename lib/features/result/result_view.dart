import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';
import 'package:receipt_ai_scanner/shared/utils/regional_formatter.dart';
import 'package:receipt_ai_scanner/shared/widgets/invoice_disclaimer.dart';
import 'package:receipt_ai_scanner/core/utils/csv_helper.dart';
import 'package:receipt_ai_scanner/core/history/history_service.dart';

class ResultView extends StatefulWidget {
  final InvoiceData invoiceData;

  const ResultView({
    super.key,
    required this.invoiceData,
  });

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> {
  bool _isSaving = false;

  InvoiceData get invoiceData => widget.invoiceData;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Scaffold(
      appBar: AppBar(
        title: Text(isSpanish ? 'Resultado' : 'Result'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'copy_text':
                  _copyTextToClipboard(context, locale);
                  break;
                case 'copy_json':
                  _copyJsonToClipboard(context, locale);
                  break;
                case 'export_csv':
                  _exportToCSV(context, locale);
                  break;
                case 'share':
                  _shareData(context, locale);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy_text',
                child: Row(
                  children: [
                    const Icon(Icons.copy, size: 20),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Copiar texto' : 'Copy text'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy_json',
                child: Row(
                  children: [
                    const Icon(Icons.code, size: 20),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Copiar JSON' : 'Copy JSON'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, size: 20),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Exportar CSV' : 'Export CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share, size: 20),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Compartir' : 'Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
          ),
          _buildBottomActions(context, isSpanish),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, bool isSpanish) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                ),
                child: Text(isSpanish ? 'Descartar' : 'Discard'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveToHistory(context, isSpanish),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isSpanish ? 'Guardar' : 'Save',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToHistory(BuildContext context, bool isSpanish) async {
    setState(() => _isSaving = true);

    try {
      await HistoryService.instance.saveEntry(invoiceData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish ? 'Guardado en historial' : 'Saved to history'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish ? 'Error al guardar: $e' : 'Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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

  void _copyTextToClipboard(BuildContext context, String locale) {
    final isSpanish = locale.startsWith('es');
    final buffer = StringBuffer();
    
    buffer.writeln('${isSpanish ? "Total" : "Total"}: ${RegionalFormatter.formatCurrency(invoiceData.total, invoiceData.currency, locale)}');
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
        content: Text(isSpanish ? 'Texto copiado al portapapeles' : 'Text copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyJsonToClipboard(BuildContext context, String locale) {
    final isSpanish = locale.startsWith('es');
    final json = {
      'vendor': invoiceData.vendor,
      'date': invoiceData.date?.toIso8601String(),
      'total': invoiceData.total,
      'tax': invoiceData.tax,
      'category': invoiceData.category.name,
      'currency': invoiceData.currency,
      'confidence': invoiceData.confidence,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    Clipboard.setData(ClipboardData(text: jsonString));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSpanish ? 'JSON copiado al portapapeles' : 'JSON copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, String locale) async {
    final isSpanish = locale.startsWith('es');
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('${isSpanish ? "Vendedor" : "Vendor"},${isSpanish ? "Fecha" : "Date"},${isSpanish ? "Total" : "Total"},${isSpanish ? "Impuesto" : "Tax"},${isSpanish ? "Categoría" : "Category"},${isSpanish ? "Moneda" : "Currency"}');
    
    // CSV Data
    final vendor = invoiceData.vendor ?? '';
    final date = invoiceData.date?.toIso8601String().split('T')[0] ?? '';
    final total = invoiceData.total?.toString() ?? '';
    final tax = invoiceData.tax?.toString() ?? '';
    final category = invoiceData.category.getDisplayName(locale);
    final currency = invoiceData.currency ?? 'USD';
    
    buffer.writeln('"$vendor","$date","$total","$tax","$category","$currency"');
    
    final csvContent = buffer.toString();
    final filename = 'receipt_${DateTime.now().millisecondsSinceEpoch}.csv';

    try {
      await CsvHelper.exportCSV(csvContent, filename);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish 
                ? (kIsWeb ? 'CSV descargado' : 'CSV copiado al portapapeles. Pégalo en Excel o Google Sheets.')
                : (kIsWeb ? 'CSV downloaded' : 'CSV copied to clipboard. Paste it in Excel or Google Sheets.'),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish ? 'Error al exportar CSV: $e' : 'Error exporting CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareData(BuildContext context, String locale) async {
    final isSpanish = locale.startsWith('es');
    final buffer = StringBuffer();
    
    buffer.writeln('${isSpanish ? "Recibo escaneado" : "Scanned Receipt"}\n');
    buffer.writeln('${isSpanish ? "Vendedor" : "Vendor"}: ${invoiceData.vendor ?? "-"}');
    buffer.writeln('${isSpanish ? "Fecha" : "Date"}: ${invoiceData.date != null ? RegionalFormatter.formatDate(invoiceData.date, locale) : "-"}');
    buffer.writeln('${isSpanish ? "Total" : "Total"}: ${RegionalFormatter.formatCurrency(invoiceData.total, invoiceData.currency, locale)}');
    if (invoiceData.tax != null) {
      buffer.writeln('${isSpanish ? "Impuesto" : "Tax"}: ${RegionalFormatter.formatCurrency(invoiceData.tax, invoiceData.currency, locale)}');
    }
    buffer.writeln('${isSpanish ? "Categoría" : "Category"}: ${invoiceData.category.getDisplayName(locale)}');
    
    try {
      await Share.share(
        buffer.toString(),
        subject: isSpanish ? 'Recibo escaneado' : 'Scanned Receipt',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish ? 'Error al compartir: $e' : 'Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


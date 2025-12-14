import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:receipt_ai_scanner/shared/models/history_entry.dart';
import 'package:receipt_ai_scanner/shared/utils/regional_formatter.dart';
import 'package:receipt_ai_scanner/core/utils/csv_helper.dart';
import 'package:receipt_ai_scanner/core/history/history_service.dart';

/// Detail view for a history entry
class HistoryDetailView extends StatelessWidget {
  final HistoryEntry entry;

  const HistoryDetailView({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isSpanish ? 'Detalle' : 'Details',
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1E3A8A)),
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
                case 'delete':
                  _confirmDelete(context, isSpanish);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy_text',
                child: Row(
                  children: [
                    const Icon(Icons.copy, size: 20, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Copiar texto' : 'Copy text'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'copy_json',
                child: Row(
                  children: [
                    const Icon(Icons.code, size: 20, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Copiar JSON' : 'Copy JSON'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, size: 20, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Exportar CSV' : 'Export CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share, size: 20, color: Color(0xFF1E3A8A)),
                    const SizedBox(width: 12),
                    Text(isSpanish ? 'Compartir' : 'Share'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      isSpanish ? 'Eliminar' : 'Delete',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
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
            const SizedBox(height: 16),
            _buildScannedDateInfo(context, locale),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, String locale) {
    final total = entry.total;
    final currency = entry.currency ?? 'USD';
    final formattedTotal = total != null
        ? RegionalFormatter.formatCurrency(total, currency, locale)
        : '-';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
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
                    color: const Color(0xFF2563EB),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.vendor != null) ...[
              _buildDetailRow(
                context,
                isSpanish ? 'Vendedor' : 'Vendor',
                entry.vendor!,
              ),
              const Divider(),
            ],
            if (entry.invoiceDate != null) ...[
              _buildDetailRow(
                context,
                isSpanish ? 'Fecha' : 'Date',
                entry.getFormattedDate(locale),
              ),
              const Divider(),
            ],
            if (entry.tax != null) ...[
              _buildDetailRow(
                context,
                isSpanish ? 'Impuesto' : 'Tax',
                RegionalFormatter.formatCurrency(
                  entry.tax,
                  entry.currency,
                  locale,
                ),
              ),
              const Divider(),
            ],
            _buildDetailRow(
              context,
              isSpanish ? 'Categoría' : 'Category',
              entry.category.getDisplayName(locale),
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
    final confidence = entry.confidence;

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
            '$label (${(confidence * 100).toStringAsFixed(0)}%)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedDateInfo(BuildContext context, String locale) {
    final isSpanish = locale.startsWith('es');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            isSpanish
                ? 'Escaneado: ${_formatScannedDate(entry.scannedAt, locale)}'
                : 'Scanned: ${_formatScannedDate(entry.scannedAt, locale)}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatScannedDate(DateTime date, String locale) {
    final isSpanish = locale.startsWith('es');
    final months = isSpanish
        ? ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyTextToClipboard(BuildContext context, String locale) {
    final isSpanish = locale.startsWith('es');
    final buffer = StringBuffer();

    buffer.writeln('${isSpanish ? "Total" : "Total"}: ${entry.total != null ? RegionalFormatter.formatCurrency(entry.total, entry.currency, locale) : "-"}');
    if (entry.vendor != null) {
      buffer.writeln('${isSpanish ? "Vendedor" : "Vendor"}: ${entry.vendor}');
    }
    if (entry.invoiceDate != null) {
      buffer.writeln('${isSpanish ? "Fecha" : "Date"}: ${entry.getFormattedDate(locale)}');
    }
    if (entry.tax != null) {
      buffer.writeln('${isSpanish ? "Impuesto" : "Tax"}: ${RegionalFormatter.formatCurrency(entry.tax, entry.currency, locale)}');
    }
    buffer.writeln('${isSpanish ? "Categoría" : "Category"}: ${entry.category.getDisplayName(locale)}');

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
      'id': entry.id,
      'vendor': entry.vendor,
      'date': entry.invoiceDate?.toIso8601String(),
      'total': entry.total,
      'tax': entry.tax,
      'category': entry.category.name,
      'currency': entry.currency,
      'confidence': entry.confidence,
      'scannedAt': entry.scannedAt.toIso8601String(),
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
    buffer.writeln(entry.toCsvRow());

    final csvContent = buffer.toString();
    final filename = 'receipt_${entry.id}.csv';

    try {
      await CsvHelper.exportCSV(csvContent, filename);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSpanish
                  ? (kIsWeb ? 'CSV descargado' : 'CSV copiado al portapapeles')
                  : (kIsWeb ? 'CSV downloaded' : 'CSV copied to clipboard'),
            ),
            duration: const Duration(seconds: 2),
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
    buffer.writeln('${isSpanish ? "Vendedor" : "Vendor"}: ${entry.vendor ?? "-"}');
    buffer.writeln('${isSpanish ? "Fecha" : "Date"}: ${entry.invoiceDate != null ? entry.getFormattedDate(locale) : "-"}');
    buffer.writeln('${isSpanish ? "Total" : "Total"}: ${entry.total != null ? RegionalFormatter.formatCurrency(entry.total, entry.currency, locale) : "-"}');
    if (entry.tax != null) {
      buffer.writeln('${isSpanish ? "Impuesto" : "Tax"}: ${RegionalFormatter.formatCurrency(entry.tax, entry.currency, locale)}');
    }
    buffer.writeln('${isSpanish ? "Categoría" : "Category"}: ${entry.category.getDisplayName(locale)}');

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

  void _confirmDelete(BuildContext context, bool isSpanish) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isSpanish ? 'Eliminar recibo' : 'Delete receipt'),
        content: Text(
          isSpanish
              ? '¿Estás seguro de que quieres eliminar este recibo?'
              : 'Are you sure you want to delete this receipt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteEntry(context, isSpanish);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isSpanish ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(BuildContext context, bool isSpanish) async {
    try {
      await HistoryService.instance.deleteEntries([entry.id]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish ? 'Recibo eliminado' : 'Receipt deleted'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSpanish ? 'Error al eliminar: $e' : 'Error deleting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receipt_ai_scanner/features/history/history_view_model.dart';
import 'package:receipt_ai_scanner/features/history/history_detail_view.dart';
import 'package:receipt_ai_scanner/shared/models/history_entry.dart';
import 'package:receipt_ai_scanner/shared/models/invoice_data.dart';
import 'package:receipt_ai_scanner/core/utils/csv_helper.dart';
import 'package:receipt_ai_scanner/core/history/history_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Consumer<HistoryViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(context, viewModel, isSpanish),
          body: _buildBody(context, viewModel, isSpanish, locale),
          floatingActionButton: viewModel.selectionMode && viewModel.hasSelection
              ? _buildExportFAB(context, viewModel, isSpanish)
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) {
    if (viewModel.selectionMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E3A8A)),
          onPressed: () => viewModel.exitSelectionMode(),
        ),
        title: Text(
          '${viewModel.selectedCount} ${isSpanish ? 'seleccionados' : 'selected'}',
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (viewModel.selectedCount < viewModel.entries.length)
            TextButton(
              onPressed: () => viewModel.selectAll(),
              child: Text(isSpanish ? 'Todos' : 'All'),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: viewModel.hasSelection
                ? () => _confirmDelete(context, viewModel, isSpanish)
                : null,
          ),
        ],
      );
    }

    if (_showSearch) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () {
            setState(() => _showSearch = false);
            viewModel.clearSearch();
            _searchController.clear();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isSpanish ? 'Buscar por vendedor...' : 'Search by vendor...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          onChanged: (value) => viewModel.search(value),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF1E3A8A)),
              onPressed: () {
                _searchController.clear();
                viewModel.clearSearch();
              },
            ),
        ],
      );
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        isSpanish ? 'Historial' : 'History',
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
          onPressed: () => setState(() => _showSearch = true),
        ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
    String locale,
  ) {
    if (viewModel.state == HistoryState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.state == HistoryState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Error loading history',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadHistory(),
              child: Text(isSpanish ? 'Reintentar' : 'Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.entries.isEmpty) {
      return _buildEmptyState(context, isSpanish);
    }

    return Column(
      children: [
        if (!viewModel.selectionMode) _buildSelectionHint(context, viewModel, isSpanish),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => viewModel.loadHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: viewModel.entries.length,
              itemBuilder: (context, index) {
                final entry = viewModel.entries[index];
                return _buildEntryCard(context, entry, viewModel, locale);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSpanish) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              isSpanish ? 'Sin historial' : 'No history yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isSpanish
                  ? 'Los recibos escaneados aparecerán aquí'
                  : 'Scanned receipts will appear here',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHint(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) {
    return InkWell(
      onTap: () => viewModel.toggleSelectionMode(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.grey[400], size: 20),
            const SizedBox(width: 12),
            Text(
              isSpanish
                  ? 'Toca para activar selección múltiple'
                  : 'Tap to enable multi-select',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    HistoryEntry entry,
    HistoryViewModel viewModel,
    String locale,
  ) {
    final isSelected = viewModel.selectedIds.contains(entry.id);
    final isSpanish = locale.startsWith('es');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (viewModel.selectionMode) {
            viewModel.toggleSelection(entry.id);
          } else {
            // Open detail view
            _openEntryDetail(context, entry, viewModel);
          }
        },
        onLongPress: () {
          if (!viewModel.selectionMode) {
            viewModel.toggleSelectionMode();
            viewModel.toggleSelection(entry.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (viewModel.selectionMode) ...[
                _buildCheckbox(isSelected),
                const SizedBox(width: 12),
              ],
              _buildCategoryIcon(entry.category),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.vendor ?? (isSpanish ? 'Sin nombre' : 'Unknown'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          entry.getFormattedAmount(locale),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            entry.category.getDisplayName(locale),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.getFormattedDate(locale),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey[400]!,
          width: 2,
        ),
        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildCategoryIcon(InvoiceCategory category) {
    IconData icon;
    switch (category) {
      case InvoiceCategory.food:
        icon = Icons.restaurant;
        break;
      case InvoiceCategory.travel:
        icon = Icons.flight;
        break;
      case InvoiceCategory.office:
        icon = Icons.business;
        break;
      case InvoiceCategory.utilities:
        icon = Icons.lightbulb;
        break;
      case InvoiceCategory.healthcare:
        icon = Icons.medical_services;
        break;
      case InvoiceCategory.retail:
        icon = Icons.shopping_bag;
        break;
      case InvoiceCategory.other:
        icon = Icons.receipt;
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(icon, color: const Color(0xFF1E3A8A), size: 22),
    );
  }

  Widget _buildExportFAB(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: () => _showExportOptions(context, viewModel, isSpanish),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.file_download),
        label: Text(
          '${isSpanish ? 'Exportar' : 'Export'} (${viewModel.selectedCount})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showExportOptions(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSpanish
                    ? 'Exportar ${viewModel.selectedCount} recibos'
                    : 'Export ${viewModel.selectedCount} receipts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
              ),
              const SizedBox(height: 24),
              // Primary option: Copy for Excel (most common use case)
              _buildExportOption(
                context,
                icon: Icons.table_view,
                label: isSpanish ? 'Copiar para Excel' : 'Copy for Excel',
                subtitle: isSpanish 
                    ? 'Pega directamente en tu hoja de cálculo' 
                    : 'Paste directly into your spreadsheet',
                onTap: () => _copyForExcel(context, viewModel, isSpanish),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.download,
                label: isSpanish ? 'Exportar CSV' : 'Export CSV',
                subtitle: isSpanish ? 'Descargar archivo' : 'Download file',
                onTap: () => _exportCsv(context, viewModel, isSpanish),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                context,
                icon: Icons.code,
                label: isSpanish ? 'Copiar JSON' : 'Copy JSON',
                subtitle: isSpanish ? 'Para desarrolladores' : 'For developers',
                onTap: () => _copyJson(context, viewModel, isSpanish),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) async {
    Navigator.pop(context);
    final csv = viewModel.exportSelectedToCsv();
    await CsvHelper.exportCSV(csv, 'receipts_export.csv');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSpanish ? 'CSV exportado' : 'CSV exported'),
          backgroundColor: Colors.green,
        ),
      );
    }

    viewModel.exitSelectionMode();
  }

  /// Copy selected entries as TSV for Excel/Sheets paste
  void _copyForExcel(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) {
    Navigator.pop(context);
    
    // Get selected entries
    final selectedEntries = viewModel.entries
        .where((e) => viewModel.selectedIds.contains(e.id))
        .toList();
    
    // Export to TSV
    final tsv = HistoryService.instance.exportToTsv(selectedEntries);
    Clipboard.setData(ClipboardData(text: tsv));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSpanish 
              ? 'Copiado. Pega en Excel o Google Sheets.' 
              : 'Copied. Paste in Excel or Google Sheets.',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    viewModel.exitSelectionMode();
  }

  void _copyJson(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) {
    Navigator.pop(context);
    final jsonStr = viewModel.exportSelectedToJson();
    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isSpanish ? 'JSON copiado' : 'JSON copied'),
        backgroundColor: Colors.green,
      ),
    );

    viewModel.exitSelectionMode();
  }

  void _confirmDelete(
    BuildContext context,
    HistoryViewModel viewModel,
    bool isSpanish,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSpanish ? 'Eliminar recibos' : 'Delete receipts'),
        content: Text(
          isSpanish
              ? '¿Eliminar ${viewModel.selectedCount} recibos seleccionados?'
              : 'Delete ${viewModel.selectedCount} selected receipts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteSelected();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isSpanish ? 'Eliminar' : 'Delete'),
          ),
        ],
      ),
    );
  }

  /// Navigate to entry detail view
  Future<void> _openEntryDetail(
    BuildContext context,
    HistoryEntry entry,
    HistoryViewModel viewModel,
  ) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailView(entry: entry),
      ),
    );

    // Refresh list if entry was deleted
    if (deleted == true && context.mounted) {
      viewModel.loadHistory();
    }
  }
}


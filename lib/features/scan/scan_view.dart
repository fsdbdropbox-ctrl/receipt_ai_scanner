import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view_model.dart';
import 'package:receipt_ai_scanner/features/result/result_view.dart';
import 'package:receipt_ai_scanner/features/paywall/paywall_view.dart';
import 'package:receipt_ai_scanner/core/file_picker/invoice_image_picker.dart';
import 'package:receipt_ai_scanner/shared/widgets/quota_banner.dart';
import 'package:receipt_ai_scanner/core/errors/scan_error.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt AI Scanner'),
        centerTitle: true,
      ),
      body: Consumer<ScanViewModel>(
        builder: (context, viewModel, _) {
          return Column(
            children: [
              QuotaBanner(
                scansLeft: viewModel.scanResult?.quotaInfo.scansLeft ?? 5,
                isPremium: viewModel.scanResult?.quotaInfo.isPremium ?? false,
                onUpgrade: () => _navigateToPaywall(context),
              ),
              Expanded(
                child: _buildContent(context, viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScanViewModel viewModel) {
    switch (viewModel.state) {
      case ScanState.idle:
        return _buildIdleState(context, viewModel);
      case ScanState.scanning:
        return _buildScanningState(context);
      case ScanState.success:
        return _buildSuccessState(context, viewModel);
      case ScanState.error:
        return _buildErrorState(context, viewModel);
    }
  }

  Widget _buildIdleState(BuildContext context, ScanViewModel viewModel) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              isSpanish
                  ? 'Escanea tu recibo o factura'
                  : 'Scan your receipt or invoice',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSpanish
                  ? 'Extrae automáticamente la información importante'
                  : 'Automatically extract important information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildActionButtons(context, viewModel, isSpanish),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ScanViewModel viewModel,
    bool isSpanish,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _pickFromCamera(context, viewModel),
            icon: const Icon(Icons.camera_alt),
            label: Text(isSpanish ? 'Tomar foto' : 'Take photo'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickFromGallery(context, viewModel),
            icon: const Icon(Icons.photo_library),
            label: Text(isSpanish ? 'Desde galería' : 'From gallery'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _pickFromFile(context, viewModel),
            icon: const Icon(Icons.insert_drive_file),
            label: Text(isSpanish ? 'Seleccionar archivo' : 'Select file'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningState(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isSpanish = locale.startsWith('es');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            isSpanish ? 'Escaneando recibo...' : 'Scanning receipt...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, ScanViewModel viewModel) {
    // Navigate to result view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.scanResult != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultView(invoiceData: viewModel.scanResult!.invoiceData),
          ),
        );
        viewModel.reset();
      }
    });

    return _buildIdleState(context, viewModel);
  }

  Widget _buildErrorState(BuildContext context, ScanViewModel viewModel) {
    final locale = Localizations.localeOf(context).toString();
    final error = viewModel.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              error?.message ?? 'An error occurred',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.reset(),
              child: Text(locale.startsWith('es') ? 'Intentar de nuevo' : 'Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera(
    BuildContext context,
    ScanViewModel viewModel,
  ) async {
    final bytes = await InvoiceImagePicker.pickFromCamera();
    if (bytes != null) {
      final locale = Localizations.localeOf(context).toString();
      await viewModel.scanImage(bytes, locale);
    }
  }

  Future<void> _pickFromGallery(
    BuildContext context,
    ScanViewModel viewModel,
  ) async {
    final bytes = await InvoiceImagePicker.pickFromGallery();
    if (bytes != null) {
      final locale = Localizations.localeOf(context).toString();
      await viewModel.scanImage(bytes, locale);
    }
  }

  Future<void> _pickFromFile(
    BuildContext context,
    ScanViewModel viewModel,
  ) async {
    final bytes = await InvoiceImagePicker.pickFromFile();
    if (bytes != null) {
      final locale = Localizations.localeOf(context).toString();
      await viewModel.scanImage(bytes, locale);
    }
  }

  void _navigateToPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PaywallView(),
      ),
    );
  }
}


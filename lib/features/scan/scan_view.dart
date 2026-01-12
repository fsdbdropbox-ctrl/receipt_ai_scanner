import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_ai_scanner/features/scan/scan_view_model.dart';
import 'package:receipt_ai_scanner/features/result/result_view.dart';
import 'package:receipt_ai_scanner/features/paywall/paywall_view.dart';
import 'package:receipt_ai_scanner/core/file_picker/invoice_image_picker.dart';
import 'package:receipt_ai_scanner/core/locale/locale_provider.dart';
import 'package:receipt_ai_scanner/core/quota/quota_provider.dart';
import 'package:receipt_ai_scanner/shared/widgets/quota_banner.dart';
import 'package:receipt_ai_scanner/shared/widgets/language_selector.dart';
import 'package:receipt_ai_scanner/shared/widgets/pro_button.dart';
import 'package:receipt_ai_scanner/shared/utils/constants.dart';

class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanViewModel>(
      builder: (context, viewModel, _) {
        // Show fullscreen scanning state
        if (viewModel.state == ScanState.scanning) {
          return _buildScanningState(context);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            actions: [
              ProButton(onTap: () => _navigateToPaywall(context)),
              const LanguageSelector(),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Consumer<QuotaProvider>(
                builder: (context, quotaProvider, _) {
                  return QuotaBanner(
                    scansLeft: quotaProvider.scansLeft,
                    isPremium: quotaProvider.isPremium,
                    quotaInfo: quotaProvider.quotaInfo,
                    onUpgrade: () => _navigateToPaywall(context),
                  );
                },
              ),
              Expanded(
                child: _buildContent(context, viewModel),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ScanViewModel viewModel) {
    switch (viewModel.state) {
      case ScanState.idle:
        return _buildIdleState(context, viewModel);
      case ScanState.scanning:
        // Handled in build() for fullscreen experience
        return const SizedBox.shrink();
      case ScanState.success:
        return _buildSuccessState(context, viewModel);
      case ScanState.error:
        return _buildErrorState(context, viewModel);
    }
  }

  Widget _buildIdleState(BuildContext context, ScanViewModel viewModel) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isSpanish = localeProvider.isSpanish(context);

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
    // On desktop web, only show file picker (camera/gallery don't make sense)
    final isDesktopWeb = kIsWeb && MediaQuery.of(context).size.width > 600;
    
    if (isDesktopWeb) {
      // Desktop web: single button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _pickFromFile(context, viewModel),
          icon: const Icon(Icons.upload_file),
          label: Text(isSpanish ? 'Seleccionar archivo' : 'Select file'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      );
    }
    
    // Mobile: show all three options
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

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Receipt animation container
              Container(
                width: 200,
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Receipt lines
                    Positioned(
                      top: 32,
                      left: 24,
                      right: 24,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 56,
                      left: 24,
                      right: 80,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 24,
                      right: 100,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    // Scan line animation
                    const _ScanLineAnimation(),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                isSpanish ? 'Analizando recibo...' : 'Analyzing receipt...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSpanish ? 'Identificando vendedor y total' : 'Identifying vendor and total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context, ScanViewModel viewModel) {
    // Capture invoiceData BEFORE scheduling callback to avoid race condition
    final invoiceData = viewModel.scanResult?.invoiceData;
    final quotaInfo = viewModel.scanResult?.quotaInfo;
    
    // Navigate to result view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (invoiceData != null) {
        // Update quota provider with latest quota from scan response
        if (quotaInfo != null) {
          try {
            final quotaProvider = context.read<QuotaProvider>();
            quotaProvider.updateQuota(QuotaInfo.simple(
              scansLeft: quotaInfo.scansLeft,
              isPremium: quotaInfo.isPremium,
            ));
          } catch (_) {
            // Provider not available, skip quota update
          }
        }
        
        try {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResultView(invoiceData: invoiceData),
            ),
          );
        } catch (_) {
          // Navigation failed, skip
        }
        viewModel.reset();
      } else {
        // If invoiceData is null, treat as error
        viewModel.reset();
      }
    });

    return _buildIdleState(context, viewModel);
  }

  Widget _buildErrorState(BuildContext context, ScanViewModel viewModel) {
    // Use PlatformDispatcher instead of Localizations.localeOf to avoid crashes
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    final locale = locales.isNotEmpty ? locales.first : const Locale('en');
    final isSpanish = locale.languageCode == 'es';
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
              error?.message ?? (isSpanish ? 'Error desconocido' : 'An error occurred'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => viewModel.reset(),
              child: Text(isSpanish ? 'Intentar de nuevo' : 'Try again'),
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
    // Capture locale before async operation
    if (!context.mounted) return;
    final locale = Localizations.localeOf(context).toString();
    
    final bytes = await InvoiceImagePicker.pickFromCamera();
    if (bytes != null && context.mounted) {
      await viewModel.scanImage(bytes, locale);
    }
  }

  Future<void> _pickFromGallery(
    BuildContext context,
    ScanViewModel viewModel,
  ) async {
    // Capture locale before async operation
    if (!context.mounted) return;
    final locale = Localizations.localeOf(context).toString();
    
    final bytes = await InvoiceImagePicker.pickFromGallery();
    if (bytes != null && context.mounted) {
      await viewModel.scanImage(bytes, locale);
    }
  }

  Future<void> _pickFromFile(
    BuildContext context,
    ScanViewModel viewModel,
  ) async {
    // Capture locale before async operation
    if (!context.mounted) return;
    final locale = Localizations.localeOf(context).toString();
    
    final bytes = await InvoiceImagePicker.pickFromFile();
    if (bytes != null && context.mounted) {
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

/// Animated scan line for the scanning state
class _ScanLineAnimation extends StatefulWidget {
  const _ScanLineAnimation();

  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value * 220 + 20,
          left: 16,
          right: 16,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF2563EB).withOpacity(0.5),
                  Colors.white,
                  const Color(0xFF2563EB).withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


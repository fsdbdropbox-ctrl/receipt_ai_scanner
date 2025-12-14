import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:receipt_ai_scanner/shared/utils/constants.dart';
import 'package:receipt_ai_scanner/shared/models/scan_invoice_response.dart';
import 'package:receipt_ai_scanner/core/errors/scan_error.dart';
import 'package:receipt_ai_scanner/core/auth/installation_id_service.dart';
import 'package:receipt_ai_scanner/core/utils/image_mime_detector.dart';
import 'package:receipt_ai_scanner/core/utils/json_parser.dart';

class InvoiceScannerService {
  final InstallationIdService _installationIdService;
  final String _apiBaseUrl;

  InvoiceScannerService({
    required InstallationIdService installationIdService,
    String? apiBaseUrl,
  })  : _installationIdService = installationIdService,
        _apiBaseUrl = apiBaseUrl ?? AppConstants.apiBaseUrl;

  Future<ScanInvoiceResponse> scanInvoice(
    Uint8List imageBytes,
    String locale,
  ) async {
    final installId = await _installationIdService.getInstallationId();
    final mimeType = ImageMimeDetector.detectMimeType(imageBytes);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_apiBaseUrl/api/scan-invoice'),
    );

    request.headers['X-Install-Id'] = installId;
    request.fields['locale'] = locale;
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'receipt.jpg',
        contentType: mimeType != null
            ? http.MediaType.parse(mimeType)
            : http.MediaType('image', 'jpeg'),
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final errorBody = response.body.isNotEmpty
            ? (RobustJsonParser.tryParse(response.body) as Map<String, dynamic>?)
            : null;
        throw ScanError.fromApiResponse(response.statusCode, errorBody);
      }

      final json = RobustJsonParser.tryParse(response.body);
      if (json == null || json is! Map<String, dynamic>) {
        throw ScanError(
          code: ScanErrorCode.unknown,
          message: 'Invalid JSON response from server',
        );
      }
      return ScanInvoiceResponse.fromJson(json, response.body);
    } on ScanError {
      rethrow;
    } catch (e) {
      throw ScanError(
        code: ScanErrorCode.networkError,
        message: e.toString(),
      );
    }
  }
}


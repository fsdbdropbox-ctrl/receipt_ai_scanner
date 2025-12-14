import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for File - only used on mobile platforms (not web)
import 'dart:io' if (dart.library.html) 'file_picker_stub.dart' as io;

class InvoiceImagePicker {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<Uint8List?> pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return null;
    return await image.readAsBytes();
  }

  static Future<Uint8List?> pickFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return null;
    return await image.readAsBytes();
  }

  static Future<Uint8List?> pickFromFile() async {
    // Use withData: true for all platforms - file_picker handles it correctly
    final result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.image,
      withData: true,
    );
    
    if (result?.files.single.bytes != null) {
      return result!.files.single.bytes!;
    }
    
    // Fallback: if bytes not available but path is, read from path (mobile only)
    if (!kIsWeb && result?.files.single.path != null) {
      // Use File from dart:io (only available on mobile)
      final file = io.File(result!.files.single.path!);
      return await file.readAsBytes();
    }
    
    return null;
  }
}


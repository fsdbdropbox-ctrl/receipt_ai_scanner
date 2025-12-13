import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/foundation.dart' show kIsWeb;

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
    if (kIsWeb) {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.image,
        withData: true,
      );
      if (result?.files.single.bytes != null) {
        return result!.files.single.bytes!;
      }
      return null;
    } else {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.image,
      );
      if (result?.files.single.path != null) {
        final file = File(result!.files.single.path!);
        return await file.readAsBytes();
      }
      return null;
    }
  }
}


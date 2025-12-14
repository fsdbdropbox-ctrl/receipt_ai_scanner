import 'dart:typed_data';

// Stub file for web - File is not used when withData: true in file_picker
// This file is only imported on web where dart:io is not available
class File {
  File(String path) {
    throw UnsupportedError('File is not available on web');
  }
  
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('File.readAsBytes is not available on web');
  }
}


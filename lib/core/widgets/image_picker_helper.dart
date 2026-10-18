import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Pick or take a photo and shrink it BEFORE upload.
/// A raw phone photo is 4-8 MB; this gives roughly 200-400 KB, which keeps
/// us far inside the free Supabase storage limit (1 GB).
/// Returns null if the user cancels.
Future<Uint8List?> pickCompressedImage({ImageSource source = ImageSource.gallery}) async {
  final file = await ImagePicker().pickImage(
    source: source,
    imageQuality: 70,
    maxWidth: 1200,
  );
  return file?.readAsBytes();
}

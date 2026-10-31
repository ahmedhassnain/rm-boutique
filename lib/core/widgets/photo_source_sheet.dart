import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'image_picker_helper.dart';

/// Asks "gallery or camera?", then returns the chosen photo, already resized
/// and compressed. Returns null when the person cancels at either step.
Future<Uint8List?> pickPhotoWithSheet(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from the gallery'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  return pickCompressedImage(source: source);
}

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';

/// Image uploads and links. Bytes come from pickCompressedImage()
/// in lib/core/widgets/image_picker_helper.dart (already resized and compressed).
///
/// Files are stored as  <order_id>/proof.jpg  so the storage rules can check
/// that the file belongs to an order the user is allowed to touch.
class StorageRepository {
  StorageRepository({SupabaseClient? client}) : _db = client ?? supabase;
  final SupabaseClient _db;

  static const _jpeg = FileOptions(contentType: 'image/jpeg', upsert: true);

  /// Customer: attach the payment screenshot to an order (replaces an older
  /// one while it is still unverified).
  Future<void> uploadPaymentProof({
    required String orderId,
    required Uint8List bytes,
    double? amount,
  }) async {
    final path = '$orderId/proof.jpg';
    await _db.storage.from('payment-proofs').uploadBinary(path, bytes, fileOptions: _jpeg);
    // verified/flagged are sent explicitly: a replacement receipt must clear
    // the admin's "flagged" mark (the database only accepts a replacement
    // with flagged = false) and puts the payment back in the admin's
    // "To review" list.
    await _db.from('payments').upsert(
      {
        'order_id': orderId,
        'screenshot_path': path,
        'amount': amount,
        'verified': false,
        'flagged': false,
      },
      onConflict: 'order_id',
    );
  }

  /// Rider: photo proof, then the order becomes Delivered.
  Future<void> uploadDeliveryProof({
    required String orderId,
    required Uint8List bytes,
    String? notes,
  }) async {
    final path = '$orderId/proof.jpg';
    await _db.storage.from('delivery-photos').uploadBinary(path, bytes, fileOptions: _jpeg);
    await _db.from('deliveries').insert({
      'order_id': orderId,
      'rider_id': _db.auth.currentUser!.id,
      'photo_path': path,
      'notes': notes,
    });
    await _db.from('orders').update({'status': 'delivered'}).eq('id', orderId);
  }

  /// Admin: upload or replace a product photo, returns the stored path
  /// to save in products.image_path.
  Future<String> uploadProductImage(String productId, Uint8List bytes) async {
    final path = '$productId/main.jpg';
    await _db.storage.from('product-images').uploadBinary(path, bytes, fileOptions: _jpeg);
    return path;
  }

  /// Public link for a product photo (bucket is public).
  String productImageUrl(String path) =>
      _db.storage.from('product-images').getPublicUrl(path);

  /// Temporary link (1 hour) for a private image: a payment screenshot
  /// or a delivery photo. Bucket is 'payment-proofs' or 'delivery-photos'.
  Future<String> signedUrl(String bucket, String path) =>
      _db.storage.from(bucket).createSignedUrl(path, 3600);
}

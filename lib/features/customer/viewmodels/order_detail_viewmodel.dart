import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/image_picker_helper.dart';
import '../../../shared/models/order.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/storage_repository.dart';

/// OWNER: Maheen. One order: details + payment proof upload.
class OrderDetailViewModel extends ChangeNotifier {
  OrderDetailViewModel(this._orders, this._storage, this.orderId) {
    load();
    // When the admin verifies payment or the status changes, refresh live.
    _sub = _orders
        .watchOrder(orderId)
        .listen((_) => load(silent: true), onError: (_) {});
  }

  final OrderRepository _orders;
  final StorageRepository _storage;
  final String orderId;
  StreamSubscription? _sub;
  bool _disposed = false;

  Order? order;
  String? proofUrl;
  String? deliveryUrl;
  bool loading = true;
  bool uploading = false;
  String? error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      _notify();
    }
    try {
      order = await _orders.fetchOrder(orderId);
      final p = order!.payment;
      final d = order!.delivery;
      proofUrl =
          p == null ? null : await _signed('payment-proofs', p.screenshotPath);
      deliveryUrl =
          d == null ? null : await _signed('delivery-photos', d.photoPath);
    } catch (e) {
      if (!silent) error = 'Could not load this order.';
    }
    loading = false;
    _notify();
  }

  bool get canUploadProof {
    final p = order?.payment;
    return p == null || !p.verified;
  }

  Future<void> uploadProof() async {
    final bytes = await pickCompressedImage();
    if (bytes == null) return; // user cancelled
    uploading = true;
    error = null;
    _notify();
    try {
      await _storage.uploadPaymentProof(
        orderId: orderId,
        bytes: bytes,
        amount: order?.total,
      );
      await load(silent: true);
    } on StorageException catch (e) {
      error = e.message;
    } on PostgrestException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Upload failed. Please try again.';
    }
    uploading = false;
    _notify();
  }

  Future<String?> _signed(String bucket, String path) async {
    try {
      return await _storage.signedUrl(bucket, path);
    } catch (_) {
      return null; // a missing photo must not break the whole page
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}

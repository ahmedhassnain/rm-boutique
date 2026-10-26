import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/widgets/image_picker_helper.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/storage_repository.dart';

/// OWNER: rider. One delivery: address, customer, items, and the
/// photo-proof action that marks the order Delivered.
class DeliveryDetailViewModel extends ChangeNotifier {
  DeliveryDetailViewModel(this._orders, this._storage, this.orderId) {
    load();
    // Live refresh if the admin or this rider changes the order elsewhere.
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
  String? deliveryPhotoUrl;
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
      final delivery = order!.delivery;
      deliveryPhotoUrl = delivery == null
          ? null
          : await _storage.signedUrl('delivery-photos', delivery.photoPath);
    } catch (e) {
      if (!silent) error = 'Could not load this delivery.';
    }
    loading = false;
    _notify();
  }

  /// Only the step this rider is allowed to make: dispatched -> delivered,
  /// and only once (see OrderStatus.canBeAdvancedBy).
  bool get canMarkDelivered =>
      order != null &&
      order!.status.canBeAdvancedBy(UserRole.rider) &&
      !uploading;

  /// Takes a photo and marks the order delivered. [photoBytes] lets tests
  /// supply bytes directly instead of going through the real camera plugin;
  /// the screen always calls this with no arguments.
  Future<void> markDelivered({Uint8List? photoBytes}) async {
    final bytes =
        photoBytes ?? await pickCompressedImage(source: ImageSource.camera);
    if (bytes == null) return; // user cancelled
    uploading = true;
    error = null;
    _notify();
    try {
      await _storage.uploadDeliveryProof(orderId: orderId, bytes: bytes);
      await load(silent: true);
    } on StorageException catch (e) {
      error = e.message;
    } on PostgrestException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not upload the delivery photo. Please try again.';
    }
    uploading = false;
    _notify();
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

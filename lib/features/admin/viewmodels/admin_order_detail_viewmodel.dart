import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/order.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/order_status.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/storage_repository.dart';

/// OWNER: Ahmed (admin). One order seen by the admin: the status timeline,
/// payment check, rider assignment and the button that moves the order on.
///
/// The database is the real gatekeeper (see guard_order_update in
/// supabase/schema.sql). The checks below only exist so the screen can
/// explain WHY a button is switched off instead of failing with an error.
class AdminOrderDetailViewModel extends ChangeNotifier {
  AdminOrderDetailViewModel(this._orders, this._storage, this.orderId) {
    load();
    _loadRiders();
    _subs.add(_watch(_orders.watchOrder(orderId)));
    _subs.add(_watch(_orders.watchPayments()));
  }

  final OrderRepository _orders;
  final StorageRepository _storage;
  final String orderId;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _disposed = false;

  Order? order;
  List<Profile> riders = [];
  String? proofUrl; // payment receipt (temporary signed link)
  String? deliveryUrl; // rider's delivery photo (temporary signed link)

  bool loading = true;
  String? error; // the page could not load
  bool busy = false; // an action (approve, assign, advance...) is running
  String? actionError; // the last action failed: shown under the buttons

  StreamSubscription<dynamic> _watch(Stream<dynamic> stream) {
    var first = true;
    return stream.listen(
      (_) {
        if (first) {
          first = false;
          return;
        }
        load(silent: true);
      },
      onError: (_) {},
    );
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      _notify();
    }
    try {
      final o = await _orders.fetchOrder(orderId);
      order = o;
      proofUrl = o.payment == null
          ? null
          : await _signed('payment-proofs', o.payment!.screenshotPath);
      deliveryUrl = o.delivery == null
          ? null
          : await _signed('delivery-photos', o.delivery!.photoPath);
    } catch (_) {
      if (!silent) error = 'Could not load this order.';
    }
    loading = false;
    _notify();
  }

  Future<void> _loadRiders() async {
    try {
      riders = await _orders.fetchRiders();
      _notify();
    } catch (_) {
      // Not fatal: the rider section just says there are no riders.
    }
  }

  Future<String?> _signed(String bucket, String path) async {
    try {
      return await _storage.signedUrl(bucket, path);
    } catch (_) {
      return null; // a missing image must not break the whole page
    }
  }

  // ---------------- what the screen may offer ----------------

  /// The admin may only move orders that are confirmed, paid or packed.
  bool get adminCanMove =>
      order != null && order!.status.canBeAdvancedBy(UserRole.admin);

  /// Why the main button is off, or null when the next step is allowed.
  String? get advanceBlocker {
    final o = order;
    if (o == null) return null;
    switch (o.status) {
      case OrderStatus.confirmed:
        if (!(o.payment?.verified ?? false)) {
          return 'Approve the payment before marking this order as paid.';
        }
        return null;
      case OrderStatus.packed:
        if (!o.hasRider) return 'Assign a rider before dispatching.';
        return null;
      default:
        return null;
    }
  }

  bool get canAdvance => adminCanMove && advanceBlocker == null && !busy;

  /// Text of the main button: it names the step it will perform.
  String? get advanceLabel {
    switch (order?.status.next) {
      case OrderStatus.paid:
        return 'Mark as paid';
      case OrderStatus.packed:
        return 'Mark as packed';
      case OrderStatus.dispatched:
        return 'Dispatch to rider';
      default:
        return null; // dispatched/delivered: the rider's part, nothing to do
    }
  }

  /// A rider can be (re)assigned until the parcel is on its way.
  bool get canAssignRider => adminCanMove && !busy;

  // ---------------- actions ----------------

  Future<bool> approvePayment() =>
      _run(() => _orders.reviewPayment(orderId, approved: true));

  Future<bool> flagPayment() =>
      _run(() => _orders.reviewPayment(orderId, approved: false));

  Future<bool> assignRider(String riderId) =>
      _run(() => _orders.assignRider(orderId, riderId));

  Future<bool> advance() {
    final o = order;
    if (o == null || !canAdvance) return Future.value(false);
    return _run(() => _orders.advanceStatus(o));
  }

  /// Runs one action, reloads the order, and turns a database refusal into a
  /// readable message. Returns true when it worked.
  Future<bool> _run(Future<void> Function() action) async {
    busy = true;
    actionError = null;
    _notify();
    var ok = true;
    try {
      await action();
      await load(silent: true);
    } on PostgrestException catch (e) {
      actionError = e.message;
      ok = false;
    } catch (_) {
      actionError = 'Something went wrong. Please try again.';
      ok = false;
    }
    busy = false;
    _notify();
    return ok;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

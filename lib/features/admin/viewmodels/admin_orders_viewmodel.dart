import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/order.dart';
import '../../../shared/order_status.dart';
import '../../../shared/repositories/order_repository.dart';

/// The four filter chips on the admin "Manage orders" screen.
enum AdminOrderFilter {
  all('All'),
  needsAction('Needs action'),
  inTransit('In transit'),
  delivered('Delivered');

  const AdminOrderFilter(this.label);
  final String label;

  /// "Needs action" = every order that is waiting for the admin to move it
  /// (confirmed, paid or packed). Dispatched and delivered belong to the rider.
  bool matches(Order o) {
    switch (this) {
      case AdminOrderFilter.all:
        return true;
      case AdminOrderFilter.needsAction:
        return o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.paid ||
            o.status == OrderStatus.packed;
      case AdminOrderFilter.inTransit:
        return o.status == OrderStatus.dispatched;
      case AdminOrderFilter.delivered:
        return o.status == OrderStatus.delivered;
    }
  }
}

/// The four filter chips on the admin "Payments" screen.
enum AdminPaymentFilter {
  toReview('To review'),
  awaiting('No receipt yet'),
  flagged('Flagged'),
  verified('Verified');

  const AdminPaymentFilter(this.label);
  final String label;

  bool matches(Order o) {
    final p = o.payment;
    switch (this) {
      case AdminPaymentFilter.toReview:
        return p != null && !p.verified && !p.flagged;
      case AdminPaymentFilter.awaiting:
        return p == null && o.status == OrderStatus.confirmed;
      case AdminPaymentFilter.flagged:
        return p != null && p.flagged && !p.verified;
      case AdminPaymentFilter.verified:
        return p != null && p.verified;
    }
  }
}

/// OWNER: Ahmed (admin).
///
/// Holds every order for the admin screens (Manage orders, Payments, Riders
/// and the alert bell all read from this one object).
///
/// How it stays live: the repository's streams only tell us "something
/// changed". Each time one fires we reload the full list with
/// [OrderRepository.fetchOrders], because that version includes the customer's
/// name, the items and the payment, which the plain streams do not.
class AdminOrdersViewModel extends ChangeNotifier {
  AdminOrdersViewModel(this._orders) {
    load();
    _subs.add(_watch(_orders.watchOrders()));
    _subs.add(_watch(_orders.watchPayments()));
  }

  final OrderRepository _orders;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _disposed = false;
  int _loadCounter = 0;

  List<Order> orders = [];
  bool loading = true;
  String? error;

  AdminOrderFilter filter = AdminOrderFilter.all;
  String query = '';

  /// Reload when a stream fires. The first event every stream sends is just
  /// the current data, which [load] already fetched, so it is skipped.
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

  /// [silent] reloads without flashing the loading spinner (used for live
  /// updates and pull-to-refresh).
  Future<void> load({bool silent = false}) async {
    final myLoad = ++_loadCounter;
    if (!silent) {
      loading = true;
      error = null;
      _notify();
    }
    try {
      final rows = await _orders.fetchOrders();
      if (myLoad != _loadCounter) return; // a newer load is already running
      orders = rows;
      error = null;
    } catch (_) {
      if (myLoad != _loadCounter) return;
      if (!silent) {
        error = 'Could not load orders. Check your connection and try again.';
      }
    }
    loading = false;
    _notify();
  }

  void setFilter(AdminOrderFilter value) {
    filter = value;
    _notify();
  }

  void setQuery(String value) {
    query = value;
    _notify();
  }

  /// Orders shown on the main screen: the chosen chip AND the search text.
  List<Order> get visible {
    final q = query.trim().toLowerCase();
    return orders.where((o) {
      if (!filter.matches(o)) return false;
      if (q.isEmpty) return true;
      return o.id.toLowerCase().contains(q) ||
          (o.customerName ?? '').toLowerCase().contains(q) ||
          (o.customerPhone ?? '').toLowerCase().contains(q) ||
          o.deliveryAddress.toLowerCase().contains(q);
    }).toList();
  }

  /// Orders for one chip of the Payments screen.
  List<Order> paymentsFor(AdminPaymentFilter f) =>
      orders.where(f.matches).toList();

  int get needsActionCount =>
      orders.where(AdminOrderFilter.needsAction.matches).length;

  int get paymentsToReviewCount =>
      orders.where(AdminPaymentFilter.toReview.matches).length;

  int get urgentCount => orders.where((o) => o.isUrgent).length;

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

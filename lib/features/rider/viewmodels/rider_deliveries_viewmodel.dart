import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/order.dart';
import '../../../shared/order_status.dart';
import '../../../shared/repositories/order_repository.dart';

/// Placeholder flat fee per delivery, used only for the earnings total on
/// the History tab. Ask the group if there is a real figure to use (e.g. a
/// per-order fee column) before this goes in the final report.
const double kDeliveryFee = 15.0;

/// OWNER: rider. Live list of orders assigned to the signed-in rider
/// (Row Level Security already limits watchOrders() to just those), split
/// into what is still outstanding and what has already been delivered.
class RiderDeliveriesViewModel extends ChangeNotifier {
  RiderDeliveriesViewModel(this._orders) {
    _sub = _orders.watchOrders().listen(
      (rows) {
        orders = rows;
        loading = false;
        error = null;
        _notify();
      },
      onError: (e) {
        loading = false;
        error = 'Could not load your deliveries. Check your connection.';
        _notify();
      },
    );
  }

  final OrderRepository _orders;
  StreamSubscription<List<Order>>? _sub;
  bool _disposed = false;

  List<Order> orders = [];
  bool loading = true;
  String? error;

  /// Not yet delivered: what "My deliveries" shows.
  List<Order> get active =>
      orders.where((o) => o.status != OrderStatus.delivered).toList();

  /// Already delivered: what the History tab shows, most recent first.
  List<Order> get history {
    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).toList();
    delivered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return delivered;
  }

  double get earnings => history.length * kDeliveryFee;

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

import 'package:flutter/foundation.dart';

import '../../../shared/models/profile.dart';
import '../../../shared/repositories/order_repository.dart';

/// OWNER: Ahmed (admin). The list of riders on the "Riders" tab.
/// How many deliveries each rider has is worked out on screen from the
/// orders held by AdminOrdersViewModel, so this class only loads the people.
class AdminRidersViewModel extends ChangeNotifier {
  AdminRidersViewModel(this._orders) {
    load();
  }

  final OrderRepository _orders;
  bool _disposed = false;

  List<Profile> riders = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      riders = await _orders.fetchRiders();
    } catch (_) {
      error = 'Could not load riders. Check your connection and try again.';
    }
    loading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/cart_line.dart';
import '../../../shared/repositories/order_repository.dart';

/// Collects the delivery details and places the order through
/// OrderRepository.placeOrder. Stock and pricing are enforced by the database;
/// a readable message comes back if an item has run out.
class CheckoutViewModel extends ChangeNotifier {
  CheckoutViewModel(this._orders, this.variantId, this.quantity);

  final OrderRepository _orders;
  final String variantId;
  final int quantity;

  DateTime? neededBy;
  bool placing = false;
  String? error;

  void setNeededBy(DateTime? date) {
    neededBy = date;
    notifyListeners();
  }

  /// Returns the new order id on success, or null on failure (error is set).
  Future<String?> submit({required String address, String? notes}) async {
    placing = true;
    error = null;
    notifyListeners();
    try {
      final id = await _orders.placeOrder(
        address: address.trim(),
        items: [CartLine(variantId: variantId, quantity: quantity)],
        neededBy: neededBy,
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      );
      return id;
    } on PostgrestException catch (e) {
      // Readable messages from the database, e.g. "Not enough stock…".
      error = e.message;
      return null;
    } catch (_) {
      error =
          'Could not place the order. Please check your connection and try again.';
      return null;
    } finally {
      placing = false;
      notifyListeners();
    }
  }
}

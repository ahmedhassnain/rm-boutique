import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/cart_line.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/product_repository.dart';

/// One line of the order being typed in: which product, which size/colour,
/// and how many.
class DraftOrderLine {
  const DraftOrderLine({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final Product product;
  final ProductVariant variant;
  final int quantity;

  double get lineTotal => product.price * quantity;
}

/// OWNER: Ahmed (admin). "Add order": the admin picks a registered customer,
/// builds the basket (products, sizes, quantities) and saves it through the
/// database function admin_place_order (supabase/admin_orders.sql). Prices and
/// stock are handled by the database, exactly as for a customer's own order.
class AddOrderViewModel extends ChangeNotifier {
  AddOrderViewModel(this._products, this._orders) {
    load();
  }

  final ProductRepository _products;
  final OrderRepository _orders;
  bool _disposed = false;

  List<Product> products = [];
  List<Profile> customers = [];
  bool loading = true;
  String? error;

  Profile? customer;
  double? lat;
  double? lng;

  bool saving = false;
  String? saveError;

  final List<DraftOrderLine> _lines = [];
  List<DraftOrderLine> get lines => List.unmodifiable(_lines);

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      final all = await _products.fetchProducts();
      products = all.where((p) => p.isActive).toList();
      customers = await _orders.fetchCustomers();
    } catch (_) {
      error = 'Could not load the catalogue or the customers. Check your connection.';
    }
    loading = false;
    _notify();
  }

  void selectCustomer(Profile? value) {
    customer = value;
    _notify();
  }

  /// Called when the admin taps the map to pin the delivery spot (optional).
  void setLocation(double latitude, double longitude) {
    lat = latitude;
    lng = longitude;
    _notify();
  }

  /// Adds a line. The same size/colour added twice becomes one line, and the
  /// quantity never goes above the stock on the shelf.
  void addLine(Product product, ProductVariant variant, int quantity) {
    if (quantity <= 0) return;
    final index = _lines.indexWhere((l) => l.variant.id == variant.id);
    final already = index == -1 ? 0 : _lines[index].quantity;
    final wanted = already + quantity;
    final capped = wanted > variant.stock ? variant.stock : wanted;
    if (capped <= 0) return;
    final line = DraftOrderLine(
        product: product, variant: variant, quantity: capped);
    if (index == -1) {
      _lines.add(line);
    } else {
      _lines[index] = line;
    }
    _notify();
  }

  void removeLine(DraftOrderLine line) {
    _lines.remove(line);
    _notify();
  }

  double get total => _lines.fold(0.0, (sum, l) => sum + l.lineTotal);

  int get itemCount => _lines.fold(0, (sum, l) => sum + l.quantity);

  bool get canSave => customer != null && _lines.isNotEmpty && !saving;

  /// Saves the order. Returns the new order id, or null when it failed
  /// ([saveError] then says why, e.g. "Not enough stock for one of the items").
  Future<String?> save({
    required String address,
    DateTime? neededBy,
    String? notes,
  }) async {
    final who = customer;
    if (who == null || _lines.isEmpty) return null;
    saving = true;
    saveError = null;
    _notify();
    try {
      final id = await _orders.adminPlaceOrder(
        customerId: who.id,
        address: address.trim(),
        items: [
          for (final l in _lines)
            CartLine(variantId: l.variant.id, quantity: l.quantity),
        ],
        lat: lat,
        lng: lng,
        neededBy: neededBy,
        notes: (notes == null || notes.trim().isEmpty) ? null : notes.trim(),
      );
      _lines.clear();
      return id;
    } on PostgrestException catch (e) {
      saveError = e.message;
      return null;
    } catch (_) {
      saveError = 'Could not save the order. Check your connection and try again.';
      return null;
    } finally {
      saving = false;
      _notify();
    }
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

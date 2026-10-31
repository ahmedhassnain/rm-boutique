import 'package:flutter/foundation.dart';

import '../../../shared/models/cart_line.dart';

/// One size/colour of one product in the basket.
class CartItem {
  const CartItem({
    required this.variantId,
    required this.productName,
    required this.variantLabel,
    required this.unitPrice,
    required this.quantity,
    required this.maxQuantity,
    this.imagePath,
  });

  final String variantId;
  final String productName;
  final String variantLabel; // e.g. "Olive · M"
  final double unitPrice;
  final int quantity;
  final int maxQuantity; // stock when it was added; the database re-checks it
  final String? imagePath;

  double get lineTotal => unitPrice * quantity;

  CartItem withQuantity(int q) => CartItem(
        variantId: variantId,
        productName: productName,
        variantLabel: variantLabel,
        unitPrice: unitPrice,
        quantity: q,
        maxQuantity: maxQuantity,
        imagePath: imagePath,
      );

  CartLine toLine() => CartLine(variantId: variantId, quantity: quantity);
}

/// The customer's basket. One instance for the whole app (see main.dart); it
/// empties itself when a different person signs in. The database still has the
/// last word on price and stock when the order is placed (place_order).
class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _ownerId;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// Number of pieces (a quantity of 2 counts as 2), for the badge.
  int get count => _items.fold(0, (sum, i) => sum + i.quantity);

  double get total => _items.fold(0, (sum, i) => sum + i.lineTotal);

  /// Called when the signed-in person changes; a new person starts empty.
  void bindTo(String? userId) {
    if (userId == _ownerId) return;
    _ownerId = userId;
    // No notification: this runs while the app is rebuilding after a sign-in
    // or sign-out, when every customer screen is being replaced anyway.
    _items.clear();
  }

  /// Adds [item]. The same size/colour is merged into one line, capped at the
  /// stock that was available.
  void add(CartItem item) {
    final i = _items.indexWhere((e) => e.variantId == item.variantId);
    if (i == -1) {
      _items.add(item.withQuantity(item.quantity.clamp(1, item.maxQuantity)));
    } else {
      final merged = _items[i].quantity + item.quantity;
      _items[i] = _items[i].withQuantity(merged.clamp(1, _items[i].maxQuantity));
    }
    notifyListeners();
  }

  void setQuantity(String variantId, int quantity) {
    final i = _items.indexWhere((e) => e.variantId == variantId);
    if (i == -1) return;
    if (quantity <= 0) {
      _items.removeAt(i);
    } else {
      _items[i] = _items[i].withQuantity(quantity.clamp(1, _items[i].maxQuantity));
    }
    notifyListeners();
  }

  void remove(String variantId) => setQuantity(variantId, 0);

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}

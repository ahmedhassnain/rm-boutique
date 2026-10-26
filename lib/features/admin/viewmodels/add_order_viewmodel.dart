import 'package:flutter/foundation.dart';

import '../../../shared/models/product.dart';
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

/// OWNER: Ahmed (admin). The basket of the "Add order" screen: pick products,
/// sizes and quantities, and see the running total.
///
/// NOT SAVED YET: the database only lets a customer place an order
/// (place_order() refuses any other role). Saving an order the admin typed in
/// for a walk-in or Instagram customer needs a database change first, so this
/// class only builds the draft.
class AddOrderViewModel extends ChangeNotifier {
  AddOrderViewModel(this._products) {
    load();
  }

  final ProductRepository _products;
  bool _disposed = false;

  List<Product> products = [];
  bool loading = true;
  String? error;

  final List<DraftOrderLine> _lines = [];
  List<DraftOrderLine> get lines => List.unmodifiable(_lines);

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      final all = await _products.fetchProducts();
      products = all.where((p) => p.isActive).toList();
    } catch (_) {
      error = 'Could not load the catalogue. Check your connection.';
    }
    loading = false;
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

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

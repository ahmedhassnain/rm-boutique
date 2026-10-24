import 'package:flutter/foundation.dart';

import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';

/// Loads the catalogue for the customer browse screen.
/// A thin wrapper around ProductRepository.fetchProducts() that tracks
/// loading and error state so the screen stays simple.
class ProductsViewModel extends ChangeNotifier {
  ProductsViewModel(this._products);
  final ProductRepository _products;

  List<Product> items = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _products.fetchProducts();
    } catch (e) {
      error = 'Could not load products. Check your connection and try again.';
    }
    loading = false;
    notifyListeners();
  }
}

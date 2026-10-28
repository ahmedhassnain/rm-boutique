import 'package:flutter/foundation.dart';

import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';

/// How the catalogue is ordered.
enum ProductSort {
  featured,
  priceLowHigh,
  priceHighLow,
  nameAZ;

  String get label => switch (this) {
        ProductSort.featured => 'Featured',
        ProductSort.priceLowHigh => 'Price: low to high',
        ProductSort.priceHighLow => 'Price: high to low',
        ProductSort.nameAZ => 'Name: A to Z',
      };
}

/// Loads the catalogue for the customer browse screen and applies the
/// search box, the category tabs and the sort dropdown. The screen only
/// reads [visibleItems]; it never filters the list itself.
class ProductsViewModel extends ChangeNotifier {
  ProductsViewModel(this._products);
  final ProductRepository _products;

  List<Product> _all = [];
  bool loading = false;
  String? error;

  String query = '';
  String category = 'All';
  ProductSort sort = ProductSort.featured;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _all = await _products.fetchProducts();
    } catch (e) {
      error = 'Could not load products. Check your connection and try again.';
    }
    loading = false;
    notifyListeners();
  }

  /// True once at least one product has loaded, whatever the filters show.
  bool get hasProducts => _all.isNotEmpty;

  /// Category tabs: 'All' plus every category present in the catalogue.
  List<String> get categories {
    final names = <String>{for (final p in _all) p.category}.toList()..sort();
    return ['All', ...names];
  }

  /// Products after search + category + sort are applied.
  List<Product> get visibleItems {
    final q = query.trim().toLowerCase();
    final list = _all.where((p) {
      final inCategory = category == 'All' || p.category == category;
      final matches = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      return inCategory && matches;
    }).toList();

    switch (sort) {
      case ProductSort.priceLowHigh:
        list.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceHighLow:
        list.sort((a, b) => b.price.compareTo(a.price));
      case ProductSort.nameAZ:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ProductSort.featured:
        break; // keep the order the catalogue came in
    }
    return list;
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void clearQuery() {
    if (query.isEmpty) return;
    query = '';
    notifyListeners();
  }

  void selectCategory(String value) {
    if (category == value) return;
    category = value;
    notifyListeners();
  }

  void setSort(ProductSort value) {
    if (sort == value) return;
    sort = value;
    notifyListeners();
  }
}

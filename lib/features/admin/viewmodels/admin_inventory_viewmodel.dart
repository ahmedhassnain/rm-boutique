import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';

/// One size/colour that needs restocking, together with its product.
class StockAlert {
  const StockAlert(this.product, this.variant);
  final Product product;
  final ProductVariant variant;
}

/// The three filter chips on the admin "Inventory" screen.
enum AdminStockFilter {
  all('All'),
  low('Low stock'),
  soldOut('Sold out');

  const AdminStockFilter(this.label);
  final String label;

  bool matchesVariant(ProductVariant v) {
    switch (this) {
      case AdminStockFilter.all:
        return true;
      case AdminStockFilter.low:
        return v.isLow;
      case AdminStockFilter.soldOut:
        return !v.inStock;
    }
  }
}

/// OWNER: Ahmed (admin). The inventory sync engine: live stock for every
/// size and colour, low-stock alerts, and manual stock corrections.
///
/// Stock also drops by itself when a customer places an order (the database
/// does that inside place_order). The live stream below makes that change
/// show up here without a refresh.
class AdminInventoryViewModel extends ChangeNotifier {
  AdminInventoryViewModel(this._products) {
    load();
    var first = true;
    _sub = _products.watchVariants().listen(
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

  final ProductRepository _products;
  StreamSubscription<dynamic>? _sub;
  bool _disposed = false;
  int _loadCounter = 0;

  List<Product> products = [];
  bool loading = true;
  String? error;

  AdminStockFilter filter = AdminStockFilter.all;
  String query = '';

  /// Id of the size/colour being saved right now (to disable its buttons).
  String? savingVariantId;
  String? actionError;

  Future<void> load({bool silent = false}) async {
    final myLoad = ++_loadCounter;
    if (!silent) {
      loading = true;
      error = null;
      _notify();
    }
    try {
      final rows = await _products.fetchProducts();
      if (myLoad != _loadCounter) return;
      products = rows;
      error = null;
    } catch (_) {
      if (myLoad != _loadCounter) return;
      if (!silent) {
        error = 'Could not load the stock. Check your connection and try again.';
      }
    }
    loading = false;
    _notify();
  }

  void setFilter(AdminStockFilter value) {
    filter = value;
    _notify();
  }

  void setQuery(String value) {
    query = value;
    _notify();
  }

  /// Products matching the search text and the chosen chip.
  List<Product> get visibleProducts {
    final q = query.trim().toLowerCase();
    return products.where((p) {
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.category.toLowerCase().contains(q)) {
        return false;
      }
      if (filter == AdminStockFilter.all) return true;
      return p.variants.any(filter.matchesVariant);
    }).toList();
  }

  /// The sizes/colours to show under a product for the current chip.
  List<ProductVariant> variantsFor(Product p) => filter == AdminStockFilter.all
      ? p.variants
      : p.variants.where(filter.matchesVariant).toList();

  /// Everything that is sold out or at/below its alert level.
  List<StockAlert> get alerts {
    final result = <StockAlert>[];
    for (final p in products) {
      for (final v in p.variants) {
        if (!v.inStock || v.isLow) result.add(StockAlert(p, v));
      }
    }
    return result;
  }

  /// Saves a corrected stock number. Returns true when it worked.
  Future<bool> setStock(ProductVariant variant, int newStock) async {
    if (newStock < 0) return false;
    savingVariantId = variant.id;
    actionError = null;
    _notify();
    var ok = true;
    try {
      await _products.updateStock(variant.id, newStock);
      await load(silent: true);
    } on PostgrestException catch (e) {
      actionError = e.message;
      ok = false;
    } catch (_) {
      actionError = 'Could not save the stock. Please try again.';
      ok = false;
    }
    savingVariantId = null;
    _notify();
    return ok;
  }

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

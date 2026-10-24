import 'package:flutter/foundation.dart';

import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';

/// Loads one product and tracks the customer's size/colour/quantity choice.
/// The selected variant drives the live stock message and the checkout line.
class ProductDetailViewModel extends ChangeNotifier {
  ProductDetailViewModel(this._products, this.productId);

  final ProductRepository _products;
  final String productId;

  Product? product;
  bool loading = false;
  String? error;

  String? selectedColour;
  String? selectedSize;
  int quantity = 1;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      product = await _products.fetchProduct(productId);
      // Pre-select the first colour/size when there is only one obvious choice.
      if (colours.length == 1) selectedColour = colours.first;
    } catch (e) {
      error = 'Could not load this product. Please try again.';
    }
    loading = false;
    notifyListeners();
  }

  /// Distinct colours, in the order they first appear.
  List<String> get colours {
    final seen = <String>{};
    final out = <String>[];
    for (final v in product?.variants ?? const <ProductVariant>[]) {
      if (seen.add(v.colour)) out.add(v.colour);
    }
    return out;
  }

  /// Sizes available for the chosen colour (or all sizes if none chosen yet).
  List<String> get sizes {
    final seen = <String>{};
    final out = <String>[];
    for (final v in product?.variants ?? const <ProductVariant>[]) {
      if (selectedColour != null && v.colour != selectedColour) continue;
      if (seen.add(v.size)) out.add(v.size);
    }
    return out;
  }

  /// The variant matching the current colour + size, if both are chosen and
  /// that combination exists.
  ProductVariant? get selectedVariant {
    if (selectedColour == null || selectedSize == null) return null;
    for (final v in product?.variants ?? const <ProductVariant>[]) {
      if (v.colour == selectedColour && v.size == selectedSize) return v;
    }
    return null;
  }

  bool get canCheckout =>
      selectedVariant != null && selectedVariant!.inStock && quantity >= 1;

  void selectColour(String colour) {
    selectedColour = colour;
    // If the current size isn't offered in this colour, clear it.
    if (selectedSize != null && !sizes.contains(selectedSize)) {
      selectedSize = null;
    }
    quantity = 1;
    notifyListeners();
  }

  void selectSize(String size) {
    selectedSize = size;
    final stock = selectedVariant?.stock ?? 0;
    if (quantity > stock) quantity = stock > 0 ? stock : 1;
    notifyListeners();
  }

  void setQuantity(int q) {
    final max = selectedVariant?.stock ?? 1;
    if (q < 1) q = 1;
    if (q > max && max > 0) q = max;
    quantity = q;
    notifyListeners();
  }
}

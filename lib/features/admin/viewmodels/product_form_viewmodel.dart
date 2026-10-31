import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';
import '../../../shared/repositories/storage_repository.dart';

/// One size row of the "New product" form, exactly as typed.
class VariantInput {
  const VariantInput({this.size = '', this.colour = '', this.stock = '0'});
  final String size;
  final String colour;
  final String stock;
}

/// OWNER: Ahmed (admin). Checks and saves the product form: "Edit details"
/// for an existing product, "New product" for a new one (with its sizes and
/// opening stock, and an optional photo).
class ProductFormViewModel extends ChangeNotifier {
  ProductFormViewModel(this._products, this._storage, {this.editing});

  final ProductRepository _products;
  final StorageRepository _storage;

  /// The product being edited, or null when creating a new one.
  final Product? editing;

  bool saving = false;
  String? error;

  /// Set when the product was saved but something minor failed (the photo).
  String? warning;

  bool _disposed = false;

  bool get isNew => editing == null;

  static const colourWhenBlank = 'Standard';

  /// Parses "450", "450.50" or "450,50". Returns null when it is not a
  /// price above zero.
  static double? parsePrice(String text) {
    final price = double.tryParse(text.trim().replaceAll(',', '.'));
    if (price == null || price <= 0 || price > 100000) return null;
    return (price * 100).round() / 100;
  }

  /// Returns the first problem with the form, or null when it can be saved.
  /// [variants] is only checked for a new product.
  static String? validate({
    required String name,
    required String priceText,
    required String category,
    List<VariantInput> variants = const [],
    required bool isNew,
  }) {
    final n = name.trim();
    if (n.length < 2) return 'Enter the product name';
    if (n.length > 80) return 'The name is too long (80 characters at most)';
    if (parsePrice(priceText) == null) {
      return 'Enter a price above 0, for example 450';
    }
    if (category.trim().isEmpty) return 'Enter a category, for example Dresses';
    if (!isNew) return null;
    if (variants.isEmpty) return 'Add at least one size';
    final seen = <String>{};
    for (final v in variants) {
      if (v.size.trim().isEmpty) return 'Every size needs a name, for example M';
      final stock = int.tryParse(v.stock.trim());
      if (stock == null || stock < 0) {
        return 'Stock must be a whole number, 0 or more';
      }
      final colour = v.colour.trim().isEmpty ? colourWhenBlank : v.colour.trim();
      if (!seen.add('${v.size.trim().toLowerCase()}|${colour.toLowerCase()}')) {
        return 'The size ${v.size.trim()} ($colour) is listed twice';
      }
    }
    return null;
  }

  /// Saves the form. Returns true when the product was saved.
  Future<bool> save({
    required String name,
    required String priceText,
    required String description,
    required String category,
    required bool isActive,
    List<VariantInput> variants = const [],
    Uint8List? photo,
  }) async {
    if (saving) return false;
    error = null;
    warning = null;
    final problem = validate(
      name: name,
      priceText: priceText,
      category: category,
      variants: variants,
      isNew: isNew,
    );
    if (problem != null) {
      error = problem;
      _notify();
      return false;
    }

    saving = true;
    _notify();
    final price = parsePrice(priceText)!;
    String? createdId;
    try {
      final existing = editing;
      if (existing != null) {
        await _products.updateProduct(
          existing.id,
          name: name.trim(),
          description: description.trim(),
          category: category.trim(),
          price: price,
          isActive: isActive,
        );
        if (photo != null) {
          await _replacePhoto(existing.id, photo, existing.imagePath);
        }
      } else {
        createdId = await _products.createProduct(
          name: name.trim(),
          description: description.trim(),
          category: category.trim(),
          price: price,
          isActive: isActive,
        );
        await _products.addVariants(createdId, [
          for (final v in variants)
            (
              size: v.size.trim(),
              colour: v.colour.trim().isEmpty ? colourWhenBlank : v.colour.trim(),
              stock: int.parse(v.stock.trim()),
            )
        ]);
        if (photo != null) {
          try {
            await _replacePhoto(createdId, photo, null);
          } catch (_) {
            warning = 'The product was saved, but the photo could not be '
                'uploaded. Open it in Inventory and tap Change photo.';
          }
        }
      }
      return true;
    } on PostgrestException catch (e) {
      error = await _undoCreate(createdId, e.message);
      return false;
    } catch (_) {
      error = await _undoCreate(createdId,
          'Could not save the product. Check your connection and try again.');
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  /// A new product whose sizes failed to save is removed again, so the
  /// catalogue never keeps a product that cannot be bought.
  Future<String> _undoCreate(String? createdId, String message) async {
    if (createdId != null) {
      try {
        await _products.deleteProduct(createdId);
      } catch (_) {}
    }
    return message;
  }

  Future<void> _replacePhoto(String productId, Uint8List bytes, String? old) async {
    final path = await _storage.uploadProductImage(productId, bytes);
    await _products.setImagePath(productId, path);
    if (old != null && old.isNotEmpty && old != path) {
      try {
        await _storage.deleteProductImage(old);
      } catch (_) {}
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

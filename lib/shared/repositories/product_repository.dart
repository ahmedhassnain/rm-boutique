import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository({SupabaseClient? client}) : _db = client ?? supabase;
  final SupabaseClient _db;

  /// Catalogue with sizes/colours and live stock.
  /// Customers only see active products (enforced by the database).
  Future<List<Product>> fetchProducts() async {
    final rows = await _db
        .from('products')
        .select('*, product_variants(*)')
        .order('name');
    return rows.map<Product>(Product.fromJson).toList();
  }

  Future<Product> fetchProduct(String id) async {
    final row = await _db
        .from('products')
        .select('*, product_variants(*)')
        .eq('id', id)
        .single();
    return Product.fromJson(row);
  }

  /// Live stock for every size/colour. Emits again whenever any stock changes,
  /// so a sale in one place shows everywhere (the double-selling fix).
  Stream<List<ProductVariant>> watchVariants() => _db
      .from('product_variants')
      .stream(primaryKey: ['id']).map(
          (rows) => rows.map(ProductVariant.fromJson).toList());

  /// Admin only: points a product at its photo in the product-images bucket.
  Future<void> setImagePath(String productId, String path) async {
    await _db.from('products').update({'image_path': path}).eq('id', productId);
  }

  /// Admin only (the database refuses anyone else).
  Future<void> updateStock(String variantId, int stock) async {
    await _db.from('product_variants').update({'stock': stock}).eq('id', variantId);
  }

  /// Admin only: changes a product's text, price and visibility. Orders keep
  /// the price they were placed at (order_items.unit_price), so a new price
  /// only applies to orders placed from now on.
  Future<void> updateProduct(
    String id, {
    required String name,
    required String description,
    required String category,
    required double price,
    required bool isActive,
  }) async {
    await _db.from('products').update({
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'is_active': isActive,
    }).eq('id', id);
  }

  /// Admin only: creates a product and returns its id. Sizes are added
  /// with [addVariants] right after.
  Future<String> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required bool isActive,
  }) async {
    final row = await _db
        .from('products')
        .insert({
          'name': name,
          'description': description,
          'category': category,
          'price': price,
          'is_active': isActive,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Admin only: adds sizes/colours (with their opening stock) to a product.
  Future<void> addVariants(
    String productId,
    List<({String size, String colour, int stock})> variants,
  ) async {
    await _db.from('product_variants').insert([
      for (final v in variants)
        {
          'product_id': productId,
          'size': v.size,
          'colour': v.colour,
          'stock': v.stock,
        }
    ]);
  }

  /// Admin only: removes a product (and, by cascade, its sizes). Used to undo
  /// a half-finished "New product". A product that already has orders cannot
  /// be deleted; hide it instead.
  Future<void> deleteProduct(String id) async {
    await _db.from('products').delete().eq('id', id);
  }
}

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

  /// Admin only (the database refuses anyone else).
  Future<void> updateStock(String variantId, int stock) async {
    await _db.from('product_variants').update({'stock': stock}).eq('id', variantId);
  }
}

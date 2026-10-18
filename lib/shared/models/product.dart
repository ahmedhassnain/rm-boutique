class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.size,
    required this.colour,
    required this.stock,
    this.lowStockAt = 2,
  });

  final String id;
  final String productId;
  final String size;
  final String colour;
  final int stock;
  final int lowStockAt;

  bool get inStock => stock > 0;
  bool get isLow => stock > 0 && stock <= lowStockAt;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        size: json['size'] as String,
        colour: json['colour'] as String,
        stock: (json['stock'] as num).toInt(),
        lowStockAt: ((json['low_stock_at'] as num?) ?? 2).toInt(),
      );
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.category = 'Dresses',
    this.imagePath,
    this.isActive = true,
    this.variants = const [],
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double price;

  /// Path inside the public bucket `product-images`.
  /// Turn it into a URL with StorageRepository.productImageUrl.
  final String? imagePath;
  final bool isActive;
  final List<ProductVariant> variants;

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);

  /// Works with `select('*, product_variants(*)')`.
  factory Product.fromJson(Map<String, dynamic> json) {
    final raw = json['product_variants'];
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'Dresses',
      price: (json['price'] as num).toDouble(),
      imagePath: json['image_path'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      variants: raw is List
          ? raw
              .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

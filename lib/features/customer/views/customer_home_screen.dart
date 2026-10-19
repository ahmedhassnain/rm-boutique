import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/role_scaffold.dart';
import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../viewmodels/products_viewmodel.dart';

/// OWNER: Maheen.
/// Customer browse screen: the catalogue of products with live stock.
/// Tapping a product opens its detail page.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  static final _price = NumberFormat.currency(symbol: '₪', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ProductsViewModel(c.read<ProductRepository>())..load(),
      child: RoleScaffold(
        title: 'R&M Boutique',
        body: Consumer<ProductsViewModel>(
          builder: (context, vm, _) {
            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.error != null) {
              return _Message(text: vm.error!, onRetry: vm.load);
            }
            if (vm.items.isEmpty) {
              return const _Message(text: 'No products available yet.');
            }
            return RefreshIndicator(
              onRefresh: vm.load,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.62,
                ),
                itemCount: vm.items.length,
                itemBuilder: (context, i) => _ProductCard(product: vm.items[i]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageRepository>();
    final imageUrl = product.imagePath != null
        ? storage.productImageUrl(product.imagePath!)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/customer/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Photo(url: imageUrl),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _StockBadge(stock: product.totalStock),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CustomerHomeScreen._price.format(product.price),
                    style: const TextStyle(
                      color: AppColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        color: AppColors.sand,
        child: const Icon(Icons.checkroom, size: 40, color: AppColors.olive),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.sand,
        child: const Icon(Icons.broken_image, size: 36, color: AppColors.olive),
      ),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : Container(color: AppColors.sand),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color colour;
    if (stock <= 0) {
      label = 'Sold out';
      colour = AppColors.charcoal;
    } else if (stock <= 3) {
      label = 'Only $stock left';
      colour = AppColors.terracotta;
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ivory,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});
  final String text;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

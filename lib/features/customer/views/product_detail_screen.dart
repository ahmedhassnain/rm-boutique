import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/product_detail_viewmodel.dart';
import 'checkout_screen.dart';

/// OWNER: Maheen.
/// Product detail: shows the product, lets the customer pick a colour and size,
/// shows live stock for that choice, and continues to checkout.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  static final _price = NumberFormat.currency(symbol: '₪', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          ProductDetailViewModel(c.read<ProductRepository>(), productId)
            ..load(),
      child: Consumer<ProductDetailViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: Text(vm.product?.name ?? 'Product')),
            body: _body(context, vm),
            bottomNavigationBar:
                vm.product == null ? null : _checkoutBar(context, vm),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, ProductDetailViewModel vm) {
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: vm.load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    final p = vm.product!;
    final storage = context.read<StorageRepository>();
    final imageUrl =
        p.imagePath != null ? storage.productImageUrl(p.imagePath!) : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _Photo(url: imageUrl),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: AppTheme.display(size: 28)),
              const SizedBox(height: 4),
              Text(_price.format(p.price),
                  style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700)),
              if (p.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(p.description,
                    style: const TextStyle(
                        height: 1.4, color: AppColors.slate)),
              ],
              const SizedBox(height: 20),

              // Colour
              if (vm.colours.isNotEmpty) ...[
                const _Label('Colour'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in vm.colours)
                      ChoiceChip(
                        label: Text(c),
                        selected: vm.selectedColour == c,
                        onSelected: (_) => vm.selectColour(c),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Size + size guide link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Label('Size'),
                  TextButton(
                    onPressed: () => context.push('/customer/size-guide'),
                    child: const Text('Size guide'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in vm.sizes)
                    ChoiceChip(
                      label: Text(s),
                      selected: vm.selectedSize == s,
                      onSelected: (_) => vm.selectSize(s),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              _StockLine(
                  variant: vm.selectedVariant,
                  hasSize: vm.selectedSize != null),

              // Quantity
              if (vm.selectedVariant != null &&
                  vm.selectedVariant!.inStock) ...[
                const SizedBox(height: 20),
                const _Label('Quantity'),
                const SizedBox(height: 8),
                _QuantityStepper(
                  value: vm.quantity,
                  max: vm.selectedVariant!.stock,
                  onChanged: vm.setQuantity,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkoutBar(BuildContext context, ProductDetailViewModel vm) {
    final p = vm.product!;
    final v = vm.selectedVariant;
    final canBuy = vm.canCheckout && v != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: !canBuy
            ? ElevatedButton(
                onPressed: null,
                child: Text(v == null
                    ? 'Select size & colour'
                    : (v.inStock ? 'Proceed to checkout' : 'Sold out')),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Add to basket'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      onPressed: () {
                        context.read<CartViewModel>().add(CartItem(
                              variantId: v.id,
                              productName: p.name,
                              variantLabel: '${v.colour} · ${v.size}',
                              unitPrice: p.price,
                              quantity: vm.quantity,
                              maxQuantity: v.stock,
                              imagePath: p.imagePath,
                            ));
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text('${p.name} added to your basket'),
                            action: SnackBarAction(
                              label: 'View basket',
                              textColor: AppColors.accentOnDark,
                              onPressed: () => context.push('/customer/cart'),
                            ),
                          ));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push(
                        '/customer/checkout',
                        extra: CheckoutArgs.single(
                          variantId: v.id,
                          quantity: vm.quantity,
                          productName: p.name,
                          variantLabel: '${v.colour} · ${v.size}',
                          unitPrice: p.price,
                          imagePath: p.imagePath,
                        ),
                      ),
                      child: const Text('Buy now'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));
}

class _Photo extends StatelessWidget {
  const _Photo({this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: url == null
          ? Container(
              color: AppColors.tint,
              child:
                  const Icon(Icons.checkroom, size: 64, color: AppColors.ink),
            )
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.tint,
                child: const Icon(Icons.broken_image,
                    size: 48, color: AppColors.ink),
              ),
            ),
    );
  }
}

/// Live stock message for the chosen size/colour.
class _StockLine extends StatelessWidget {
  const _StockLine({required this.variant, required this.hasSize});
  final ProductVariant? variant;
  final bool hasSize;

  @override
  Widget build(BuildContext context) {
    if (variant == null) {
      return Text(
        hasSize
            ? 'That combination is unavailable.'
            : 'Choose a size to see availability.',
        style: const TextStyle(color: AppColors.muted),
      );
    }
    if (!variant!.inStock) {
      return const Text('Sold out',
          style: TextStyle(
              color: AppColors.slate, fontWeight: FontWeight.w600));
    }
    if (variant!.isLow) {
      return Text('Only ${variant!.stock} left',
          style: const TextStyle(
              color: AppColors.alert, fontWeight: FontWeight.w600));
    }
    return const Text('In stock',
        style: TextStyle(
            color: AppColors.statusDelivered, fontWeight: FontWeight.w600));
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper(
      {required this.value, required this.max, required this.onChanged});
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$value', style: const TextStyle(fontSize: 16)),
        ),
        IconButton.outlined(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

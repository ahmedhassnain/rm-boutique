import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_photo.dart';
import '../viewmodels/cart_viewmodel.dart';
import 'checkout_screen.dart';

/// The basket button for the app bar, with the number of pieces inside.
class BasketButton extends StatelessWidget {
  const BasketButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartViewModel, int>((c) => c.count);
    return IconButton(
      tooltip: 'Basket',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      onPressed: () => context.push('/customer/cart'),
    );
  }
}

/// OWNER: Ahmed (added for the basket). The customer's basket: change
/// quantities, remove things, then check out all of it as one order.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static final _price = NumberFormat.currency(symbol: '₪', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Basket')),
      body: cart.isEmpty
          ? const _EmptyBasket()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _CartRow(item: cart.items[i]),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  onPressed: () => context.push(
                    '/customer/checkout',
                    extra: CheckoutArgs.fromCart(
                      [for (final i in cart.items) CheckoutLine.fromCartItem(i)],
                    ),
                  ),
                  child: Text('Checkout · ${_price.format(cart.total)}'),
                ),
              ),
            ),
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  const _EmptyBasket();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                size: 48, color: AppColors.ink),
            const SizedBox(height: 16),
            const Text('Your basket is empty',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Add a few pieces from the shop and check out once.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => context.go('/customer'),
              child: const Text('Back to the shop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item});
  final CartItem item;

  static final _price = NumberFormat.currency(symbol: '₪', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartViewModel>();
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: AppSurface.shadowColor,
      surfaceTintColor: Colors.transparent,
      shape: AppSurface.card(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductPhoto(imagePath: item.imagePath, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(item.variantLabel,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StepButton(
                        icon: Icons.remove,
                        tooltip: 'One less',
                        onPressed: () => cart.setQuantity(
                            item.variantId, item.quantity - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${item.quantity}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        tooltip: 'One more',
                        onPressed: item.quantity >= item.maxQuantity
                            ? null
                            : () => cart.setQuantity(
                                item.variantId, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => cart.remove(item.variantId),
                ),
                Text(_price.format(item.lineTotal),
                    style: const TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton(
      {required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton.outlined(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

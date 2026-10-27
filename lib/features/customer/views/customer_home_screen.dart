import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/role_scaffold.dart';
import '../../../features/auth/auth_controller.dart';
import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../viewmodels/products_viewmodel.dart';

/// OWNER: Maheen.
/// Customer main page (matches the Part 1 wireframe): search bar with a
/// clear button, a sort dropdown, category tabs, a two-column grid of
/// product cards, and a four-item bottom bar. Tapping a product opens its
/// detail page.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ProductsViewModel(c.read<ProductRepository>())..load(),
      child: RoleScaffold(
        title: 'R&M Boutique',
        bottomNavigationBar: const _CustomerBottomBar(),
        body: const _Catalogue(),
      ),
    );
  }
}

/// The scrolling catalogue plus the header controls. Stateful only to own
/// the search box controller.
class _Catalogue extends StatefulWidget {
  const _Catalogue();

  @override
  State<_Catalogue> createState() => _CatalogueState();
}

class _CatalogueState extends State<_Catalogue> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductsViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null) {
          return _Message(text: vm.error!, onRetry: vm.load);
        }
        if (!vm.hasProducts) {
          return _Message(text: 'No products available yet.', onRetry: vm.load);
        }

        final items = vm.visibleItems;
        return Column(
          children: [
            _Header(vm: vm, controller: _search),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.load,
                child: items.isEmpty
                    ? ListView(
                        // ListView so pull-to-refresh still works when empty.
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'No products match your search.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) =>
                            _ProductCard(product: items[i]),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vm, required this.controller});
  final ProductsViewModel vm;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: vm.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: vm.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              vm.clearQuery();
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SortDropdown(vm: vm),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final name = vm.categories[i];
                return Align(
                  alignment: Alignment.center,
                  child: ChoiceChip(
                    label: Text(name),
                    selected: vm.category == name,
                    onSelected: (_) => vm.selectCategory(name),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.vm});
  final ProductsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductSort>(
          value: vm.sort,
          icon: const Icon(Icons.sort),
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          onChanged: (v) {
            if (v != null) vm.setSort(v);
          },
          items: [
            for (final s in ProductSort.values)
              DropdownMenuItem(value: s, child: Text(s.label)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  static final _price = NumberFormat.currency(symbol: '₪', decimalDigits: 0);

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
                    product.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _price.format(product.price),
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

/// Four-item bottom bar. "Shop" is the current screen; the others navigate.
class _CustomerBottomBar extends StatelessWidget {
  const _CustomerBottomBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        switch (i) {
          case 0:
            break; // already on the shop page
          case 1:
            context.push('/customer/size-guide');
          case 2:
            context.push('/customer/orders');
          case 3:
            _showAccountSheet(context);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Shop'),
        BottomNavigationBarItem(
            icon: Icon(Icons.straighten), label: 'Size guide'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), label: 'My orders'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Account'),
      ],
    );
  }

  void _showAccountSheet(BuildContext context) {
    final auth = context.read<AuthController>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.olive),
              title: Text(auth.profile?.fullName ?? 'My account'),
              subtitle: const Text('Signed in as a customer'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                auth.signOut();
              },
            ),
          ],
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/product.dart';
import '../viewmodels/admin_inventory_viewmodel.dart';
import 'widgets/admin_format.dart';
import 'widgets/filter_chips.dart';
import 'widgets/search_field.dart';

/// OWNER: Ahmed (admin). The inventory sync engine screen: every product with
/// its sizes and colours, live stock, low-stock warnings, and quick
/// corrections (- / + buttons, or tap the number to type an exact amount).
class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminInventoryViewModel>();
    final products = vm.visibleProducts;

    return RefreshIndicator(
      onRefresh: () => vm.load(silent: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchField(
                    hint: 'Search products',
                    onChanged: vm.setQuery,
                  ),
                  const SizedBox(height: 16),
                  FilterChips<AdminStockFilter>(
                    options: AdminStockFilter.values,
                    selected: vm.filter,
                    labelOf: (f) => f.label,
                    onSelected: vm.setFilter,
                  ),
                  if (vm.actionError != null) ...[
                    const SizedBox(height: 12),
                    Text(vm.actionError!,
                        style: const TextStyle(color: AppColors.terracotta)),
                  ],
                ],
              ),
            ),
          ),
          if (vm.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
            )
          else if (products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No products match.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ProductCard(product: products[i]),
                  ),
                  childCount: products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminInventoryViewModel>();
    final variants = vm.variantsFor(product);
    final needsRestock = product.variants.any((v) => !v.inStock || v.isLow);

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.sand, width: 1.5),
      ),
      child: Theme(
        // Removes the default divider lines of ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('stock-${product.id}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          title: Text(product.name,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${product.category}  ·  ${adminMoney.format(product.price)}  ·  '
            '${product.totalStock} in stock',
          ),
          trailing: needsRestock
              ? const Icon(Icons.warning_amber_rounded,
                  color: AppColors.terracotta)
              : const Icon(Icons.expand_more),
          children: [
            for (final v in variants) _VariantRow(variant: v),
          ],
        ),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({required this.variant});
  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminInventoryViewModel>();
    final saving = vm.savingVariantId == variant.id;

    final String? badge = !variant.inStock
        ? 'Sold out'
        : variant.isLow
            ? 'Low'
            : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${variant.size}  ·  ${variant.colour}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.terracotta,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(badge,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'One less',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: saving || variant.stock == 0
                ? null
                : () => vm.setStock(variant, variant.stock - 1),
          ),
          InkWell(
            onTap: saving ? null : () => _editExact(context, vm),
            child: Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('${variant.stock}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          IconButton(
            tooltip: 'One more',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline),
            onPressed:
                saving ? null : () => vm.setStock(variant, variant.stock + 1),
          ),
        ],
      ),
    );
  }

  Future<void> _editExact(
      BuildContext context, AdminInventoryViewModel vm) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _StockDialog(variant: variant),
    );
    if (value != null) await vm.setStock(variant, value);
  }
}

/// Asks for an exact stock number (for example after a delivery of 20 pieces).
class _StockDialog extends StatefulWidget {
  const _StockDialog({required this.variant});
  final ProductVariant variant;

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.variant.stock}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final n = int.tryParse(_controller.text.trim());
    if (n == null || n < 0) {
      setState(() => _error = 'Enter a whole number, 0 or more');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Stock: ${widget.variant.size} · ${widget.variant.colour}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Pieces in stock',
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

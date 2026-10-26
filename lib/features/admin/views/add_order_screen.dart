import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';
import '../viewmodels/add_order_viewmodel.dart';
import 'widgets/admin_format.dart';

/// OWNER: Ahmed (admin). "Add order": the admin types in an order that came
/// from the shop, Instagram or WhatsApp.
///
/// PREVIEW ONLY: the form and the basket work, but saving is switched off
/// until the database accepts orders from the admin (see AddOrderViewModel).
class AddOrderScreen extends StatelessWidget {
  const AddOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AddOrderViewModel(c.read<ProductRepository>()),
      child: const _AddOrderForm(),
    );
  }
}

class _AddOrderForm extends StatefulWidget {
  const _AddOrderForm();

  @override
  State<_AddOrderForm> createState() => _AddOrderFormState();
}

class _AddOrderFormState extends State<_AddOrderForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _neededBy;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool _canSave(AddOrderViewModel vm) =>
      _name.text.trim().isNotEmpty &&
      _address.text.trim().isNotEmpty &&
      vm.lines.isNotEmpty;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _neededBy ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _neededBy = picked);
  }

  Future<void> _addItem(AddOrderViewModel vm) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemPicker(
        products: vm.products,
        onAdd: (product, variant, qty) => vm.addLine(product, variant, qty),
      ),
    );
  }

  void _save() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Saving is not switched on yet'),
        content: const Text(
          'The database only accepts orders placed by customers. To save an '
          'order typed in by the admin, the team needs to add that to the '
          'database first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddOrderViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Preview: you can fill this in, but orders cannot be saved yet.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Customer name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Delivery address'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(_neededBy == null
                ? 'Needed by (optional)'
                : 'Needed by ${adminDate(_neededBy!)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text('Items',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              TextButton.icon(
                onPressed:
                    vm.loading || vm.error != null ? null : () => _addItem(vm),
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ],
          ),
          if (vm.loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (vm.error != null)
            Text(vm.error!)
          else if (vm.lines.isEmpty)
            const Text('No items yet.', style: TextStyle(color: Colors.black54))
          else ...[
            for (final line in vm.lines)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.product.name),
                subtitle: Text(
                    '${line.variant.size} · ${line.variant.colour} × ${line.quantity}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(adminMoney.format(line.lineTotal)),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                      onPressed: () => vm.removeLine(line),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(adminMoney.format(vm.total),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.sand)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: ElevatedButton(
              onPressed: _canSave(vm) ? _save : null,
              child: const Text('Save order'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet: choose a product, a size/colour and a quantity.
class _ItemPicker extends StatefulWidget {
  const _ItemPicker({required this.products, required this.onAdd});

  final List<Product> products;
  final void Function(Product product, ProductVariant variant, int quantity)
      onAdd;

  @override
  State<_ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<_ItemPicker> {
  // The dropdowns hold ids (plain strings), not whole objects: a dropdown
  // breaks if its value is not exactly one of its items.
  String? _productId;
  String? _variantId;
  int _quantity = 1;

  Product? get _product {
    for (final p in widget.products) {
      if (p.id == _productId) return p;
    }
    return null;
  }

  ProductVariant? get _variant {
    for (final v in _product?.variants ?? const <ProductVariant>[]) {
      if (v.id == _variantId) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final variant = _variant;
    final variants = product?.variants ?? const <ProductVariant>[];
    final maxQty = variant?.stock ?? 1;

    return Padding(
      // Lifts the sheet above the keyboard when it opens.
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add item',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          DropdownButton<String>(
            isExpanded: true,
            value: _productId,
            hint: const Text('Product'),
            items: [
              for (final p in widget.products)
                DropdownMenuItem<String>(value: p.id, child: Text(p.name)),
            ],
            onChanged: (id) => setState(() {
              _productId = id;
              _variantId = null;
              _quantity = 1;
            }),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: _variantId,
            hint: const Text('Size and colour'),
            items: [
              for (final v in variants)
                DropdownMenuItem<String>(
                  value: v.id,
                  enabled: v.inStock,
                  child: Text(
                    '${v.size} · ${v.colour}  '
                    '(${v.inStock ? '${v.stock} in stock' : 'sold out'})',
                  ),
                ),
            ],
            onChanged: product == null
                ? null
                : (id) => setState(() {
                      _variantId = id;
                      _quantity = 1;
                    }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Quantity'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Text('$_quantity',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: variant != null && _quantity < maxQty
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: product == null || variant == null
                ? null
                : () {
                    widget.onAdd(product, variant, _quantity);
                    Navigator.of(context).pop();
                  },
            child: const Text('Add to order'),
          ),
        ],
      ),
    );
  }
}

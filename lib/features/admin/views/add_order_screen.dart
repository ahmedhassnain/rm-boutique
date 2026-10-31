import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/location_picker_map.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../shared/models/product.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/product_repository.dart';
import '../viewmodels/add_order_viewmodel.dart';
import 'widgets/admin_format.dart';

/// OWNER: Ahmed (admin). "Add order": the admin types in an order that came
/// from the shop, Instagram or WhatsApp, for a customer who has an account.
/// Saving goes through the database function admin_place_order.
class AddOrderScreen extends StatelessWidget {
  const AddOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AddOrderViewModel(
        c.read<ProductRepository>(),
        c.read<OrderRepository>(),
      ),
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
  final _address = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _neededBy;

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool _canSave(AddOrderViewModel vm) =>
      vm.canSave && _address.text.trim().isNotEmpty;

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

  Future<void> _save(AddOrderViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final name = vm.customer?.fullName ?? 'the customer';
    final id = await vm.save(
      address: _address.text,
      neededBy: _neededBy,
      notes: _notes.text,
    );
    if (id == null || !mounted) return; // the reason shows on the screen
    messenger.showSnackBar(SnackBar(content: Text('Order saved for $name')));
    // Back to the orders list; the new order is already there (live list).
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddOrderViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CustomerPicker(vm: vm),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Delivery address'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          const Text('Pin the delivery spot (optional)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            vm.lat == null
                ? 'Tap the map so the rider sees it on their screen.'
                : 'Location pinned. Tap again to adjust.',
            style: TextStyle(
              fontSize: 13,
              color: vm.lat == null ? AppColors.muted : AppColors.statusDelivered,
            ),
          ),
          const SizedBox(height: 8),
          LocationPickerMap(
            onChanged: (LatLng point) =>
                vm.setLocation(point.latitude, point.longitude),
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
            const Text('No items yet.', style: TextStyle(color: AppColors.muted))
          else ...[
            for (final line in vm.lines)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    ProductPhoto(imagePath: line.product.imagePath, size: 44),
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
          if (vm.saveError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alert.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(vm.saveError!,
                  style: const TextStyle(color: AppColors.alert)),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.tint)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: ElevatedButton(
              onPressed: _canSave(vm) ? () => _save(vm) : null,
              child: vm.saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.canvas),
                    )
                  : Text(vm.lines.isEmpty
                      ? 'Save order'
                      : 'Save order · ${adminMoney.format(vm.total)}'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Which registered customer the order is for. The database needs a real
/// account to attach the order to, so the person has to have signed up.
class _CustomerPicker extends StatelessWidget {
  const _CustomerPicker({required this.vm});
  final AddOrderViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.loading) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Customer'),
        child: Text('Loading customers...'),
      );
    }
    if (vm.customers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'No customer accounts yet. A customer has to sign up in the app '
          'before an order can be added for them.',
        ),
      );
    }
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: vm.customer?.id,
      decoration: const InputDecoration(
        labelText: 'Customer',
        helperText: 'The customer needs an account in the app',
      ),
      items: [
        for (final c in vm.customers)
          DropdownMenuItem<String>(
            value: c.id,
            child: Text(
              c.phone == null || c.phone!.isEmpty
                  ? (c.fullName.isEmpty ? (c.email ?? 'Customer') : c.fullName)
                  : '${c.fullName.isEmpty ? (c.email ?? 'Customer') : c.fullName}  ·  ${c.phone}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) => vm.selectCustomer(
        id == null ? null : vm.customers.firstWhere((c) => c.id == id),
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

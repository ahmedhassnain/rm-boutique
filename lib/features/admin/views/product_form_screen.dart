import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/photo_source_sheet.dart';
import '../../../core/widgets/product_photo.dart';
import '../../../shared/models/product.dart';
import '../../../shared/repositories/product_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../viewmodels/product_form_viewmodel.dart';

/// OWNER: Ahmed (admin). One screen for both "Edit details" (name, category,
/// price, description, photo, visible to customers) and "New product" (the
/// same, plus the sizes with their opening stock). Stock of an existing
/// product is changed with the - / + buttons in Inventory.
/// Closes with `true` when something was saved, so Inventory reloads.
class ProductFormScreen extends StatelessWidget {
  const ProductFormScreen({super.key, this.product});

  /// The product to edit, or null to create a new one.
  final Product? product;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ProductFormViewModel(
        c.read<ProductRepository>(),
        c.read<StorageRepository>(),
        editing: product,
      ),
      child: _ProductForm(product: product),
    );
  }
}

class _SizeRow {
  final size = TextEditingController();
  final colour = TextEditingController();
  final stock = TextEditingController(text: '1');
  void dispose() {
    size.dispose();
    colour.dispose();
    stock.dispose();
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({required this.product});
  final Product? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _category =
      TextEditingController(text: widget.product?.category ?? 'Dresses');
  late final _price = TextEditingController(
      text: widget.product == null ? '' : _plain(widget.product!.price));
  late final _description =
      TextEditingController(text: widget.product?.description ?? '');
  late bool _active = widget.product?.isActive ?? true;
  final List<_SizeRow> _sizes = [_SizeRow()];
  Uint8List? _photo;

  bool get _isNew => widget.product == null;

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _description.dispose();
    for (final s in _sizes) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final bytes = await pickPhotoWithSheet(context);
    if (bytes != null && mounted) setState(() => _photo = bytes);
  }

  Future<void> _save() async {
    final vm = context.read<ProductFormViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final name = _name.text.trim();
    final ok = await vm.save(
      name: _name.text,
      priceText: _price.text,
      description: _description.text,
      category: _category.text,
      isActive: _active,
      variants: _isNew
          ? [
              for (final s in _sizes)
                VariantInput(
                    size: s.size.text, colour: s.colour.text, stock: s.stock.text)
            ]
          : const [],
      photo: _photo,
    );
    if (!ok) return;
    messenger.showSnackBar(SnackBar(
      content: Text(vm.warning ??
          (_isNew ? '$name added to the shop' : '$name updated')),
    ));
    router.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductFormViewModel>();
    final saving = vm.saving;
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New product' : 'Edit details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              _photo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.memory(_photo!,
                          width: 88, height: 88, fit: BoxFit.cover),
                    )
                  : ProductPhoto(
                      imagePath: widget.product?.imagePath, size: 88),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _pickPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: Text(_photo != null ||
                          (widget.product?.imagePath ?? '').isNotEmpty
                      ? 'Change photo'
                      : 'Add photo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            enabled: !saving,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _category,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _price,
                  enabled: !saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Price', prefixText: '₪ '),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            enabled: !saving,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Description', alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            onChanged: saving ? null : (v) => setState(() => _active = v),
            title: const Text('Show to customers'),
            subtitle: Text(_active
                ? 'Customers can see and order it'
                : 'Hidden from the shop. Existing orders are not affected'),
          ),
          if (!_isNew)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'A new price applies to new orders only. Orders already placed '
                'keep the price they were bought at.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          if (_isNew) ...[
            const SizedBox(height: 16),
            const Text('Sizes and stock',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            for (var i = 0; i < _sizes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _sizes[i].size,
                        enabled: !saving,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Size'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _sizes[i].colour,
                        enabled: !saving,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Colour', hintText: 'Standard'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _sizes[i].stock,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'In stock'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove this size',
                      onPressed: saving || _sizes.length == 1
                          ? null
                          : () => setState(() => _sizes.removeAt(i).dispose()),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: saving
                    ? null
                    : () => setState(() => _sizes.add(_SizeRow())),
                icon: const Icon(Icons.add),
                label: const Text('Add another size'),
              ),
            ),
          ],
          if (vm.error != null) ...[
            const SizedBox(height: 12),
            Text(vm.error!,
                style: const TextStyle(
                    color: AppColors.alert, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isNew ? 'Add product' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}

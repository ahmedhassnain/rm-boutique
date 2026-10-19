import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/repositories/order_repository.dart';
import '../viewmodels/checkout_viewmodel.dart';

/// Data passed from the product detail page into checkout.
class CheckoutArgs {
  const CheckoutArgs({
    required this.variantId,
    required this.quantity,
    required this.productName,
    required this.variantLabel,
    required this.unitPrice,
  });

  final String variantId;
  final int quantity;
  final String productName;
  final String variantLabel; // e.g. "Olive · M"
  final double unitPrice;
}

/// OWNER: Maheen.
/// Checkout: the customer confirms the item, enters a delivery address, an
/// optional needed-by date and notes, then places the order.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.args});
  final CheckoutArgs args;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  static final _price = NumberFormat.currency(symbol: '₪', decimalDigits: 0);

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    return ChangeNotifierProvider(
      create: (c) =>
          CheckoutViewModel(c.read<OrderRepository>(), a.variantId, a.quantity),
      child: Consumer<CheckoutViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _summary(a),
                  const SizedBox(height: 24),
                  const _Label('Delivery address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'House/unit, street, area, city',
                    ),
                    validator: (v) => (v == null || v.trim().length < 8)
                        ? 'Please enter a full delivery address'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  const _Label('Needed by (optional)'),
                  const SizedBox(height: 8),
                  _DateField(
                    date: vm.neededBy,
                    onPick: () => _pickDate(context, vm),
                    onClear: () => vm.setNeededBy(null),
                  ),
                  const SizedBox(height: 20),
                  const _Label('Notes (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Landmark, delivery instructions, anything else',
                    ),
                  ),
                  if (vm.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(vm.error!,
                          style: const TextStyle(color: AppColors.terracotta)),
                    ),
                  ],
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  onPressed: vm.placing ? null : () => _submit(context, vm),
                  child: vm.placing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.ivory),
                        )
                      : Text(
                          'Place order · ${_price.format(a.unitPrice * a.quantity)}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _summary(CheckoutArgs a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.checkroom, color: AppColors.olive),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${a.variantLabel}  ·  Qty ${a.quantity}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Text(_price.format(a.unitPrice * a.quantity),
                style: const TextStyle(
                    color: AppColors.terracotta, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, CheckoutViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.neededBy ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) vm.setNeededBy(picked);
  }

  Future<void> _submit(BuildContext context, CheckoutViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final id = await vm.submit(address: _address.text, notes: _notes.text);
    if (!context.mounted) return;
    if (id != null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order placed'),
          content: const Text(
              'Your order has been placed. Next, upload your payment proof so we can confirm it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      // Back to the customer home / orders.
      context.go('/customer');
    }
    // On failure the error is shown inline by the Consumer above.
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15));
}

class _DateField extends StatelessWidget {
  const _DateField(
      {required this.date, required this.onPick, required this.onClear});
  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'Select a date'
        : DateFormat('EEE, d MMM yyyy').format(date!);
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
          suffixIcon: date == null
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
        ),
        child: Text(label,
            style: TextStyle(
                color: date == null ? Colors.grey : AppColors.charcoal)),
      ),
    );
  }
}

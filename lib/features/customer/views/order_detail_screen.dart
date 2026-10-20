import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'order_tracking.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../viewmodels/order_detail_viewmodel.dart';

/// OWNER: Maheen. Order summary + payment proof upload.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => OrderDetailViewModel(
        c.read<OrderRepository>(),
        c.read<StorageRepository>(),
        orderId,
      ),
      child: Consumer<OrderDetailViewModel>(
        builder: (context, vm, _) {
          final money = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
          final o = vm.order;
          return Scaffold(
            appBar: AppBar(title: const Text('Order details')),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : o == null
                    ? Center(child: Text(vm.error ?? 'Order not found'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Order ${o.id.substring(0, 8)}',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                              ),
                              StatusChip(o.status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final i in o.items)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(i.productName ?? 'Item'),
                              subtitle: Text(
                                  '${i.size ?? ''} ${i.colour ?? ''} × ${i.quantity}'
                                      .trim()),
                              trailing: Text(money.format(i.lineTotal)),
                            ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              Text(money.format(o.total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Deliver to: ${o.deliveryAddress}'),
                          if (o.neededBy != null)
                            Text(
                                'Needed by: ${DateFormat.yMMMd().format(o.neededBy!)}'),
                          const SizedBox(height: 20),
                          OrderTracking(order: o, deliveryUrl: vm.deliveryUrl),
                          const SizedBox(height: 12),
                          _PaymentCard(vm: vm),
                        ],
                      ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.vm});
  final OrderDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = vm.order!.payment;
    final (String title, String hint, Color colour, IconData icon) = p == null
        ? (
            'Payment needed',
            'Pay by bank transfer, then upload a screenshot of the receipt.',
            AppColors.terracotta,
            Icons.upload_file
          )
        : p.verified
            ? (
                'Payment verified',
                'Thank you! We are preparing your order.',
                AppColors.olive,
                Icons.verified
              )
            : p.flagged
                ? (
                    'Payment problem',
                    'The amount or receipt did not match. Please upload a clear, correct screenshot.',
                    AppColors.terracotta,
                    Icons.error_outline
                  )
                : (
                    'Waiting for verification',
                    'We received your screenshot. The shop will check it soon.',
                    const Color(0xFF8A6D1F),
                    Icons.hourglass_top
                  );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: colour),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: colour)),
            ]),
            const SizedBox(height: 6),
            Text(hint),
            if (vm.proofUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  vm.proofUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 60,
                      child: Center(child: Text('Preview unavailable'))),
                ),
              ),
            ],
            if (vm.error != null) ...[
              const SizedBox(height: 8),
              Text(vm.error!, style: const TextStyle(color: Colors.red)),
            ],
            if (vm.canUploadProof) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: vm.uploading ? null : vm.uploadProof,
                  icon: vm.uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.photo_library),
                  label: Text(p == null
                      ? 'Upload payment screenshot'
                      : 'Replace screenshot'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

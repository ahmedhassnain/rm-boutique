import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/order_status.dart';

/// OWNER: Maheen. Status timeline + rider + delivery photo for one order.
class OrderTracking extends StatelessWidget {
  const OrderTracking({super.key, required this.order, this.deliveryUrl});
  final Order order;
  final String? deliveryUrl;

  static String _hint(OrderStatus s) => switch (s) {
        OrderStatus.confirmed => 'We received your order',
        OrderStatus.paid => 'Your payment was verified',
        OrderStatus.packed => 'Your items are packed',
        OrderStatus.dispatched => 'On the way to you',
        OrderStatus.delivered => 'Delivered',
      };

  @override
  Widget build(BuildContext context) {
    final current = order.status.index;
    final d = order.delivery;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order tracking',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            for (final s in OrderStatus.values)
              _Step(
                label: s.label,
                hint: _hint(s),
                done: s.index <= current,
                isCurrent: s.index == current,
                isLast: s == OrderStatus.values.last,
              ),
            if (order.hasRider) ...[
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.delivery_dining, color: AppColors.ink),
                title: Text(order.riderName ?? 'Rider assigned'),
                subtitle: Text(order.riderPhone ?? 'Your rider'),
              ),
            ],
            if (d != null) ...[
              const Divider(height: 24),
              Text(
                  'Delivered on ${DateFormat.yMMMd().add_jm().format(d.deliveredAt.toLocal())}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (d.notes != null && d.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Rider note: ${d.notes}'),
              ],
              if (deliveryUrl != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    deliveryUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                        height: 60,
                        child: Center(child: Text('Photo unavailable'))),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.hint,
    required this.done,
    required this.isCurrent,
    required this.isLast,
  });
  final String label;
  final String hint;
  final bool done;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colour = done ? AppColors.ink : AppColors.hairline;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: colour, size: 22),
              if (!isLast) Expanded(child: Container(width: 2, color: colour)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: done ? null : AppColors.muted)),
                  if (isCurrent)
                    Text(hint, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

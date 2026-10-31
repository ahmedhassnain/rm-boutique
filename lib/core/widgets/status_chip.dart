import 'package:flutter/material.dart';

import '../../shared/order_status.dart';
import '../theme/app_theme.dart';

/// Coloured label for an order status. Use it everywhere a status is shown
/// so all three roles see the same thing. The chip is a soft tint of the
/// status colour with the same colour as text, so a list of orders stays calm
/// and the status is still readable at a glance.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final OrderStatus status;

  Color get _colour => switch (status) {
        OrderStatus.confirmed => AppColors.alert,
        OrderStatus.paid => AppColors.statusPaid,
        OrderStatus.packed => AppColors.statusPacked,
        OrderStatus.dispatched => AppColors.statusDispatched,
        OrderStatus.delivered => AppColors.statusDelivered,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: _colour, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

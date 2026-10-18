import 'package:flutter/material.dart';

import '../../shared/order_status.dart';
import '../theme/app_theme.dart';

/// Coloured label for an order status. Use it everywhere a status is shown
/// so all three roles see the same thing.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final OrderStatus status;

  Color get _colour => switch (status) {
        OrderStatus.confirmed => AppColors.terracotta,
        OrderStatus.paid => const Color(0xFF8A6D1F),
        OrderStatus.packed => const Color(0xFF4B5148),
        OrderStatus.dispatched => const Color(0xFF2F5D8A),
        OrderStatus.delivered => AppColors.olive,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _colour,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

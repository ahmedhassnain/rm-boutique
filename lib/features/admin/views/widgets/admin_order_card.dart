import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../shared/models/order.dart';
import 'admin_format.dart';

/// One order in the list: picture box on the left, order name, customer and
/// address in the middle, status label top right (the "record card" of the
/// wireframe). Tapping it opens the order detail.
class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.sand, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Picture slot. Real product photos come in the UI/UX phase.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.sand),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.checkroom_outlined,
                        color: AppColors.olive),
                    if (count > 0)
                      Text(
                        count == 1 ? '1 item' : '$count items',
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            adminOrderLabel(order),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(order.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.customerName ?? 'Customer'}  ·  '
                      '${adminMoney.format(order.total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    if (order.isUrgent)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.flag,
                                size: 14, color: AppColors.terracotta),
                            const SizedBox(width: 4),
                            Text(
                              'Needed by ${adminDate(order.neededBy!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

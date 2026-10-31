import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/product_photo.dart';
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
      elevation: 2,
      shadowColor: AppSurface.shadowColor,
      surfaceTintColor: Colors.transparent,
      shape: AppSurface.card(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The photo of the first item, with the item count over it.
              ProductPhoto(
                imagePath:
                    order.items.isEmpty ? null : order.items.first.imagePath,
                size: 64,
                badge: count > 0 ? (count == 1 ? '1 item' : '$count items') : null,
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
                      style: const TextStyle(color: AppColors.slate),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    if (order.isUrgent)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.flag,
                                size: 14, color: AppColors.alert),
                            const SizedBox(width: 4),
                            Text(
                              'Needed by ${adminDate(order.neededBy!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.alert,
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

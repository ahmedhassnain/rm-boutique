import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/order_status.dart';
import '../viewmodels/admin_orders_viewmodel.dart';
import '../viewmodels/admin_riders_viewmodel.dart';

/// OWNER: Ahmed (admin). Who the riders are and how busy each one is.
/// (Assigning a rider happens on the order itself.)
class RidersTab extends StatelessWidget {
  const RidersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final riders = context.watch<AdminRidersViewModel>();
    final orders = context.watch<AdminOrdersViewModel>();

    if (riders.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (riders.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(riders.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: riders.load, child: const Text('Try again')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: riders.load,
      child: riders.riders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No riders yet. A rider appears here once they have signed '
                    'up and been given the rider role.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: riders.riders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final rider = riders.riders[i];
                final mine =
                    orders.orders.where((o) => o.riderId == rider.id).toList();
                final active = mine
                    .where((o) => o.status != OrderStatus.delivered)
                    .length;
                final done = mine.length - active;
                return _RiderCard(rider: rider, active: active, delivered: done);
              },
            ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({
    required this.rider,
    required this.active,
    required this.delivered,
  });

  final Profile rider;
  final int active;
  final int delivered;

  @override
  Widget build(BuildContext context) {
    final name = rider.fullName.isEmpty ? (rider.email ?? 'Rider') : rider.fullName;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.sand, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.olive,
              foregroundColor: AppColors.ivory,
              child: Text(name.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (rider.phone != null && rider.phone!.isNotEmpty)
                    Text(rider.phone!,
                        style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$active active',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: active > 0 ? AppColors.terracotta : AppColors.olive,
                    )),
                Text('$delivered delivered',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

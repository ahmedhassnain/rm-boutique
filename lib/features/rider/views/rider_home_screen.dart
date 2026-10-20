import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/role_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/order.dart';
import '../../../shared/repositories/order_repository.dart';
import '../viewmodels/rider_deliveries_viewmodel.dart';

/// OWNER: rider. "My deliveries" (active, not yet delivered) and
/// "History" (delivered, with an earnings total) as two tabs.
class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => RiderDeliveriesViewModel(c.read<OrderRepository>()),
      child: DefaultTabController(
        length: 2,
        child: RoleScaffold(
          title: 'My deliveries',
          body: Column(
            children: [
              const Material(
                color: AppColors.olive,
                child: TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'Deliveries'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<RiderDeliveriesViewModel>(
                  builder: (context, vm, _) {
                    if (vm.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vm.error != null) {
                      return Center(
                          child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(vm.error!, textAlign: TextAlign.center),
                      ));
                    }
                    return TabBarView(
                      children: [
                        _DeliveriesList(
                          orders: vm.active,
                          emptyText: 'No deliveries assigned to you',
                        ),
                        _HistoryTab(vm: vm),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveriesList extends StatelessWidget {
  const _DeliveriesList({required this.orders, required this.emptyText});
  final List<Order> orders;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return Center(child: Text(emptyText));
    final money = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final o = orders[i];
        return Card(
          child: ListTile(
            onTap: () => context.go('/rider/delivery/${o.id}'),
            title: Text(
                'Order ${o.id.substring(0, 8)}  ·  ${money.format(o.total)}'),
            subtitle: Text(o.deliveryAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: StatusChip(o.status),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.vm});
  final RiderDeliveriesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${vm.history.length} delivered',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Earnings: ${money.format(vm.earnings)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.olive)),
            ],
          ),
        ),
        Expanded(
          child: _DeliveriesList(
            orders: vm.history,
            emptyText: 'Nothing delivered yet',
          ),
        ),
      ],
    );
  }
}

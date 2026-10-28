import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/admin_orders_viewmodel.dart';
import 'widgets/admin_order_card.dart';
import 'widgets/filter_chips.dart';
import 'widgets/search_field.dart';
import 'widgets/summary_tile.dart';

/// OWNER: Ahmed (admin). The "Manage orders" screen: the order command centre.
/// Top to bottom this follows the admin wireframe in the proposal: search bar,
/// four filter buttons in a 2 x 2 grid, two summary blocks and the order list.
/// The small "+" (Add order) button belongs to the frame, see
/// admin_home_screen.dart.
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key, required this.onOpenTab});

  /// Switches the bottom navigation to another tab (0 orders, 1 payments,
  /// 2 inventory, 3 inbox).
  final void Function(int index) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminOrdersViewModel>();
    final orders = vm.visible;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => vm.load(silent: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SearchField(
                          hint: 'Search order, customer or address',
                          onChanged: vm.setQuery,
                        ),
                        const SizedBox(height: 16),
                        FilterChips<AdminOrderFilter>(
                          options: AdminOrderFilter.values,
                          selected: vm.filter,
                          labelOf: (f) => f.label,
                          onSelected: vm.setFilter,
                          twoColumns: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SummaryTile(
                                value: '${vm.needsActionCount}',
                                label: 'Need action',
                                warn: vm.needsActionCount > 0,
                                onTap: () =>
                                    vm.setFilter(AdminOrderFilter.needsAction),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SummaryTile(
                                value: '${vm.paymentsToReviewCount}',
                                label: 'Payments to review',
                                warn: vm.paymentsToReviewCount > 0,
                                onTap: () => onOpenTab(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          vm.filter == AdminOrderFilter.all
                              ? 'All orders'
                              : vm.filter.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (vm.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (vm.error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(text: vm.error!, onRetry: vm.load),
                  )
                else if (orders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Message(
                      text: vm.orders.isEmpty
                          ? 'No orders yet. New orders appear here the moment a customer places one.'
                          : 'No orders match this filter or search.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AdminOrderCard(
                            order: orders[i],
                            onTap: () =>
                                context.push('/admin/order/${orders[i].id}'),
                          ),
                        ),
                        childCount: orders.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

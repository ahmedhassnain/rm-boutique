import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/order.dart';
import '../viewmodels/admin_orders_viewmodel.dart';
import 'widgets/admin_format.dart';
import 'widgets/filter_chips.dart';

/// OWNER: Ahmed (admin). The payment verification panel: every order grouped
/// by what its payment needs. Tapping a card opens the order, where the
/// receipt image is shown and the payment is approved or flagged.
class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  AdminPaymentFilter _filter = AdminPaymentFilter.toReview;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminOrdersViewModel>();
    final list = vm.paymentsFor(_filter);

    return RefreshIndicator(
      onRefresh: () => vm.load(silent: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: FilterChips<AdminPaymentFilter>(
                options: AdminPaymentFilter.values,
                selected: _filter,
                labelOf: (f) => '${f.label} (${vm.paymentsFor(f).length})',
                onSelected: (f) => setState(() => _filter = f),
                twoColumns: true,
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
              child: Center(child: Text(vm.error!, textAlign: TextAlign.center)),
            )
          else if (list.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Nothing in this list.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentCard(order: list[i]),
                  ),
                  childCount: list.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final p = order.payment;
    final amount = p?.amount;
    final mismatch = amount != null && (amount - order.total).abs() > 0.01;

    final String label;
    final Color colour;
    if (p == null) {
      label = 'No receipt';
      colour = AppColors.muted;
    } else if (p.verified) {
      label = 'Verified';
      colour = AppColors.statusDelivered;
    } else if (p.flagged) {
      label = 'Flagged';
      colour = AppColors.alert;
    } else {
      label = 'To review';
      colour = AppColors.statusPaid;
    }

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: AppSurface.shadowColor,
      surfaceTintColor: Colors.transparent,
      shape: AppSurface.card(),
      child: InkWell(
        onTap: () => context.push('/admin/order/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.tint),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminOrderLabel(order),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerName ?? 'Customer'}  ·  '
                      'Order total ${adminMoney.format(order.total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (amount != null)
                      Text(
                        'Receipt shows ${adminMoney.format(amount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: mismatch ? AppColors.alert : AppColors.muted,
                          fontWeight:
                              mismatch ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    if (mismatch)
                      const Text(
                        'Amount does not match the order total',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.alert),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colour,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/order_status.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../viewmodels/admin_order_detail_viewmodel.dart';
import 'widgets/admin_format.dart';

/// OWNER: Ahmed (admin). One order, start to finish: the status timeline, the
/// items, the payment receipt (approve or flag), the rider, the delivery
/// photo, and the button that moves the order to its next step.
class AdminOrderDetailScreen extends StatelessWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AdminOrderDetailViewModel(
        c.read<OrderRepository>(),
        c.read<StorageRepository>(),
        orderId,
      ),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminOrderDetailViewModel>();
    final o = vm.order;

    return Scaffold(
      appBar: AppBar(title: Text(o == null ? 'Order' : adminOrderLabel(o))),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : o == null
              ? Center(child: Text(vm.error ?? 'Order not found'))
              : RefreshIndicator(
                  onRefresh: () => vm.load(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _Summary(order: o),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'Progress',
                        child: _Timeline(status: o.status),
                      ),
                      const SizedBox(height: 12),
                      _Section(title: 'Items', child: _Items(order: o)),
                      const SizedBox(height: 12),
                      _Section(title: 'Payment', child: _PaymentPanel(vm: vm)),
                      const SizedBox(height: 12),
                      _Section(title: 'Rider', child: _RiderPanel(vm: vm)),
                      if (vm.deliveryUrl != null && o.delivery != null) ...[
                        const SizedBox(height: 12),
                        _Section(
                          title: 'Proof of delivery',
                          child: _DeliveryProof(vm: vm),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
      bottomNavigationBar: o == null ? null : _ActionBar(vm: vm),
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.sand, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Customer, address, needed-by date and notes.
class _Summary extends StatelessWidget {
  const _Summary({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.sand, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName ?? 'Customer',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
                StatusChip(order.status),
              ],
            ),
            if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
              Text(order.customerPhone!,
                  style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.place_outlined, text: order.deliveryAddress),
            _InfoRow(
              icon: Icons.event_outlined,
              text: 'Placed ${adminDateTime(order.createdAt)}',
            ),
            if (order.neededBy != null)
              _InfoRow(
                icon: order.isUrgent ? Icons.flag : Icons.flag_outlined,
                text: 'Needed by ${adminDate(order.neededBy!)}',
                colour: order.isUrgent ? AppColors.terracotta : null,
              ),
            if (order.notes != null && order.notes!.isNotEmpty)
              _InfoRow(icon: Icons.sticky_note_2_outlined, text: order.notes!),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text, this.colour});
  final IconData icon;
  final String text;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colour ?? AppColors.olive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: colour,
                    fontWeight:
                        colour == null ? FontWeight.normal : FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// The five steps of the agreed order flow, with who performs each one.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final OrderStatus status;

  String _who(int index) {
    if (index == 0) return 'Customer placed the order';
    // The person who moves an order INTO a step is the one who moves it OUT
    // of the step before it.
    final role = OrderStatus.values[index - 1].movedBy;
    return role == UserRole.rider ? 'Rider' : 'You';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in OrderStatus.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(
                  s.index < status.index
                      ? Icons.check_circle
                      : s.index == status.index
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                  size: 22,
                  color: s.index <= status.index
                      ? AppColors.olive
                      : Colors.black26,
                ),
                const SizedBox(width: 10),
                Text(
                  s.label,
                  style: TextStyle(
                    fontWeight: s.index == status.index
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: s.index > status.index ? Colors.black45 : null,
                  ),
                ),
                const Spacer(),
                Text(_who(s.index),
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) {
      return const Text('No items to show.');
    }
    return Column(
      children: [
        for (final i in order.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.productName ?? 'Item',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '${i.size ?? ''} ${i.colour ?? ''} × ${i.quantity}'
                            .trim(),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(adminMoney.format(i.lineTotal)),
              ],
            ),
          ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text(adminMoney.format(order.total),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Payment verification
// ---------------------------------------------------------------------------

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.vm});
  final AdminOrderDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final order = vm.order!;
    final p = order.payment;

    if (p == null) {
      return const Row(
        children: [
          Icon(Icons.hourglass_top, color: Colors.black45),
          SizedBox(width: 10),
          Expanded(child: Text('Waiting for the customer to upload a receipt.')),
        ],
      );
    }

    final amount = p.amount;
    final mismatch = amount != null && (amount - order.total).abs() > 0.01;

    final String statusText;
    final Color statusColour;
    final IconData statusIcon;
    if (p.verified) {
      statusText = 'Payment verified';
      statusColour = AppColors.olive;
      statusIcon = Icons.verified;
    } else if (p.flagged) {
      statusText = 'Flagged as a mismatch';
      statusColour = AppColors.terracotta;
      statusIcon = Icons.error_outline;
    } else {
      statusText = 'Waiting for your review';
      statusColour = const Color(0xFF8A6D1F);
      statusIcon = Icons.hourglass_top;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(statusIcon, color: statusColour),
            const SizedBox(width: 10),
            Text(statusText,
                style: TextStyle(
                    color: statusColour, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount == null
              ? 'Order total ${adminMoney.format(order.total)}'
              : 'Receipt shows ${adminMoney.format(amount)}  ·  '
                  'Order total ${adminMoney.format(order.total)}',
        ),
        if (mismatch)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'The receipt amount does not match the order total.',
              style: TextStyle(
                  color: AppColors.terracotta, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 12),
        if (vm.proofUrl != null)
          _ReceiptImage(url: vm.proofUrl!)
        else
          const Text('The receipt image could not be loaded right now.',
              style: TextStyle(color: Colors.black54)),
        if (!p.verified) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: vm.busy ? null : vm.flagPayment,
                  child: const Text('Flag mismatch'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: vm.busy ? null : vm.approvePayment,
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A receipt or delivery photo. Tap it to open it full screen and zoom in
/// (the admin has to read the amount on the receipt).
class _ReceiptImage extends StatelessWidget {
  const _ReceiptImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 120,
            child: Center(child: Text('Image could not be shown')),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rider
// ---------------------------------------------------------------------------

class _RiderPanel extends StatelessWidget {
  const _RiderPanel({required this.vm});
  final AdminOrderDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final order = vm.order!;

    // A dropdown must never show a value that is not in its list.
    final selected = vm.riders.any((r) => r.id == order.riderId)
        ? order.riderId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (vm.riders.isEmpty)
          const Text('No riders available yet.')
        else
          DropdownButton<String>(
            isExpanded: true,
            value: selected,
            hint: const Text('Choose a rider'),
            items: [
              for (final r in vm.riders)
                DropdownMenuItem<String>(
                  value: r.id,
                  child: Text(
                    r.fullName.isEmpty ? (r.email ?? 'Rider') : r.fullName,
                  ),
                ),
            ],
            onChanged: vm.canAssignRider
                ? (id) {
                    if (id != null) vm.assignRider(id);
                  }
                : null,
          ),
        if (order.riderName != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Assigned: ${order.riderName}'
              '${order.riderPhone == null ? '' : '  ·  ${order.riderPhone}'}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        if (!vm.canAssignRider && vm.order!.status.index > OrderStatus.packed.index)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('The order has left the shop, so the rider is fixed.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ),
      ],
    );
  }
}

class _DeliveryProof extends StatelessWidget {
  const _DeliveryProof({required this.vm});
  final AdminOrderDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final d = vm.order!.delivery!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReceiptImage(url: vm.deliveryUrl!),
        const SizedBox(height: 8),
        Text('Delivered ${adminDateTime(d.deliveredAt)}'),
        if (d.notes != null && d.notes!.isNotEmpty)
          Text('Rider note: ${d.notes}',
              style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The button that moves the order on
// ---------------------------------------------------------------------------

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.vm});
  final AdminOrderDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final label = vm.advanceLabel;
    final blocker = vm.advanceBlocker;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.sand)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.actionError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(vm.actionError!,
                      style: const TextStyle(color: AppColors.terracotta)),
                ),
              if (label == null)
                Text(
                  vm.order!.status == OrderStatus.delivered
                      ? 'This order has been delivered.'
                      : 'With the rider. They mark it delivered after taking '
                          'the photo.',
                  style: const TextStyle(color: Colors.black54),
                )
              else ...[
                if (blocker != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(blocker,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ),
                ElevatedButton(
                  onPressed: vm.canAdvance ? vm.advance : null,
                  child: vm.busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

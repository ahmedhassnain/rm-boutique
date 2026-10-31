import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../shared/models/order.dart';
import 'product_photo.dart';
import 'status_chip.dart';

/// Live list of orders. Works for every role, because the database only
/// returns the orders that role may see. Each role's home screen starts
/// with this so integration is visible from day one; replace it with your
/// own screen as you build.
class OrdersFeed extends StatefulWidget {
  const OrdersFeed({super.key, required this.streamFactory, this.onTap, this.emptyText = 'No orders yet'});

  final Stream<List<Order>> Function() streamFactory;
  final void Function(Order order)? onTap;
  final String emptyText;

  @override
  State<OrdersFeed> createState() => _OrdersFeedState();
}

class _OrdersFeedState extends State<OrdersFeed> {
  late final Stream<List<Order>> _stream = widget.streamFactory();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load orders.\n${snap.error}', textAlign: TextAlign.center)));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!;
        if (orders.isEmpty) return Center(child: Text(widget.emptyText));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final o = orders[i];
            return Card(
              child: ListTile(
                leading: OrderThumb(orderId: o.id),
                onTap: widget.onTap == null ? null : () => widget.onTap!(o),
                title: Text('Order ${o.id.substring(0, 8)}  ·  ${NumberFormat.currency(symbol: '₪', decimalDigits: 0).format(o.total)}'),
                subtitle: Text(o.deliveryAddress),
                trailing: StatusChip(o.status),
              ),
            );
          },
        );
      },
    );
  }
}

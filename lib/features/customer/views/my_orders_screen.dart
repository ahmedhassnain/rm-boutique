import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/orders_feed.dart';
import '../../../shared/repositories/order_repository.dart';

/// OWNER: Maheen. My orders; tap one to see details / upload payment.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrderRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: OrdersFeed(
        streamFactory: orders.watchOrders,
        emptyText: 'You have no orders yet',
        onTap: (o) => context.push('/customer/order/${o.id}'),
      ),
    );
  }
}

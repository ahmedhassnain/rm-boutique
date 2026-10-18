import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/orders_feed.dart';
import '../../../core/widgets/role_scaffold.dart';
import '../../../shared/repositories/order_repository.dart';

/// OWNER: Maheen.  Placeholder: a live list of MY orders.
/// Replace with: browse products, size guide, stock status, checkout,
/// payment upload and order tracking.
class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrderRepository>();
    return RoleScaffold(
      title: 'My orders',
      body: OrdersFeed(
        streamFactory: orders.watchOrders,
        emptyText: 'You have no orders yet',
      ),
    );
  }
}

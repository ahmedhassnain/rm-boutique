import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/orders_feed.dart';
import '../../../core/widgets/role_scaffold.dart';
import '../../../shared/repositories/order_repository.dart';

/// OWNER: Ahmad.  Placeholder: a live list of orders ASSIGNED TO ME.
/// Replace with: assigned orders, address details with map pin,
/// delivery photo proof and earnings.
class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrderRepository>();
    return RoleScaffold(
      title: 'My deliveries',
      body: OrdersFeed(
        streamFactory: orders.watchOrders,
        emptyText: 'No deliveries assigned to you',
      ),
    );
  }
}

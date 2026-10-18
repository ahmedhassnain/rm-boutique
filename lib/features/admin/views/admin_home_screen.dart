import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/orders_feed.dart';
import '../../../core/widgets/role_scaffold.dart';
import '../../../shared/repositories/order_repository.dart';

/// OWNER: Ahmed.  Placeholder: a live list of ALL orders.
/// Replace with the order command centre (timeline, payment check,
/// rider assignment, inventory sync).
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrderRepository>();
    return RoleScaffold(
      title: 'Admin · Orders',
      body: OrdersFeed(streamFactory: orders.watchOrders),
    );
  }
}

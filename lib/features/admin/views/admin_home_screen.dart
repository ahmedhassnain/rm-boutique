import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/product_repository.dart';
import '../../auth/auth_controller.dart';
import '../viewmodels/admin_inventory_viewmodel.dart';
import '../viewmodels/admin_orders_viewmodel.dart';
import '../viewmodels/admin_riders_viewmodel.dart';
import 'inbox_tab.dart';
import 'inventory_tab.dart';
import 'orders_tab.dart';
import 'payments_tab.dart';
import 'riders_tab.dart';
import 'widgets/admin_format.dart';

/// OWNER: Ahmed (admin). The admin app frame: top bar (title, alerts bell,
/// sign out), the five tabs, and the bottom navigation bar from the wireframe.
///
/// The three view-models are created ONCE here, above the tabs, so every tab
/// (and the alerts bell) reads the same live data instead of loading its own.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  static const _titles = [
    'Manage orders',
    'Payments',
    'Inventory',
    'Riders',
    'Inbox',
  ];

  void _openTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (c) => AdminOrdersViewModel(c.read<OrderRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AdminInventoryViewModel(c.read<ProductRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AdminRidersViewModel(c.read<OrderRepository>()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: [
            _AlertsButton(onOpenTab: _openTab),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthController>().signOut(),
            ),
          ],
        ),
        // IndexedStack keeps every tab alive, so switching tabs never loses
        // a search, a filter or the scroll position.
        body: IndexedStack(
          index: _index,
          children: [
            OrdersTab(onOpenTab: _openTab),
            const PaymentsTab(),
            const InventoryTab(),
            const RidersTab(),
            const InboxTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _openTab,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.sand,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.two_wheeler_outlined),
              selectedIcon: Icon(Icons.two_wheeler),
              label: 'Riders',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Inbox',
            ),
          ],
        ),
      ),
    );
  }
}

/// The bell in the top bar. The badge counts what needs the admin's
/// attention: payments waiting for review plus sizes that are low or sold out.
class _AlertsButton extends StatelessWidget {
  const _AlertsButton({required this.onOpenTab});
  final void Function(int index) onOpenTab;

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AdminOrdersViewModel>();
    final stock = context.watch<AdminInventoryViewModel>();
    final count = orders.paymentsToReviewCount + stock.alerts.length;

    return IconButton(
      tooltip: 'Alerts',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        // The sheet is a separate page and cannot see our providers, so it
        // gets a snapshot of the data it needs.
        final payments = orders.paymentsFor(AdminPaymentFilter.toReview);
        final alerts = stock.alerts;
        showModalBottomSheet<void>(
          context: context,
          builder: (sheetContext) => _AlertsSheet(
            payments: payments,
            alerts: alerts,
            onOpenOrder: (id) {
              Navigator.of(sheetContext).pop();
              context.push('/admin/order/$id');
            },
            onOpenInventory: () {
              Navigator.of(sheetContext).pop();
              onOpenTab(2);
            },
          ),
        );
      },
    );
  }
}

class _AlertsSheet extends StatelessWidget {
  const _AlertsSheet({
    required this.payments,
    required this.alerts,
    required this.onOpenOrder,
    required this.onOpenInventory,
  });

  final List<Order> payments;
  final List<StockAlert> alerts;
  final void Function(String orderId) onOpenOrder;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Alerts',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          if (payments.isEmpty && alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nothing needs your attention right now.'),
            ),
          for (final o in payments)
            ListTile(
              leading: const Icon(Icons.receipt_long,
                  color: AppColors.terracotta),
              title: Text('${adminOrderLabel(o)}: payment to review'),
              subtitle: Text(o.customerName ?? 'Customer'),
              onTap: () => onOpenOrder(o.id),
            ),
          for (final a in alerts)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.terracotta),
              title: Text(a.product.name),
              subtitle: Text(
                '${a.variant.size} · ${a.variant.colour}: '
                '${a.variant.inStock ? '${a.variant.stock} left' : 'sold out'}',
              ),
              onTap: onOpenInventory,
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/repositories/message_repository.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/product_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../../auth/auth_controller.dart';
import '../viewmodels/admin_inventory_viewmodel.dart';
import '../viewmodels/admin_orders_viewmodel.dart';
import '../viewmodels/inbox_viewmodel.dart';
import 'inbox_tab.dart';
import 'inventory_tab.dart';
import 'orders_tab.dart';
import 'payments_tab.dart';
import 'widgets/admin_format.dart';

/// OWNER: Ahmed (admin). The admin app frame: top bar (title, alerts bell,
/// sign out), the four tabs, the small "+" button and the bottom navigation
/// bar, as in the admin wireframe of the proposal. The four tabs are the four
/// admin features: order command centre, payment verification, inventory sync
/// and communication hub.
///
/// The view-models are created ONCE here, above the tabs, so every tab
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
          create: (c) => AdminInventoryViewModel(
            c.read<ProductRepository>(),
            storage: c.read<StorageRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => InboxViewModel(c.read<MessageRepository>()),
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
        // The "+" of the wireframe: "Add order" on the Orders tab and
        // "New product" on the Inventory tab.
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                tooltip: 'Add order',
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: () => context.push('/admin/add-order'),
                child: const Icon(Icons.add),
              )
            : _index == 2
                ? Builder(
                    builder: (context) => FloatingActionButton.extended(
                      tooltip: 'New product',
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () async {
                        final inventory =
                            context.read<AdminInventoryViewModel>();
                        final saved =
                            await context.push<bool>('/admin/product');
                        if (saved == true) inventory.load(silent: true);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New product'),
                    ),
                  )
                : null,
        // IndexedStack keeps every tab alive, so switching tabs never loses
        // a search, a filter or the scroll position.
        body: IndexedStack(
          index: _index,
          children: [
            OrdersTab(onOpenTab: _openTab),
            const PaymentsTab(),
            const InventoryTab(),
            const InboxTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _openTab,
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
              icon: _InboxIcon(selected: false),
              selectedIcon: _InboxIcon(selected: true),
              label: 'Inbox',
            ),
          ],
        ),
      ),
    );
  }
}

/// The Inbox icon of the bottom bar, with a count of unread customer messages.
class _InboxIcon extends StatelessWidget {
  const _InboxIcon({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<InboxViewModel>().unreadCount;
    return Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      child: Icon(selected ? Icons.forum : Icons.forum_outlined),
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
                  color: AppColors.alert),
              title: Text('${adminOrderLabel(o)}: payment to review'),
              subtitle: Text(o.customerName ?? 'Customer'),
              onTap: () => onOpenOrder(o.id),
            ),
          for (final a in alerts)
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.alert),
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

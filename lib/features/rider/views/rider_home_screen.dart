import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/role_scaffold.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/auth_controller.dart';
import '../../../shared/models/order.dart';
import '../../../shared/repositories/order_repository.dart';
import '../viewmodels/rider_deliveries_viewmodel.dart';

/// This app has one boutique store, not many vendors, so every order's
/// "pickup" point is the same place. There's no store-address column in the
/// schema, so this is a label, not a geocoded point.
const String kPickupLabel = 'R&M Boutique (pickup)';

/// OWNER: rider. Main page, laid out to match the "Delivery Rider Main Page"
/// wireframe: a Home dashboard (today's stats + the next delivery's route),
/// plus Deliveries, History and Profile behind a bottom nav bar.
///
/// This follows the wireframe's shape but not its sample content — that
/// content key described a live marketplace (accept/decline, on-duty
/// toggle, ratings). This app assigns deliveries to a rider ahead of time,
/// so those don't apply; the stats/route-card content here is all real data
/// from RiderDeliveriesViewModel instead.
class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _index = 0;
  static const _titles = ['My deliveries', 'Deliveries', 'History', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => RiderDeliveriesViewModel(c.read<OrderRepository>()),
      child: Consumer<RiderDeliveriesViewModel>(
        builder: (context, vm, _) {
          return RoleScaffold(
            title: _titles[_index],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping),
                  label: 'Deliveries',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
            body: _body(vm),
          );
        },
      ),
    );
  }

  Widget _body(RiderDeliveriesViewModel vm) {
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vm.error!, textAlign: TextAlign.center),
        ),
      );
    }
    return switch (_index) {
      1 => _DeliveriesList(
          orders: vm.active, emptyText: 'No deliveries assigned to you'),
      2 => _HistoryTab(vm: vm),
      3 => const _ProfileTab(),
      _ => _DashboardTab(vm: vm, onSeeAll: (i) => setState(() => _index = i)),
    };
  }
}

/// Home tab: today's stats strip, a map preview of the next delivery, and
/// its pickup -> drop-off route card. Matches the wireframe's layout.
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.vm, required this.onSeeAll});
  final RiderDeliveriesViewModel vm;
  final ValueChanged<int> onSeeAll;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final next = vm.active.isEmpty ? null : vm.active.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatsStrip(vm: vm, money: money, onSeeAll: onSeeAll),
        const SizedBox(height: 16),
        if (next != null && next.hasLocation) ...[
          _DashboardMapCard(order: next),
          const SizedBox(height: 16),
        ],
        if (next != null)
          _NextDeliveryCard(order: next)
        else
          const _NoActiveDeliveryCard(),
      ],
    );
  }
}

/// Three stat tiles (active / completed / estimated earnings). The first
/// is styled as emphasised, matching the selected-looking first block in
/// the wireframe; tapping any of them jumps to the relevant tab.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip(
      {required this.vm, required this.money, required this.onSeeAll});
  final RiderDeliveriesViewModel vm;
  final NumberFormat money;
  final ValueChanged<int> onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${vm.active.length}',
            label: 'Active',
            highlighted: true,
            onTap: () => onSeeAll(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            value: '${vm.history.length}',
            label: 'Completed',
            onTap: () => onSeeAll(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            value: money.format(vm.earnings),
            label: 'Est. earnings',
            onTap: () => onSeeAll(2),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final String value;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.olive : AppColors.sand,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: highlighted ? AppColors.ivory : AppColors.olive,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: highlighted
                      ? AppColors.ivory.withValues(alpha: 0.85)
                      : AppColors.charcoal.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only map preview of the next delivery's address, with a small
/// overlay chip -- the big map card from the wireframe.
class _DashboardMapCard extends StatelessWidget {
  const _DashboardMapCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(order.addressLat!, order.addressLng!);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            IgnorePointer(
              child: FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rmboutique.app',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: point,
                      width: 32,
                      height: 32,
                      child: const Icon(Icons.location_pin,
                          color: AppColors.terracotta, size: 32),
                    ),
                  ]),
                ],
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Next stop',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The route card: pickup -> drop-off with a connecting line, then Call and
/// View details buttons -- the detail card from the wireframe.
class _NextDeliveryCard extends StatelessWidget {
  const _NextDeliveryCard({required this.order});
  final Order order;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: order.customerPhone);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone app')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    final hasPhone =
        order.customerPhone != null && order.customerPhone!.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Order ${order.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                StatusChip(order.status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${order.customerName ?? 'Customer'} · ${money.format(order.total)}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 14),
            const _RouteRow(pickup: true, label: kPickupLabel),
            Padding(
              padding: const EdgeInsets.only(left: 8.5),
              child: Container(
                  width: 1.4,
                  height: 18,
                  color: AppColors.olive.withValues(alpha: 0.3)),
            ),
            _RouteRow(pickup: false, label: order.deliveryAddress),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasPhone ? () => _call(context) : null,
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/rider/delivery/${order.id}'),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('View details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.pickup, required this.label});
  final bool pickup;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(pickup ? Icons.storefront : Icons.flag,
            size: 18, color: pickup ? AppColors.olive : AppColors.terracotta),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _NoActiveDeliveryCard extends StatelessWidget {
  const _NoActiveDeliveryCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.olive),
            SizedBox(height: 10),
            Text('No deliveries assigned right now',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('New deliveries assigned to you will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final profile = auth.profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.olive,
                  child: Icon(Icons.person, color: AppColors.ivory, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  (profile == null || profile.fullName.isEmpty)
                      ? 'Rider'
                      : profile.fullName,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                if (profile?.phone != null && profile!.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(profile.phone!,
                      style: const TextStyle(color: Colors.black54)),
                ],
                const SizedBox(height: 4),
                const Text('Rider',
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: auth.signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _DeliveriesList extends StatelessWidget {
  const _DeliveriesList({required this.orders, required this.emptyText});
  final List<Order> orders;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return Center(child: Text(emptyText));
    final money = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final o = orders[i];
        return Card(
          child: ListTile(
            onTap: () => context.go('/rider/delivery/${o.id}'),
            title: Text(
                'Order ${o.id.substring(0, 8)}  ·  ${money.format(o.total)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            subtitle: Text(o.deliveryAddress,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: StatusChip(o.status),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.vm});
  final RiderDeliveriesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₪', decimalDigits: 0);
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('${vm.history.length} delivered',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(money.format(vm.earnings),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.olive)),
                    const Text('Estimated earnings',
                        style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _DeliveriesList(
            orders: vm.history,
            emptyText: 'Nothing delivered yet',
          ),
        ),
      ],
    );
  }
}

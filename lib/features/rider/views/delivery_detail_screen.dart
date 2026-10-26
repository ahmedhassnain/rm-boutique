import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../shared/models/order.dart';
import '../../../shared/repositories/order_repository.dart';
import '../../../shared/repositories/storage_repository.dart';
import '../viewmodels/delivery_detail_viewmodel.dart';

/// OWNER: rider. One delivery: address + map, customer contact, the items,
/// and the "Mark delivered" photo-proof action.
class DeliveryDetailScreen extends StatelessWidget {
  const DeliveryDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => DeliveryDetailViewModel(
        c.read<OrderRepository>(),
        c.read<StorageRepository>(),
        orderId,
      ),
      child: Consumer<DeliveryDetailViewModel>(
        builder: (context, vm, _) {
          final o = vm.order;
          return Scaffold(
            appBar: AppBar(title: const Text('Delivery details')),
            body: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : o == null
                    ? Center(child: Text(vm.error ?? 'Delivery not found'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Order ${o.id.substring(0, 8)}',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                              ),
                              StatusChip(o.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat.currency(symbol: '₪', decimalDigits: 0)
                                .format(o.total),
                            style: const TextStyle(
                                color: AppColors.olive,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          _ContactCard(
                            name: o.customerName ?? 'Customer',
                            phone: o.customerPhone,
                            address: o.deliveryAddress,
                            notes: o.notes,
                            neededBy: o.neededBy,
                          ),
                          if (o.hasLocation) ...[
                            const SizedBox(height: 16),
                            _MapCard(lat: o.addressLat!, lng: o.addressLng!),
                          ],
                          const SizedBox(height: 16),
                          _ItemsCard(order: o),
                          const SizedBox(height: 20),
                          _DeliveryProofCard(vm: vm),
                        ],
                      ),
          );
        },
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.name,
    required this.phone,
    required this.address,
    this.notes,
    this.neededBy,
  });

  final String name;
  final String? phone;
  final String address;
  final String? notes;
  final DateTime? neededBy;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open the phone app')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (phone != null && phone!.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => _call(context),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 18, color: AppColors.olive),
                const SizedBox(width: 6),
                Expanded(child: Text(address)),
              ],
            ),
            if (neededBy != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.event, size: 18, color: AppColors.olive),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Needed by ${DateFormat.yMMMd().format(neededBy!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (notes != null && notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined,
                      size: 18, color: AppColors.olive),
                  const SizedBox(width: 6),
                  Expanded(child: Text(notes!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.lat, required this.lng});
  final double lat;
  final double lng;

  Future<void> _navigate(BuildContext context) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: IgnorePointer(
              // Read-only preview: the rider navigates with the button below
              // rather than panning around inside the card.
              child: FlutterMap(
                options: MapOptions(initialCenter: point, initialZoom: 15),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.rmboutique.app',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: point,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.location_pin,
                          color: AppColors.terracotta, size: 36),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _navigate(context),
              icon: const Icon(Icons.directions),
              label: const Text('Navigate'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            for (final i in order.items)
              ListTile(
                dense: true,
                title: Text(i.productName ?? 'Item'),
                subtitle: Text('${i.size ?? ''} ${i.colour ?? ''}'.trim()),
                trailing: Text('× ${i.quantity}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryProofCard extends StatelessWidget {
  const _DeliveryProofCard({required this.vm});
  final DeliveryDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final delivered = vm.order!.delivery != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(delivered ? Icons.verified : Icons.camera_alt,
                  color: delivered ? AppColors.olive : AppColors.terracotta),
              const SizedBox(width: 8),
              Text(delivered ? 'Delivered' : 'Proof of delivery',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text(delivered
                ? 'This order was marked delivered with a photo below.'
                : 'Take a photo at hand-off, then mark the order delivered.'),
            if (vm.deliveryPhotoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  vm.deliveryPhotoUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 60,
                      child: Center(child: Text('Preview unavailable'))),
                ),
              ),
            ],
            if (vm.error != null) ...[
              const SizedBox(height: 8),
              Text(vm.error!, style: const TextStyle(color: AppColors.terracotta)),
            ],
            if (vm.canMarkDelivered) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: vm.uploading ? null : () => vm.markDelivered(),
                  icon: vm.uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt),
                  label: Text(vm.uploading
                      ? 'Uploading...'
                      : 'Take photo & mark delivered'),
                ),
              ),
            ] else if (!delivered) ...[
              const SizedBox(height: 8),
              Text(
                'This order is ${vm.order!.status.label.toLowerCase()} — it needs '
                'to be Dispatched before it can be marked delivered.',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

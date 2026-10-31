import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_theme.dart';

/// SHARED widget (moved here from the rider feature so any screen can use
/// it directly, no copy-paste needed).
///
/// A self-contained "pick a location on the map" field. Drop it into any
/// form: it shows an OpenStreetMap view (free, no API key/credit card
/// needed), lets the person tap to drop a pin, and reports the picked
/// point back through [onChanged].
///
/// Usage (e.g. in checkout_screen.dart, alongside the address text field):
/// ```dart
/// import '../../../core/widgets/location_picker_map.dart';
///
/// LocationPickerMap(
///   initial: const LatLng(31.9522, 35.2332), // optional starting point
///   onChanged: (point) => vm.setLocation(point.latitude, point.longitude),
/// )
/// ```
/// Maheen: import this directly from lib/core/widgets/location_picker_map.dart
/// in checkout and wire `onChanged` into `OrderRepository.placeOrder(lat:, lng:, ...)`.
class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({
    super.key,
    this.initial,
    required this.onChanged,
    this.height = 220,
  });

  /// Starting pin position. Defaults to a central point if not given.
  final LatLng? initial;

  /// Called every time the person taps the map with the newly picked point.
  final ValueChanged<LatLng> onChanged;

  final double height;

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  static const _fallback = LatLng(31.9522, 35.2332); // Ramallah, as a default
  late LatLng _point = widget.initial ?? _fallback;

  void _pick(LatLng point) {
    setState(() => _point = point);
    widget.onChanged(point);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _point,
                initialZoom: 14,
                onTap: (_, point) => _pick(point),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rmboutique.app',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: _point,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.location_pin,
                        color: AppColors.alert, size: 36),
                  ),
                ]),
              ],
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Tap the map to drop a pin',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

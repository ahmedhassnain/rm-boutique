import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/repositories/order_repository.dart';
import '../../shared/repositories/storage_repository.dart';
import '../theme/app_theme.dart';

/// A product photo in a fixed square, used wherever a product appears in a
/// list (order cards, order details, checkout, inventory...).
///
/// [imagePath] is `products.image_path`. With no path, or if the photo cannot
/// be loaded, it shows the hanger icon on the soft tint instead, so a product
/// without a photo never breaks a screen. [badge] is a small label drawn over
/// the bottom of the photo, e.g. "2 items".
class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    super.key,
    this.imagePath,
    this.size = 56,
    this.radius = 10,
    this.badge,
  });

  final String? imagePath;
  final double size;
  final double radius;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final url = (path == null || path.isEmpty)
        ? null
        : context.read<StorageRepository>().productImageUrl(path);
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.tint,
            border: Border.all(color: AppColors.tint),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url == null)
                _fallback()
              else
                Image.network(
                  url,
                  fit: BoxFit.cover,
                  cacheWidth: pixels,
                  errorBuilder: (_, __, ___) => _fallback(),
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : const SizedBox.shrink(),
                ),
              if (badge != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    color: AppColors.ink.withValues(alpha: 0.72),
                    child: Text(
                      badge!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Center(
        child: Icon(Icons.checkroom_outlined,
            size: size * 0.45, color: AppColors.ink),
      );
}

/// The photo of the FIRST item of an order, for lists whose orders arrive
/// without their items (the live "My orders" and rider lists). It asks the
/// database once per order and remembers the answer while the app is open.
class OrderThumb extends StatefulWidget {
  const OrderThumb({super.key, required this.orderId, this.size = 48});

  final String orderId;
  final double size;

  @override
  State<OrderThumb> createState() => _OrderThumbState();
}

class _OrderThumbState extends State<OrderThumb> {
  static final Map<String, Future<String?>> _cache = {};

  late final Future<String?> _path = _cache.putIfAbsent(
    widget.orderId,
    () => context
        .read<OrderRepository>()
        .firstItemImagePath(widget.orderId)
        .catchError((_) => null),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _path,
      builder: (context, snap) =>
          ProductPhoto(imagePath: snap.data, size: widget.size),
    );
  }
}

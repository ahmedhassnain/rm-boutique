import 'dart:async';

import 'package:rm_boutique/shared/models/order.dart';
import 'package:rm_boutique/shared/models/payment.dart';
import 'package:rm_boutique/shared/models/product.dart';
import 'package:rm_boutique/shared/models/profile.dart';
import 'package:rm_boutique/shared/order_status.dart';
import 'package:rm_boutique/shared/repositories/order_repository.dart';
import 'package:rm_boutique/shared/repositories/product_repository.dart';
import 'package:rm_boutique/shared/repositories/storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A real-but-unused client, only so the repositories' constructors never
/// touch the uninitialised global `supabase` singleton in tests.
SupabaseClient _dummyClient() =>
    SupabaseClient('https://example.supabase.co', 'anon-key');

/// Builds an Order the same way the app does: from a database-shaped map.
Order makeOrder({
  String id = 'order-12345678',
  String status = 'confirmed',
  String? riderId,
  String? riderName,
  String? neededBy,
  String customerName = 'Maheen Zubair',
  double total = 900,
  Map<String, dynamic>? payment,
  Map<String, dynamic>? delivery,
}) =>
    Order.fromJson({
      'id': id,
      'customer_id': 'c1',
      'rider_id': riderId,
      'status': status,
      'delivery_address': 'Parkhill Residence, Bethlehem',
      'needed_by': neededBy,
      'total': total,
      'created_at': '2026-10-20T08:00:00Z',
      'customer': {'full_name': customerName, 'phone': '0599123456'},
      if (riderName != null) 'rider': {'full_name': riderName, 'phone': '0599000000'},
      if (payment != null) 'payments': payment,
      if (delivery != null) 'deliveries': delivery,
    });

Map<String, dynamic> paymentJson({
  bool verified = false,
  bool flagged = false,
  double? amount = 900,
}) =>
    {
      'id': 'pay-1',
      'order_id': 'order-12345678',
      'screenshot_path': 'order-12345678/proof.jpg',
      'amount': amount,
      'verified': verified,
      'flagged': flagged,
    };

/// Stands in for OrderRepository: serves whatever the test puts in [orders],
/// records the admin actions, and lets a test fire the live streams by hand.
class FakeOrderRepository extends OrderRepository {
  FakeOrderRepository() : super(client: _dummyClient());

  List<Order> orders = [];
  List<Profile> riders = [];
  Order? single;
  Object? fetchError;
  Object? actionError;

  int fetchOrdersCalls = 0;
  final List<String> actions = [];

  final ordersStream = StreamController<List<Order>>.broadcast();
  final paymentsStream = StreamController<List<Payment>>.broadcast();
  final orderStream = StreamController<Order>.broadcast();

  @override
  Future<List<Order>> fetchOrders({OrderStatus? status}) async {
    fetchOrdersCalls++;
    if (fetchError != null) throw fetchError!;
    return orders;
  }

  @override
  Future<Order> fetchOrder(String id) async {
    if (fetchError != null) throw fetchError!;
    return single!;
  }

  @override
  Stream<List<Order>> watchOrders() => ordersStream.stream;

  @override
  Stream<List<Payment>> watchPayments() => paymentsStream.stream;

  @override
  Stream<Order> watchOrder(String id) => orderStream.stream;

  @override
  Future<List<Profile>> fetchRiders() async => riders;

  @override
  Future<void> advanceStatus(Order order) async {
    if (actionError != null) throw actionError!;
    actions.add('advance:${order.status.name}');
  }

  @override
  Future<void> assignRider(String orderId, String riderId) async {
    if (actionError != null) throw actionError!;
    actions.add('assign:$riderId');
  }

  @override
  Future<void> reviewPayment(String orderId, {required bool approved}) async {
    if (actionError != null) throw actionError!;
    actions.add(approved ? 'approve' : 'flag');
  }
}

/// Stands in for ProductRepository.
class FakeProductRepository extends ProductRepository {
  FakeProductRepository() : super(client: _dummyClient());

  List<Product> products = [];
  Object? updateError;
  final List<String> updates = [];
  final variantsStream = StreamController<List<ProductVariant>>.broadcast();

  @override
  Future<List<Product>> fetchProducts() async => products;

  @override
  Stream<List<ProductVariant>> watchVariants() => variantsStream.stream;

  @override
  Future<void> updateStock(String variantId, int stock) async {
    if (updateError != null) throw updateError!;
    updates.add('$variantId=$stock');
  }
}

/// Stands in for StorageRepository: returns a fake link for any image.
class FakeStorageRepository extends StorageRepository {
  FakeStorageRepository() : super(client: _dummyClient());

  @override
  Future<String> signedUrl(String bucket, String path) async =>
      'https://example.supabase.co/$bucket/$path?signed=1';
}

/// A product with the given stock per size, for the inventory tests.
Product makeProduct({
  String id = 'p1',
  String name = 'Terracotta Thobe',
  required List<int> stocks,
}) =>
    Product(
      id: id,
      name: name,
      price: 450,
      variants: [
        for (var i = 0; i < stocks.length; i++)
          ProductVariant(
            id: '$id-v$i',
            productId: id,
            size: ['S', 'M', 'L', 'XL'][i],
            colour: 'Terracotta',
            stock: stocks[i],
          ),
      ],
    );

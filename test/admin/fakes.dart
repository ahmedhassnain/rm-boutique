import 'dart:async';
import 'dart:typed_data';

import 'package:rm_boutique/shared/models/cart_line.dart';
import 'package:rm_boutique/shared/models/chat_message.dart';
import 'package:rm_boutique/shared/models/order.dart';
import 'package:rm_boutique/shared/models/payment.dart';
import 'package:rm_boutique/shared/models/product.dart';
import 'package:rm_boutique/shared/models/profile.dart';
import 'package:rm_boutique/shared/order_status.dart';
import 'package:rm_boutique/shared/repositories/message_repository.dart';
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
  List<Profile> customers = [];
  final List<String> adminOrders = []; // customer ids the admin ordered for
  List<CartLine>? lastAdminItems;
  Object? adminOrderError;
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
  Future<List<Profile>> fetchCustomers() async => customers;

  @override
  Future<String> adminPlaceOrder({
    required String customerId,
    required String address,
    required List<CartLine> items,
    double? lat,
    double? lng,
    DateTime? neededBy,
    String? notes,
  }) async {
    if (adminOrderError != null) throw adminOrderError!;
    adminOrders.add(customerId);
    lastAdminItems = items;
    return 'new-order-id';
  }

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

  // Product form: every write is recorded as a short text, in order.
  Object? variantsError;
  final List<String> productWrites = [];

  @override
  Future<void> updateProduct(
    String id, {
    required String name,
    required String description,
    required String category,
    required double price,
    required bool isActive,
  }) async {
    if (updateError != null) throw updateError!;
    productWrites.add('update $id $name|$category|$price|$isActive');
  }

  @override
  Future<String> createProduct({
    required String name,
    required String description,
    required String category,
    required double price,
    required bool isActive,
  }) async {
    if (updateError != null) throw updateError!;
    productWrites.add('create $name|$category|$price|$isActive');
    return 'new-id';
  }

  @override
  Future<void> addVariants(
    String productId,
    List<({String size, String colour, int stock})> variants,
  ) async {
    if (variantsError != null) throw variantsError!;
    productWrites.add('variants $productId ' +
        variants.map((v) => '${v.size}/${v.colour}/${v.stock}').join(','));
  }

  @override
  Future<void> deleteProduct(String id) async => productWrites.add('delete $id');

  @override
  Future<void> setImagePath(String productId, String path) async =>
      productWrites.add('image $productId $path');
}

/// Stands in for StorageRepository: returns a fake link for any image.
class FakeStorageRepository extends StorageRepository {
  FakeStorageRepository() : super(client: _dummyClient());

  @override
  Future<String> signedUrl(String bucket, String path) async =>
      'https://example.supabase.co/$bucket/$path?signed=1';

  Object? uploadError;
  final List<String> removed = [];

  @override
  Future<String> uploadProductImage(String productId, Uint8List bytes) async {
    if (uploadError != null) throw uploadError!;
    return '$productId/new.jpg';
  }

  @override
  Future<void> deleteProductImage(String path) async => removed.add(path);
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

/// Stands in for MessageRepository: the test pushes messages by hand.
class FakeMessageRepository extends MessageRepository {
  FakeMessageRepository() : super(client: _dummyClient());

  final allStream = StreamController<List<ChatMessage>>.broadcast();
  final threadStream = StreamController<List<ChatMessage>>.broadcast();
  Map<String, ChatMember> members = {};
  Object? sendError;

  final List<String> sent = []; // "fromAdmin|tag|body"
  final List<String> markedRead = [];

  @override
  Stream<List<ChatMessage>> watchAll() => allStream.stream;

  @override
  Stream<List<ChatMessage>> watchThread(String memberId) => threadStream.stream;

  @override
  Future<Map<String, ChatMember>> memberInfo(Iterable<String> ids) async => {
        for (final id in ids)
          if (members.containsKey(id)) id: members[id]!,
      };

  @override
  Future<void> send({
    required String memberId,
    required String body,
    required bool fromAdmin,
    MessageTag? tag,
  }) async {
    if (sendError != null) throw sendError!;
    sent.add('$fromAdmin|${tag?.dbValue}|$body');
  }

  @override
  Future<void> markRead(String memberId) async => markedRead.add(memberId);
}

/// A chat message for the chat tests.
ChatMessage makeMessage({
  String id = 'm1',
  String memberId = 'c1',
  bool fromAdmin = false,
  String body = 'Hello',
  MessageTag? tag,
  bool read = false,
  DateTime? at,
}) =>
    ChatMessage(
      id: id,
      memberId: memberId,
      fromAdmin: fromAdmin,
      body: body,
      tag: tag,
      readAt: read ? DateTime(2026, 10, 31, 10) : null,
      createdAt: at ?? DateTime(2026, 10, 31, 9),
    );

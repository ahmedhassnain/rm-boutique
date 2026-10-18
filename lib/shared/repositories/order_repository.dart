import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../models/cart_line.dart';
import '../models/order.dart';
import '../models/profile.dart';
import '../order_status.dart';

/// All order reads and writes. Row Level Security decides what each role gets
/// back, so the same call is safe for everyone:
///   customer -> own orders, rider -> assigned orders, admin -> all orders.
class OrderRepository {
  OrderRepository({SupabaseClient? client}) : _db = client ?? supabase;
  final SupabaseClient _db;

  // Orders with customer/rider names, line items, payment and delivery proof.
  static const _detailSelect = '''
    *,
    customer:profiles!orders_customer_id_fkey(full_name, phone),
    rider:profiles!orders_rider_id_fkey(full_name, phone),
    order_items(*, product_variants(size, colour, products(name))),
    payments(*),
    deliveries(*)
  ''';

  // ---------------- reading ----------------

  Future<List<Order>> fetchOrders({OrderStatus? status}) async {
    var query = _db.from('orders').select(_detailSelect);
    if (status != null) query = query.eq('status', status.dbValue);
    final rows = await query.order('created_at', ascending: false);
    return rows.map<Order>(Order.fromJson).toList();
  }

  Future<Order> fetchOrder(String id) async {
    final row =
        await _db.from('orders').select(_detailSelect).eq('id', id).single();
    return Order.fromJson(row);
  }

  /// Live list. Plain order rows only (no names/items): use fetchOrder(id)
  /// when a detail screen needs them.
  Stream<List<Order>> watchOrders() => _db
      .from('orders')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(Order.fromJson).toList());

  /// Live single order, for the tracking screen.
  Stream<Order> watchOrder(String id) => _db
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', id)
      .where((rows) => rows.isNotEmpty)
      .map((rows) => Order.fromJson(rows.first));

  // ---------------- customer ----------------

  /// Places an order. Prices and stock are handled by the database.
  /// Throws PostgrestException with a readable message, e.g.
  /// "Not enough stock for one of the items".
  Future<String> placeOrder({
    required String address,
    required List<CartLine> items,
    double? lat,
    double? lng,
    DateTime? neededBy,
    String? notes,
  }) async {
    final id = await _db.rpc('place_order', params: {
      'p_address': address,
      'p_lat': lat,
      'p_lng': lng,
      'p_needed_by': neededBy?.toIso8601String().substring(0, 10),
      'p_notes': notes,
      'p_items': items.map((l) => l.toJson()).toList(),
    });
    return id as String;
  }

  // ---------------- admin ----------------

  /// Admin: every status change goes through here.
  /// The database enforces who may make each move.
  Future<void> advanceStatus(Order order) async {
    final next = order.status.next;
    if (next == null) return;
    await _db.from('orders').update({'status': next.dbValue}).eq('id', order.id);
  }

  Future<void> assignRider(String orderId, String riderId) async {
    await _db.from('orders').update({'rider_id': riderId}).eq('id', orderId);
  }

  /// Admin: approve a payment, or flag a mismatch.
  Future<void> reviewPayment(String orderId, {required bool approved}) async {
    await _db.from('payments').update({
      'verified': approved,
      'flagged': !approved,
      'verified_by': _db.auth.currentUser?.id,
      'verified_at': DateTime.now().toIso8601String(),
    }).eq('order_id', orderId);
  }

  /// Admin: the riders to choose from when assigning.
  Future<List<Profile>> fetchRiders() async {
    final rows = await _db.from('profiles').select().eq('role', 'rider');
    return rows.map<Profile>(Profile.fromJson).toList();
  }
}

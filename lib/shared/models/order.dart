import '../order_status.dart';
import 'delivery.dart';
import 'payment.dart';

class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    this.productName,
    this.size,
    this.colour,
  });

  final String id;
  final String orderId;
  final String variantId;
  final int quantity;
  final double unitPrice;

  // Filled only when the order was loaded with its details
  // (OrderRepository.fetchOrder / fetchOrders).
  final String? productName;
  final String? size;
  final String? colour;

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final variant = json['product_variants'];
    final product = variant is Map ? variant['products'] : null;
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      variantId: json['variant_id'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      productName: product is Map ? product['name'] as String? : null,
      size: variant is Map ? variant['size'] as String? : null,
      colour: variant is Map ? variant['colour'] as String? : null,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.status,
    required this.deliveryAddress,
    required this.total,
    required this.createdAt,
    this.riderId,
    this.addressLat,
    this.addressLng,
    this.neededBy,
    this.notes,
    this.customerName,
    this.customerPhone,
    this.riderName,
    this.riderPhone,
    this.items = const [],
    this.payment,
    this.delivery,
  });

  final String id;
  final String customerId;
  final String? riderId;
  final OrderStatus status;
  final String deliveryAddress;
  final double? addressLat;
  final double? addressLng;
  final DateTime? neededBy;
  final String? notes;
  final double total;
  final DateTime createdAt;

  final String? customerName;
  final String? customerPhone;
  final String? riderName;
  final String? riderPhone;
  final List<OrderItem> items;
  final Payment? payment;
  final Delivery? delivery;

  bool get hasRider => riderId != null;
  bool get hasLocation => addressLat != null && addressLng != null;

  /// True when the customer needs it within 3 days and it is not delivered.
  bool get isUrgent {
    if (neededBy == null || status == OrderStatus.delivered) return false;
    return neededBy!.difference(DateTime.now()).inDays <= 3;
  }

  /// Accepts both a plain `orders` row (realtime stream) and a row loaded
  /// with joins (see OrderRepository for the select string).
  factory Order.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? one(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is List && v.isNotEmpty) return v.first as Map<String, dynamic>;
      return null;
    }

    final customer = one(json['customer']);
    final rider = one(json['rider']);
    final payment = one(json['payments']);
    final delivery = one(json['deliveries']);
    final items = json['order_items'];

    return Order(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      riderId: json['rider_id'] as String?,
      status: OrderStatus.fromDb(json['status'] as String),
      deliveryAddress: json['delivery_address'] as String,
      addressLat: (json['address_lat'] as num?)?.toDouble(),
      addressLng: (json['address_lng'] as num?)?.toDouble(),
      neededBy: json['needed_by'] == null
          ? null
          : DateTime.parse(json['needed_by'] as String),
      notes: json['notes'] as String?,
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      customerName: customer?['full_name'] as String?,
      customerPhone: customer?['phone'] as String?,
      riderName: rider?['full_name'] as String?,
      riderPhone: rider?['phone'] as String?,
      items: items is List
          ? items
              .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
              .toList()
          : const [],
      payment: payment == null ? null : Payment.fromJson(payment),
      delivery: delivery == null ? null : Delivery.fromJson(delivery),
    );
  }
}

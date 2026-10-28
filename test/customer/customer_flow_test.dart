import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/customer/views/order_tracking.dart';
import 'package:rm_boutique/shared/models/cart_line.dart';
import 'package:rm_boutique/shared/models/order.dart';
import 'package:rm_boutique/shared/models/product.dart';
import 'package:rm_boutique/shared/models/profile.dart';
import 'package:rm_boutique/shared/order_status.dart';

Map<String, dynamic> _orderJson({
  String status = 'confirmed',
  String? riderId,
  String? neededBy,
  Map<String, dynamic>? payment,
  Map<String, dynamic>? rider,
}) =>
    {
      'id': 'order-1234',
      'customer_id': 'c1',
      'rider_id': riderId,
      'status': status,
      'delivery_address': 'Parkhill Residence',
      'needed_by': neededBy,
      'total': 900,
      'created_at': '2026-10-20T08:00:00Z',
      if (payment != null) 'payments': payment,
      if (rider != null) 'rider': rider,
    };

Future<void> _pumpTracking(WidgetTester tester, Order order) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: OrderTracking(order: order)),
    ),
  ));
}

void main() {
  test('Product total stock adds up all size/colour variants', () {
    const product =
        Product(id: 'p1', name: 'Terracotta Thobe', price: 450, variants: [
      ProductVariant(
          id: 'v1', productId: 'p1', size: 'M', colour: 'Terracotta', stock: 3),
      ProductVariant(
          id: 'v2', productId: 'p1', size: 'L', colour: 'Terracotta', stock: 0),
    ]);
    expect(product.totalStock, 3);
  });

  test('Variant stock flags: sold out, low and healthy', () {
    const soldOut = ProductVariant(
        id: 'a', productId: 'p', size: 'M', colour: 'x', stock: 0);
    const low = ProductVariant(
        id: 'b', productId: 'p', size: 'M', colour: 'x', stock: 2);
    const healthy = ProductVariant(
        id: 'c', productId: 'p', size: 'M', colour: 'x', stock: 10);
    expect(soldOut.inStock, false);
    expect(low.inStock && low.isLow, true);
    expect(healthy.isLow, false);
  });

  test('CartLine sends exactly what place_order expects', () {
    const line = CartLine(variantId: 'v1', quantity: 2);
    expect(line.toJson(), {'variant_id': 'v1', 'quantity': 2});
  });

  test('A customer can never move an order forward, only admin and rider can',
      () {
    for (final s in OrderStatus.values) {
      expect(s.canBeAdvancedBy(UserRole.customer), false, reason: s.label);
    }
    expect(OrderStatus.confirmed.canBeAdvancedBy(UserRole.admin), true);
    expect(OrderStatus.dispatched.canBeAdvancedBy(UserRole.rider), true);
  });

  test('Order reads payment state and urgency correctly', () {
    final soon = DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    final order = Order.fromJson(_orderJson(neededBy: soon, payment: {
      'id': 'pay1',
      'order_id': 'order-1234',
      'screenshot_path': 'order-1234/proof.jpg',
      'amount': 900,
      'verified': false,
      'flagged': false,
    }));
    expect(order.payment!.verified, false);
    expect(order.isUrgent, true);

    final delivered =
        Order.fromJson(_orderJson(status: 'delivered', neededBy: soon));
    expect(delivered.isUrgent, false);
  });

  testWidgets('Tracking shows the five steps and no rider before assignment',
      (tester) async {
    await _pumpTracking(tester, Order.fromJson(_orderJson()));
    for (final s in OrderStatus.values) {
      expect(find.text(s.label), findsOneWidget);
    }
    expect(find.text('We received your order'), findsOneWidget);
    expect(find.byIcon(Icons.delivery_dining), findsNothing);
  });

  testWidgets('Tracking shows rider name and phone once a rider is assigned',
      (tester) async {
    final order = Order.fromJson(_orderJson(
      status: 'dispatched',
      riderId: 'r1',
      rider: {'full_name': 'Ahmad Rider', 'phone': '0501234567'},
    ));
    await _pumpTracking(tester, order);
    expect(find.text('Ahmad Rider'), findsOneWidget);
    expect(find.text('0501234567'), findsOneWidget);
    expect(find.text('On the way to you'), findsOneWidget);
  });
}

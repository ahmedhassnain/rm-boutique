import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/shared/models/order.dart';
import 'package:rm_boutique/shared/models/product.dart';
import 'package:rm_boutique/shared/models/profile.dart';
import 'package:rm_boutique/shared/order_status.dart';

void main() {
  test('Order.fromJson reads a plain row (realtime stream)', () {
    final o = Order.fromJson({
      'id': 'o1',
      'customer_id': 'c1',
      'rider_id': null,
      'status': 'paid',
      'delivery_address': 'Bethlehem, near the old market',
      'address_lat': null,
      'address_lng': null,
      'needed_by': null,
      'notes': null,
      'total': 389,
      'created_at': '2026-10-20T10:00:00+00:00',
    });
    expect(o.status, OrderStatus.paid);
    expect(o.total, 389.0);
    expect(o.hasRider, isFalse);
    expect(o.items, isEmpty);
    expect(o.payment, isNull);
  });

  test('Order.fromJson reads a joined row (details)', () {
    final o = Order.fromJson({
      'id': 'o2',
      'customer_id': 'c1',
      'rider_id': 'r1',
      'status': 'dispatched',
      'delivery_address': 'Hebron',
      'total': 450.0,
      'created_at': '2026-10-20T10:00:00+00:00',
      'customer': {'full_name': 'Maheen Zubair', 'phone': '0599'},
      'rider': {'full_name': 'Ahmad', 'phone': '0598'},
      'order_items': [
        {
          'id': 'i1', 'order_id': 'o2', 'variant_id': 'v1', 'quantity': 1, 'unit_price': 450,
          'product_variants': {'size': 'M', 'colour': 'Terracotta', 'products': {'name': 'Terracotta Thobe'}},
        }
      ],
      'payments': {
        'id': 'p1', 'order_id': 'o2', 'screenshot_path': 'o2/proof.jpg',
        'verified': true, 'flagged': false, 'amount': 450,
      },
      'deliveries': [],
    });
    expect(o.customerName, 'Maheen Zubair');
    expect(o.riderName, 'Ahmad');
    expect(o.items.single.productName, 'Terracotta Thobe');
    expect(o.items.single.lineTotal, 450.0);
    expect(o.payment!.verified, isTrue);
    expect(o.delivery, isNull);
  });

  test('Product.fromJson reads variants and stock flags', () {
    final p = Product.fromJson({
      'id': 'p1', 'name': 'Dress', 'price': 215, 'is_active': true,
      'product_variants': [
        {'id': 'v1', 'product_id': 'p1', 'size': 'S', 'colour': 'Olive', 'stock': 1, 'low_stock_at': 2},
        {'id': 'v2', 'product_id': 'p1', 'size': 'M', 'colour': 'Olive', 'stock': 0},
      ],
    });
    expect(p.totalStock, 1);
    expect(p.variants[0].isLow, isTrue);
    expect(p.variants[1].inStock, isFalse);
  });

  test('UserRole home paths', () {
    expect(UserRole.admin.homePath, '/admin');
    expect(UserRole.fromDb('rider'), UserRole.rider);
  });
}

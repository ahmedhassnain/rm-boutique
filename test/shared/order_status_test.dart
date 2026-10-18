import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/shared/models/profile.dart';
import 'package:rm_boutique/shared/order_status.dart';

void main() {
  group('OrderStatus', () {
    test('the flow is confirmed -> paid -> packed -> dispatched -> delivered', () {
      expect(OrderStatus.values.map((s) => s.dbValue).toList(),
          ['confirmed', 'paid', 'packed', 'dispatched', 'delivered']);
      expect(OrderStatus.confirmed.next, OrderStatus.paid);
      expect(OrderStatus.dispatched.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
    });

    test('fromDb round-trips and rejects unknown values', () {
      for (final s in OrderStatus.values) {
        expect(OrderStatus.fromDb(s.dbValue), s);
      }
      expect(() => OrderStatus.fromDb('shipped'), throwsArgumentError);
    });

    test('only the right role can move each step', () {
      expect(OrderStatus.confirmed.canBeAdvancedBy(UserRole.admin), isTrue);
      expect(OrderStatus.packed.canBeAdvancedBy(UserRole.admin), isTrue);
      expect(OrderStatus.dispatched.canBeAdvancedBy(UserRole.rider), isTrue);
      expect(OrderStatus.dispatched.canBeAdvancedBy(UserRole.admin), isFalse);
      expect(OrderStatus.confirmed.canBeAdvancedBy(UserRole.customer), isFalse);
      expect(OrderStatus.delivered.canBeAdvancedBy(UserRole.rider), isFalse);
    });
  });
}

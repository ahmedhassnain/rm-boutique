import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/rider/viewmodels/rider_deliveries_viewmodel.dart';
import 'package:rm_boutique/shared/models/order.dart';
import 'package:rm_boutique/shared/order_status.dart';

import 'fakes.dart';

Order _order(String id, OrderStatus status) => Order(
      id: id,
      customerId: 'customer-1',
      status: status,
      deliveryAddress: '12 Olive St, Ramallah',
      total: 389,
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  group('RiderDeliveriesViewModel', () {
    test('splits orders into active (not delivered) and history (delivered)',
        () async {
      final repo = FakeOrderRepository()
        ..ordersToStream = [
          _order('a', OrderStatus.dispatched),
          _order('b', OrderStatus.delivered),
          _order('c', OrderStatus.packed),
          _order('d', OrderStatus.delivered),
        ];
      final vm = RiderDeliveriesViewModel(repo);
      await Future<void>.delayed(Duration.zero); // let the stream deliver

      expect(vm.loading, isFalse);
      expect(vm.active.map((o) => o.id), ['a', 'c']);
      expect(vm.history.map((o) => o.id), ['b', 'd']);
    });

    test('earnings is history length times the flat fee', () async {
      final repo = FakeOrderRepository()
        ..ordersToStream = [
          _order('a', OrderStatus.delivered),
          _order('b', OrderStatus.delivered),
          _order('c', OrderStatus.delivered),
        ];
      final vm = RiderDeliveriesViewModel(repo);
      await Future<void>.delayed(Duration.zero);

      expect(vm.earnings, 3 * kDeliveryFee);
    });

    test('sets a readable error when the stream fails', () async {
      final repo = FakeOrderRepository()..streamError = Exception('offline');
      final vm = RiderDeliveriesViewModel(repo);
      await Future<void>.delayed(Duration.zero);

      expect(vm.loading, isFalse);
      expect(vm.error, isNotNull);
    });
  });
}

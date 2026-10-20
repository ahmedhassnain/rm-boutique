import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/rider/viewmodels/delivery_detail_viewmodel.dart';
import 'package:rm_boutique/shared/models/order.dart';
import 'package:rm_boutique/shared/order_status.dart';

import 'fakes.dart';

Order _order(OrderStatus status) => Order(
      id: 'order-1',
      customerId: 'customer-1',
      status: status,
      deliveryAddress: '12 Olive St, Ramallah',
      total: 389,
      createdAt: DateTime(2026, 10, 1),
      customerName: 'Maheen Zubair',
      customerPhone: '+970500000000',
    );

void main() {
  group('DeliveryDetailViewModel', () {
    test('load() fetches the order by id', () async {
      final orders = FakeOrderRepository()
        ..orderToReturn = _order(OrderStatus.dispatched);
      final vm = DeliveryDetailViewModel(orders, FakeStorageRepository(), 'order-1');
      await Future<void>.delayed(Duration.zero);

      expect(vm.loading, isFalse);
      expect(vm.order?.id, 'order-1');
      expect(vm.order?.customerName, 'Maheen Zubair');
    });

    test('canMarkDelivered is true only once the order is dispatched', () async {
      final orders = FakeOrderRepository()
        ..orderToReturn = _order(OrderStatus.dispatched);
      final vm = DeliveryDetailViewModel(orders, FakeStorageRepository(), 'order-1');
      await Future<void>.delayed(Duration.zero);
      expect(vm.canMarkDelivered, isTrue);

      final deliveredOrders = FakeOrderRepository()
        ..orderToReturn = _order(OrderStatus.delivered);
      final deliveredVm =
          DeliveryDetailViewModel(deliveredOrders, FakeStorageRepository(), 'order-1');
      await Future<void>.delayed(Duration.zero);
      expect(deliveredVm.canMarkDelivered, isFalse);

      final packedOrders = FakeOrderRepository()
        ..orderToReturn = _order(OrderStatus.packed);
      final packedVm =
          DeliveryDetailViewModel(packedOrders, FakeStorageRepository(), 'order-1');
      await Future<void>.delayed(Duration.zero);
      expect(packedVm.canMarkDelivered, isFalse);
    });

    test('markDelivered uploads the photo for this order', () async {
      final orders = FakeOrderRepository()
        ..orderToReturn = _order(OrderStatus.dispatched);
      final storage = FakeStorageRepository();
      final vm = DeliveryDetailViewModel(orders, storage, 'order-1');
      await Future<void>.delayed(Duration.zero);

      await vm.markDelivered(photoBytes: Uint8List.fromList([1, 2, 3]));

      expect(storage.uploadCalled, isTrue);
      expect(storage.lastOrderId, 'order-1');
      expect(vm.uploading, isFalse);
      expect(vm.error, isNull);
    });

    test('shows a readable error when the upload fails', () async {
      final orders = FakeOrderRepository()
        ..orderToReturn = _order(OrderStatus.dispatched);
      final storage = FakeStorageRepository()..uploadError = Exception('network down');
      final vm = DeliveryDetailViewModel(orders, storage, 'order-1');
      await Future<void>.delayed(Duration.zero);

      await vm.markDelivered(photoBytes: Uint8List.fromList([1, 2, 3]));

      expect(vm.error, isNotNull);
      expect(vm.uploading, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/viewmodels/admin_orders_viewmodel.dart';

import 'fakes.dart';

void main() {
  late FakeOrderRepository repo;

  setUp(() {
    repo = FakeOrderRepository()
      ..orders = [
        makeOrder(id: 'order-aaaaaaaa', status: 'confirmed',
            payment: paymentJson()),
        makeOrder(id: 'order-bbbbbbbb', status: 'paid',
            customerName: 'Layla Haddad',
            payment: paymentJson(verified: true)),
        makeOrder(id: 'order-cccccccc', status: 'dispatched', riderId: 'r1'),
        makeOrder(id: 'order-dddddddd', status: 'delivered', riderId: 'r1'),
      ];
  });

  Future<AdminOrdersViewModel> start() async {
    final vm = AdminOrdersViewModel(repo);
    addTearDown(vm.dispose);
    await pumpEventQueue();
    return vm;
  }

  test('loads every order and stops showing the spinner', () async {
    final vm = await start();
    expect(vm.loading, false);
    expect(vm.error, isNull);
    expect(vm.orders.length, 4);
    expect(vm.visible.length, 4);
  });

  test('shows an error message when loading fails', () async {
    repo.fetchError = Exception('offline');
    final vm = await start();
    expect(vm.loading, false);
    expect(vm.error, isNotNull);
    expect(vm.orders, isEmpty);
  });

  test('"Needs action" is confirmed + paid + packed only', () async {
    final vm = await start();
    vm.setFilter(AdminOrderFilter.needsAction);
    expect(vm.visible.map((o) => o.id),
        ['order-aaaaaaaa', 'order-bbbbbbbb']);
    expect(vm.needsActionCount, 2);
  });

  test('"In transit" and "Delivered" filters', () async {
    final vm = await start();
    vm.setFilter(AdminOrderFilter.inTransit);
    expect(vm.visible.single.id, 'order-cccccccc');
    vm.setFilter(AdminOrderFilter.delivered);
    expect(vm.visible.single.id, 'order-dddddddd');
  });

  test('search matches customer name, id and address, case-insensitively',
      () async {
    final vm = await start();
    vm.setQuery('layla');
    expect(vm.visible.single.id, 'order-bbbbbbbb');
    vm.setQuery('ORDER-CCC');
    expect(vm.visible.single.id, 'order-cccccccc');
    vm.setQuery('bethlehem');
    expect(vm.visible.length, 4);
    vm.setQuery('nobody');
    expect(vm.visible, isEmpty);
  });

  test('chip and search work together', () async {
    final vm = await start();
    vm.setFilter(AdminOrderFilter.needsAction);
    vm.setQuery('layla');
    expect(vm.visible.single.id, 'order-bbbbbbbb');
    vm.setQuery('maheen'); // Maheen's orders that need action
    expect(vm.visible.length, 1);
  });

  test('payment filters sort orders by what the payment needs', () async {
    final vm = await start();
    expect(vm.paymentsFor(AdminPaymentFilter.toReview).single.id,
        'order-aaaaaaaa');
    expect(vm.paymentsFor(AdminPaymentFilter.verified).single.id,
        'order-bbbbbbbb');
    expect(vm.paymentsFor(AdminPaymentFilter.flagged), isEmpty);
    expect(vm.paymentsToReviewCount, 1);
  });

  test('a flagged payment is not counted as "to review"', () async {
    repo.orders = [
      makeOrder(payment: paymentJson(flagged: true)),
    ];
    final vm = await start();
    expect(vm.paymentsToReviewCount, 0);
    expect(vm.paymentsFor(AdminPaymentFilter.flagged).length, 1);
  });

  test('a confirmed order with no receipt is "no receipt yet"', () async {
    repo.orders = [makeOrder(status: 'confirmed')];
    final vm = await start();
    expect(vm.paymentsFor(AdminPaymentFilter.awaiting).length, 1);
  });

  test('a live change reloads the orders, but the first event does not',
      () async {
    final vm = await start();
    expect(repo.fetchOrdersCalls, 1);

    repo.ordersStream.add(repo.orders); // first event = current snapshot
    await pumpEventQueue();
    expect(repo.fetchOrdersCalls, 1);

    repo.ordersStream.add(repo.orders); // a real change
    await pumpEventQueue();
    expect(repo.fetchOrdersCalls, 2);
    expect(vm.loading, false);
  });

  test('a payment change also reloads the orders', () async {
    await start();
    repo.paymentsStream.add([]); // first event ignored
    repo.paymentsStream.add([]); // real change
    await pumpEventQueue();
    expect(repo.fetchOrdersCalls, 2);
  });

  test('a failed silent reload keeps the orders already on screen', () async {
    final vm = await start();
    repo.fetchError = Exception('offline');
    await vm.load(silent: true);
    expect(vm.orders.length, 4);
    expect(vm.error, isNull);
  });
}

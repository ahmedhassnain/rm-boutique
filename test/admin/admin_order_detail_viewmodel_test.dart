import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/viewmodels/admin_order_detail_viewmodel.dart';
import 'package:rm_boutique/shared/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

void main() {
  late FakeOrderRepository repo;

  Future<AdminOrderDetailViewModel> open() async {
    final vm = AdminOrderDetailViewModel(
        repo, FakeStorageRepository(), 'order-12345678');
    addTearDown(vm.dispose);
    await pumpEventQueue();
    return vm;
  }

  setUp(() {
    repo = FakeOrderRepository()
      ..riders = const [
        Profile(id: 'r1', role: UserRole.rider, fullName: 'Ahmad Mousa'),
      ];
  });

  test('loads the order, the riders and a link to the receipt', () async {
    repo.single = makeOrder(payment: paymentJson());
    final vm = await open();
    expect(vm.loading, false);
    expect(vm.order, isNotNull);
    expect(vm.riders.length, 1);
    expect(vm.proofUrl, contains('payment-proofs'));
  });

  test('shows an error when the order cannot be loaded', () async {
    repo.fetchError = Exception('offline');
    final vm = await open();
    expect(vm.order, isNull);
    expect(vm.error, isNotNull);
  });

  test('confirmed + unverified payment: button is blocked with a reason',
      () async {
    repo.single = makeOrder(payment: paymentJson());
    final vm = await open();
    expect(vm.advanceLabel, 'Mark as paid');
    expect(vm.advanceBlocker, contains('Approve the payment'));
    expect(vm.canAdvance, false);
  });

  test('confirmed + no receipt at all: also blocked', () async {
    repo.single = makeOrder();
    final vm = await open();
    expect(vm.canAdvance, false);
  });

  test('confirmed + verified payment: can mark as paid', () async {
    repo.single = makeOrder(payment: paymentJson(verified: true));
    final vm = await open();
    expect(vm.advanceBlocker, isNull);
    expect(vm.canAdvance, true);
    expect(await vm.advance(), true);
    expect(repo.actions, ['advance:confirmed']);
  });

  test('paid -> packed needs nothing else', () async {
    repo.single = makeOrder(status: 'paid');
    final vm = await open();
    expect(vm.advanceLabel, 'Mark as packed');
    expect(vm.canAdvance, true);
  });

  test('packed without a rider: dispatch is blocked', () async {
    repo.single = makeOrder(status: 'packed');
    final vm = await open();
    expect(vm.advanceLabel, 'Dispatch to rider');
    expect(vm.advanceBlocker, contains('Assign a rider'));
    expect(vm.canAdvance, false);
  });

  test('packed with a rider: can dispatch', () async {
    repo.single = makeOrder(status: 'packed', riderId: 'r1');
    final vm = await open();
    expect(vm.canAdvance, true);
  });

  test('dispatched and delivered orders belong to the rider', () async {
    repo.single = makeOrder(status: 'dispatched', riderId: 'r1');
    var vm = await open();
    expect(vm.advanceLabel, isNull);
    expect(vm.canAdvance, false);
    expect(vm.canAssignRider, false);

    repo.single = makeOrder(status: 'delivered', riderId: 'r1');
    vm = await open();
    expect(vm.advanceLabel, isNull);
    expect(vm.canAdvance, false);
  });

  test('approve, flag and assign call the repository', () async {
    repo.single = makeOrder(payment: paymentJson());
    final vm = await open();
    expect(await vm.approvePayment(), true);
    expect(await vm.flagPayment(), true);
    expect(await vm.assignRider('r1'), true);
    expect(repo.actions, ['approve', 'flag', 'assign:r1']);
    expect(vm.busy, false);
  });

  test('a database refusal becomes a readable message', () async {
    repo.single = makeOrder(status: 'paid');
    repo.actionError =
        PostgrestException(message: 'Assign a rider before dispatching');
    final vm = await open();
    expect(await vm.advance(), false);
    expect(vm.actionError, 'Assign a rider before dispatching');
    expect(vm.busy, false);
  });

  test('any other failure shows a generic message', () async {
    repo.single = makeOrder(status: 'paid');
    repo.actionError = Exception('boom');
    final vm = await open();
    await vm.advance();
    expect(vm.actionError, isNotNull);
  });

  test('advance does nothing when the button should be off', () async {
    repo.single = makeOrder(status: 'packed'); // no rider
    final vm = await open();
    expect(await vm.advance(), false);
    expect(repo.actions, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/viewmodels/add_order_viewmodel.dart';
import 'package:rm_boutique/shared/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

void main() {
  late FakeProductRepository repo;
  late FakeOrderRepository orders;

  Future<AddOrderViewModel> start() async {
    final vm = AddOrderViewModel(repo, orders);
    addTearDown(vm.dispose);
    await pumpEventQueue();
    return vm;
  }

  setUp(() {
    repo = FakeProductRepository()
      ..products = [makeProduct(stocks: [3, 0])];
    orders = FakeOrderRepository()
      ..customers = [
        const Profile(
            id: 'c1',
            role: UserRole.customer,
            fullName: 'Maheen Zubair',
            phone: '0599123456'),
      ];
  });

  test('loads active products', () async {
    final vm = await start();
    expect(vm.loading, false);
    expect(vm.products.length, 1);
  });

  test('adding items builds a total (price x quantity)', () async {
    final vm = await start();
    final p = vm.products.first;
    vm.addLine(p, p.variants[0], 2);
    expect(vm.itemCount, 2);
    expect(vm.total, 900); // 2 x 450
  });

  test('the same size added twice becomes one line', () async {
    final vm = await start();
    final p = vm.products.first;
    vm.addLine(p, p.variants[0], 1);
    vm.addLine(p, p.variants[0], 1);
    expect(vm.lines.length, 1);
    expect(vm.lines.single.quantity, 2);
  });

  test('quantity never goes above the stock on the shelf', () async {
    final vm = await start();
    final p = vm.products.first;
    vm.addLine(p, p.variants[0], 10);
    expect(vm.lines.single.quantity, 3);
  });

  test('a sold-out size cannot be added', () async {
    final vm = await start();
    final p = vm.products.first;
    vm.addLine(p, p.variants[1], 1);
    expect(vm.lines, isEmpty);
  });

  test('lines can be removed', () async {
    final vm = await start();
    final p = vm.products.first;
    vm.addLine(p, p.variants[0], 1);
    vm.removeLine(vm.lines.single);
    expect(vm.lines, isEmpty);
    expect(vm.total, 0);
  });

  test('loads the registered customers for the picker', () async {
    final vm = await start();
    expect(vm.customers.single.fullName, 'Maheen Zubair');
    expect(vm.canSave, false); // no customer and no items yet
  });

  test('cannot save without a customer or without items', () async {
    final vm = await start();
    final p = vm.products.first;
    vm.addLine(p, p.variants[0], 1);
    expect(vm.canSave, false); // still no customer
    vm.selectCustomer(vm.customers.first);
    expect(vm.canSave, true);
    vm.removeLine(vm.lines.single);
    expect(vm.canSave, false); // no items
    expect(await vm.save(address: 'Bethlehem'), isNull);
    expect(orders.adminOrders, isEmpty);
  });

  test('saving sends the order for the chosen customer and empties the basket',
      () async {
    final vm = await start();
    final p = vm.products.first;
    vm.selectCustomer(vm.customers.first);
    vm.addLine(p, p.variants[0], 2);
    vm.setLocation(31.7, 35.2);

    final id = await vm.save(address: '  Parkhill, Bethlehem ', notes: ' ');
    expect(id, 'new-order-id');
    expect(orders.adminOrders, ['c1']);
    expect(orders.lastAdminItems!.single.quantity, 2);
    expect(orders.lastAdminItems!.single.variantId, p.variants[0].id);
    expect(vm.lines, isEmpty);
    expect(vm.saveError, isNull);
    expect(vm.saving, false);
  });

  test('a database refusal is shown and the basket is kept', () async {
    final vm = await start();
    final p = vm.products.first;
    orders.adminOrderError =
        const PostgrestException(message: 'Not enough stock for one of the items');
    vm.selectCustomer(vm.customers.first);
    vm.addLine(p, p.variants[0], 1);

    final id = await vm.save(address: 'Bethlehem');
    expect(id, isNull);
    expect(vm.saveError, 'Not enough stock for one of the items');
    expect(vm.lines.length, 1);
    expect(vm.saving, false);
  });
}

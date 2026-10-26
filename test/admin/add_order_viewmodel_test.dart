import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/viewmodels/add_order_viewmodel.dart';

import 'fakes.dart';

void main() {
  late FakeProductRepository repo;

  Future<AddOrderViewModel> start() async {
    final vm = AddOrderViewModel(repo);
    addTearDown(vm.dispose);
    await pumpEventQueue();
    return vm;
  }

  setUp(() {
    repo = FakeProductRepository()
      ..products = [makeProduct(stocks: [3, 0])];
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
}

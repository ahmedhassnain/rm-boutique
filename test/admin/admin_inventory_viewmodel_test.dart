import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/viewmodels/admin_inventory_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

void main() {
  late FakeProductRepository repo;

  setUp(() {
    repo = FakeProductRepository()
      ..products = [
        makeProduct(id: 'p1', name: 'Terracotta Thobe', stocks: [10, 2, 0]),
        makeProduct(id: 'p2', name: 'Olive Abaya', stocks: [8, 9]),
      ];
  });

  Future<AdminInventoryViewModel> start() async {
    final vm = AdminInventoryViewModel(repo);
    addTearDown(vm.dispose);
    await pumpEventQueue();
    return vm;
  }

  test('loads the catalogue', () async {
    final vm = await start();
    expect(vm.loading, false);
    expect(vm.products.length, 2);
  });

  test('alerts list every size that is low or sold out', () async {
    final vm = await start();
    // p1: M has 2 (low, alert level is 2) and L has 0 (sold out).
    expect(vm.alerts.length, 2);
    expect(vm.alerts.map((a) => a.variant.size), ['M', 'L']);
  });

  test('"Low stock" and "Sold out" chips narrow products and sizes', () async {
    final vm = await start();
    vm.setFilter(AdminStockFilter.low);
    expect(vm.visibleProducts.single.id, 'p1');
    expect(vm.variantsFor(vm.visibleProducts.single).single.size, 'M');

    vm.setFilter(AdminStockFilter.soldOut);
    expect(vm.variantsFor(vm.visibleProducts.single).single.size, 'L');

    vm.setFilter(AdminStockFilter.all);
    expect(vm.visibleProducts.length, 2);
    expect(vm.variantsFor(vm.visibleProducts.first).length, 3);
  });

  test('search matches the product name', () async {
    final vm = await start();
    vm.setQuery('abaya');
    expect(vm.visibleProducts.single.id, 'p2');
  });

  test('setStock saves the new number', () async {
    final vm = await start();
    final variant = vm.products.first.variants.first;
    expect(await vm.setStock(variant, 12), true);
    expect(repo.updates, ['p1-v0=12']);
    expect(vm.savingVariantId, isNull);
  });

  test('a negative stock is refused without calling the database', () async {
    final vm = await start();
    expect(await vm.setStock(vm.products.first.variants.first, -1), false);
    expect(repo.updates, isEmpty);
  });

  test('a database refusal is reported', () async {
    repo.updateError = PostgrestException(message: 'Not allowed');
    final vm = await start();
    expect(await vm.setStock(vm.products.first.variants.first, 5), false);
    expect(vm.actionError, 'Not allowed');
  });

  test('a live stock change reloads the catalogue', () async {
    final vm = await start();
    repo.products = [makeProduct(id: 'p1', stocks: [1])];
    repo.variantsStream.add([]); // first event ignored
    repo.variantsStream.add([]); // real change
    await pumpEventQueue();
    expect(vm.products.length, 1);
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/admin/viewmodels/product_form_viewmodel.dart';
import 'package:rm_boutique/shared/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';

void main() {
  late FakeProductRepository repo;
  late FakeStorageRepository storage;

  setUp(() {
    repo = FakeProductRepository();
    storage = FakeStorageRepository();
  });

  ProductFormViewModel form({Product? editing}) {
    final vm = ProductFormViewModel(repo, storage, editing: editing);
    addTearDown(vm.dispose);
    return vm;
  }

  const oneSize = [VariantInput(size: 'M', colour: 'Olive', stock: '3')];

  group('validation', () {
    String? check({
      String name = 'Olive Dress',
      String price = '450',
      String category = 'Dresses',
      List<VariantInput> variants = oneSize,
      bool isNew = true,
    }) =>
        ProductFormViewModel.validate(
          name: name,
          priceText: price,
          category: category,
          variants: variants,
          isNew: isNew,
        );

    test('a good form passes', () => expect(check(), isNull));
    test('name is required', () => expect(check(name: ' '), isNotNull));
    test('price must be above zero', () {
      expect(check(price: '0'), isNotNull);
      expect(check(price: '-5'), isNotNull);
      expect(check(price: 'abc'), isNotNull);
      expect(check(price: ''), isNotNull);
    });
    test('price accepts a decimal comma', () {
      expect(ProductFormViewModel.parsePrice('450,50'), 450.5);
      expect(ProductFormViewModel.parsePrice('450.499'), 450.5);
    });
    test('a new product needs a size', () {
      expect(check(variants: const []), isNotNull);
      expect(check(variants: const [], isNew: false), isNull);
    });
    test('stock must be a whole number, 0 or more', () {
      expect(check(variants: const [VariantInput(size: 'M', stock: '-1')]), isNotNull);
      expect(check(variants: const [VariantInput(size: 'M', stock: '1.5')]), isNotNull);
      expect(check(variants: const [VariantInput(size: 'M', stock: '0')]), isNull);
    });
    test('the same size and colour twice is refused', () {
      expect(
        check(variants: const [
          VariantInput(size: 'M', colour: 'Olive', stock: '1'),
          VariantInput(size: 'm', colour: 'olive', stock: '2'),
        ]),
        contains('twice'),
      );
    });
  });

  group('edit', () {
    test('saves the new details and keeps stock untouched', () async {
      final vm = form(editing: makeProduct(stocks: [3]));
      final ok = await vm.save(
        name: ' Terracotta Thobe ',
        priceText: '480',
        description: 'Hand embroidered',
        category: 'Thobes',
        isActive: false,
      );
      expect(ok, true);
      expect(repo.productWrites, ['update p1 Terracotta Thobe|Thobes|480.0|false']);
      expect(repo.updates, isEmpty);
    });

    test('an invalid form writes nothing', () async {
      final vm = form(editing: makeProduct(stocks: [3]));
      final ok = await vm.save(
          name: '', priceText: '480', description: '', category: 'Dresses', isActive: true);
      expect(ok, false);
      expect(vm.error, isNotNull);
      expect(repo.productWrites, isEmpty);
    });

    test('a new photo replaces and removes the old one', () async {
      final product = Product(
          id: 'p1', name: 'Thobe', price: 450, imagePath: 'p1/old.jpg');
      final vm = form(editing: product);
      final ok = await vm.save(
        name: 'Thobe',
        priceText: '450',
        description: '',
        category: 'Dresses',
        isActive: true,
        photo: Uint8List.fromList([1, 2, 3]),
      );
      expect(ok, true);
      expect(repo.productWrites.last, 'image p1 p1/new.jpg');
      expect(storage.removed, ['p1/old.jpg']);
    });

    test('a database refusal is shown and nothing else happens', () async {
      repo.updateError = const PostgrestException(message: 'permission denied');
      final vm = form(editing: makeProduct(stocks: [3]));
      final ok = await vm.save(
          name: 'Thobe', priceText: '450', description: '', category: 'Dresses', isActive: true);
      expect(ok, false);
      expect(vm.error, 'permission denied');
      expect(vm.saving, false);
    });
  });

  group('new product', () {
    test('creates the product, then its sizes, then the photo', () async {
      final vm = form();
      final ok = await vm.save(
        name: 'Olive Dress',
        priceText: '390',
        description: '',
        category: 'Dresses',
        isActive: true,
        variants: const [
          VariantInput(size: 'S', colour: 'Olive', stock: '2'),
          VariantInput(size: 'M', stock: '4'),
        ],
        photo: Uint8List.fromList([1]),
      );
      expect(ok, true);
      expect(repo.productWrites, [
        'create Olive Dress|Dresses|390.0|true',
        'variants new-id S/Olive/2,M/Standard/4',
        'image new-id new-id/new.jpg',
      ]);
      expect(vm.warning, isNull);
    });

    test('if the sizes fail, the half-made product is removed again', () async {
      repo.variantsError = const PostgrestException(message: 'boom');
      final vm = form();
      final ok = await vm.save(
        name: 'Olive Dress',
        priceText: '390',
        description: '',
        category: 'Dresses',
        isActive: true,
        variants: oneSize,
      );
      expect(ok, false);
      expect(repo.productWrites.last, 'delete new-id');
      expect(vm.error, 'boom');
    });

    test('if only the photo fails, the product stays and a warning shows', () async {
      storage.uploadError = Exception('offline');
      final vm = form();
      final ok = await vm.save(
        name: 'Olive Dress',
        priceText: '390',
        description: '',
        category: 'Dresses',
        isActive: true,
        variants: oneSize,
        photo: Uint8List.fromList([1]),
      );
      expect(ok, true);
      expect(vm.warning, contains('photo'));
      expect(repo.productWrites.any((w) => w.startsWith('delete')), false);
    });
  });
}

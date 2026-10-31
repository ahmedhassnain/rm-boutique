import 'package:flutter_test/flutter_test.dart';
import 'package:rm_boutique/features/customer/viewmodels/cart_viewmodel.dart';

CartItem _item({
  String variantId = 'v1',
  String name = 'Tatreez Evening Dress',
  double price = 389,
  int quantity = 1,
  int max = 3,
}) =>
    CartItem(
      variantId: variantId,
      productName: name,
      variantLabel: 'Olive · M',
      unitPrice: price,
      quantity: quantity,
      maxQuantity: max,
    );

void main() {
  test('starts empty', () {
    final cart = CartViewModel();
    expect(cart.isEmpty, true);
    expect(cart.count, 0);
    expect(cart.total, 0);
  });

  test('several products add up to one total and one count', () {
    final cart = CartViewModel()
      ..add(_item(variantId: 'v1', price: 389, quantity: 2))
      ..add(_item(variantId: 'v2', name: 'Clutch', price: 95, quantity: 1));
    expect(cart.items.length, 2);
    expect(cart.count, 3);
    expect(cart.total, 873); // 2 x 389 + 95
  });

  test('the same size and colour merges into one line, capped at stock', () {
    final cart = CartViewModel()
      ..add(_item(quantity: 2, max: 3))
      ..add(_item(quantity: 2, max: 3));
    expect(cart.items.length, 1);
    expect(cart.items.single.quantity, 3);
  });

  test('quantity can change but never beyond the stock', () {
    final cart = CartViewModel()..add(_item(quantity: 1, max: 2));
    cart.setQuantity('v1', 2);
    expect(cart.items.single.quantity, 2);
    cart.setQuantity('v1', 9);
    expect(cart.items.single.quantity, 2);
  });

  test('a quantity of zero removes the line', () {
    final cart = CartViewModel()..add(_item());
    cart.setQuantity('v1', 0);
    expect(cart.isEmpty, true);
  });

  test('remove and clear', () {
    final cart = CartViewModel()
      ..add(_item(variantId: 'v1'))
      ..add(_item(variantId: 'v2'));
    cart.remove('v1');
    expect(cart.items.single.variantId, 'v2');
    cart.clear();
    expect(cart.isEmpty, true);
  });

  test('lines sent to the database carry only the variant and quantity', () {
    final cart = CartViewModel()..add(_item(quantity: 2));
    expect(cart.items.single.toLine().toJson(),
        {'variant_id': 'v1', 'quantity': 2});
  });

  test('a different person signing in starts with an empty basket', () {
    final cart = CartViewModel()..bindTo('maheen');
    cart.add(_item());
    cart.bindTo('maheen'); // same person: kept
    expect(cart.count, 1);
    cart.bindTo('someone-else');
    expect(cart.isEmpty, true);
  });
}

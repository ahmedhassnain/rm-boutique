/// One line of a basket: which size/colour and how many.
/// This is exactly what place_order() expects.
class CartLine {
  const CartLine({required this.variantId, required this.quantity});

  final String variantId;
  final int quantity;

  Map<String, dynamic> toJson() =>
      {'variant_id': variantId, 'quantity': quantity};
}

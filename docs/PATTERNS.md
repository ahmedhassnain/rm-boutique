# How to build a screen (copy these patterns)

We use MVVM with Provider: a **view** (the screen), a **view-model** (state and actions,
a `ChangeNotifier`), and the shared **repositories** (the only code that talks to Supabase).

## 1. Get data: view-model + screen

```dart
// lib/features/customer/viewmodels/products_viewmodel.dart
class ProductsViewModel extends ChangeNotifier {
  ProductsViewModel(this._products);
  final ProductRepository _products;

  List<Product> items = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try {
      items = await _products.fetchProducts();
    } catch (e) {
      error = 'Could not load products. Check your connection.';
    }
    loading = false; notifyListeners();
  }
}
```

```dart
// lib/features/customer/views/products_screen.dart
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ProductsViewModel(c.read<ProductRepository>())..load(),
      child: Consumer<ProductsViewModel>(builder: (context, vm, _) {
        if (vm.loading) return const Center(child: CircularProgressIndicator());
        if (vm.error != null) return Center(child: Text(vm.error!));
        return ListView(children: [for (final p in vm.items) ListTile(title: Text(p.name))]);
      }),
    );
  }
}
```

Add the route in `lib/core/router.dart` under your role, e.g.
`GoRoute(path: 'products', builder: (_, __) => const ProductsScreen())`, and open it
with `context.go('/customer/products')`.

## 2. Live data (orders, stock)

Use a stream and `StreamBuilder` (see `lib/core/widgets/orders_feed.dart`):
`orders.watchOrders()` for lists, `orders.watchOrder(id)` for a tracking screen,
`products.watchVariants()` for live stock. For names, items and payment info on a
detail screen use `orders.fetchOrder(id)`.

## 3. Common actions

| Who | Task | Call |
|---|---|---|
| Customer | place an order | `orders.placeOrder(address:, items: [CartLine(variantId:, quantity:)], lat:, lng:, neededBy:)` |
| Customer | attach payment screenshot | `final bytes = await pickCompressedImage();` then `storage.uploadPaymentProof(orderId:, bytes:, amount:)` |
| Admin | approve or flag a payment | `orders.reviewPayment(orderId, approved: true)` |
| Admin | assign a rider | `orders.fetchRiders()` then `orders.assignRider(orderId, riderId)` |
| Admin | move to the next step | `orders.advanceStatus(order)` |
| Admin | change stock | `products.updateStock(variantId, 5)` |
| Rider | confirm delivery | `final bytes = await pickCompressedImage(source: ImageSource.camera);` then `storage.uploadDeliveryProof(orderId:, bytes:)` |
| Anyone | show a private image | `storage.signedUrl('payment-proofs', path)` or `('delivery-photos', path)`, then `Image.network(url)` |
| Anyone | show a product photo | `storage.productImageUrl(path)` |

Errors from the database are readable (`PostgrestException.message`), e.g.
"Not enough stock for one of the items", "Verify the payment before marking the order as paid".
Show them to the user.

## 4. Rules

- Screens never call `supabase.from(...)` directly. Need something new? Add a method to a repository.
- Always show a status with `StatusChip(order.status)`.
- Colours and fonts come from `AppColors` and the theme; no hard-coded hex in screens.
- Compress every photo with `pickCompressedImage()` before uploading.

## 5. Tests (3-5 per role)

Unit-test your view-model with a fake repository; widget-test one screen. Example idea for
Customer: `ProductsViewModel.load()` sets `items`; sets `error` when the repository throws.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/views/add_order_screen.dart';
import '../features/admin/views/admin_home_screen.dart';
import '../features/admin/views/admin_order_detail_screen.dart';
import '../features/admin/views/product_form_screen.dart';
import '../shared/models/product.dart';
import '../features/auth/auth_controller.dart';
import '../features/chat/chat_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/customer/views/cart_screen.dart';
import '../features/customer/views/checkout_screen.dart';
import '../features/customer/views/customer_home_screen.dart';
import '../features/customer/views/my_orders_screen.dart';
import '../features/customer/views/order_detail_screen.dart';
import '../features/customer/views/product_detail_screen.dart';
import '../features/customer/views/size_guide_screen.dart';
import '../features/rider/views/delivery_detail_screen.dart';
import '../features/rider/views/rider_home_screen.dart';

/// Role-based routing.
///   not signed in -> /login
///   admin    -> everything under /admin
///   customer -> everything under /customer
///   rider    -> everything under /rider
/// Nobody can open another role's area, even by typing the address.
///
/// TO ADD A SCREEN: add a child route under your role's route below, e.g.
///   GoRoute(path: 'checkout', builder: (_, __) => const CheckoutScreen())
/// then open it with  context.go('/customer/checkout').
GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onAuthPage = loc == '/login' || loc == '/register';

      if (auth.loading) return loc == '/' ? null : '/';
      if (!auth.isSignedIn) return onAuthPage ? null : '/login';

      final home = auth.profile!.role.homePath;
      if (loc == '/' || onAuthPage) return home;
      if (!loc.startsWith(home)) return home;
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Splash()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminHomeScreen(),
        routes: [
          GoRoute(
            path: 'order/:id',
            builder: (_, state) =>
                AdminOrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(path: 'add-order', builder: (_, __) => const AddOrderScreen()),
          // New product (no extra) or Edit details (the Product as extra).
          GoRoute(
            path: 'product',
            builder: (_, state) => ProductFormScreen(
              product: state.extra is Product ? state.extra as Product : null,
            ),
          ),
          // One customer's conversation, opened from the Inbox. The customer's
          // name and role travel along as `extra` (a ChatRouteArgs).
          GoRoute(
            path: 'chat/:memberId',
            builder: (_, state) {
              final args = state.extra is ChatRouteArgs
                  ? state.extra as ChatRouteArgs
                  : null;
              return ChatScreen(
                memberId: state.pathParameters['memberId']!,
                asAdmin: true,
                isRider: args?.isRider ?? false,
                title: args?.name ?? 'Conversation',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/customer',
        builder: (_, __) => const CustomerHomeScreen(),
        routes: [
          // Maheen: add customer screens here
          GoRoute(
            path: 'product/:id',
            builder: (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
              path: 'size-guide', builder: (_, __) => const SizeGuideScreen()),
          GoRoute(
            path: 'checkout',
            builder: (_, state) =>
                CheckoutScreen(args: state.extra as CheckoutArgs),
          ),
          GoRoute(path: 'cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: 'orders', builder: (_, __) => const MyOrdersScreen()),
          // The customer's own conversation with the boutique.
          GoRoute(
            path: 'chat',
            builder: (_, __) => ChatScreen(
              memberId: auth.profile!.id,
              asAdmin: false,
              title: 'Message R&M Boutique',
            ),
          ),
          GoRoute(
            path: 'order/:id',
            builder: (_, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/rider',
        builder: (_, __) => const RiderHomeScreen(),
        routes: [
          // The rider's own conversation with the boutique.
          GoRoute(
            path: 'chat',
            builder: (_, __) => ChatScreen(
              memberId: auth.profile!.id,
              asAdmin: false,
              isRider: true,
              title: 'Message R&M Boutique',
            ),
          ),
          // Ahmad: add rider screens here
          GoRoute(
            path: 'delivery/:id',
            builder: (_, state) =>
                DeliveryDetailScreen(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

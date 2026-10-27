import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/views/admin_home_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/customer/views/customer_home_screen.dart';
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
        routes: const [
          // Ahmed: add admin screens here
        ],
      ),
      GoRoute(
        path: '/customer',
        builder: (_, __) => const CustomerHomeScreen(),
        routes: const [
          // Maheen: add customer screens here
        ],
      ),
      GoRoute(
        path: '/rider',
        builder: (_, __) => const RiderHomeScreen(),
        routes: [
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

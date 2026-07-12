import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/screens/language_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/pending_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/cart/screens/checkout_screen.dart';
import '../features/catalog/screens/catalog_screen.dart';
import '../features/catalog/screens/home_screen.dart';
import '../features/catalog/screens/product_detail_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'buyer_shell.dart';

/// Bridges a Riverpod provider to a [Listenable] for GoRouter refresh.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      const authRoutes = {'/login', '/register', '/language'};

      switch (auth.status) {
        case AuthStatus.unknown:
          return loc == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          if (loc == '/splash') return '/login';
          return authRoutes.contains(loc) ? null : '/login';
        case AuthStatus.pending:
          return loc == '/pending' ? null : '/pending';
        case AuthStatus.authenticated:
          if (loc == '/splash' || loc == '/pending' || authRoutes.contains(loc)) {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingScreen()),
      GoRoute(
        path: '/products',
        builder: (_, s) => CatalogScreen(
          initialCategoryId: int.tryParse(s.uri.queryParameters['category'] ?? ''),
          initialFactoryId: int.tryParse(s.uri.queryParameters['factory'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, s) => ProductDetailScreen(productId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
        path: '/order/:id',
        builder: (_, s) => OrderDetailScreen(orderId: int.parse(s.pathParameters['id']!)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => BuyerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/cart', builder: (_, __) => const CartScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});

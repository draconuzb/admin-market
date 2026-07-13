import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/screens/admin_products_screen.dart';
import '../features/admin/screens/admin_registrations_screen.dart';
import '../features/admin/screens/admin_reports_screen.dart';
import '../features/admin/screens/admin_settings_screen.dart';
import '../features/admin/screens/admin_shell.dart';
import '../features/admin/screens/admin_users_screen.dart';
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
import '../features/factory/screens/factory_order_detail_screen.dart';
import '../features/factory/screens/factory_orders_screen.dart';
import '../features/factory/screens/factory_products_screen.dart';
import '../features/factory/screens/factory_shell.dart';
import '../features/factory/screens/factory_stats_screen.dart';
import '../features/factory/screens/product_form_screen.dart';
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

/// Landing route per role after login.
String _roleHome(String? role) => switch (role) {
      'factory' => '/factory/orders',
      'admin' => '/admin/registrations',
      _ => '/home', // shop | distributor
    };

/// Route prefixes each role is allowed to view.
const _buyerPrefixes = [
  '/home', '/catalog', '/cart', '/orders', '/order', '/products', '/product',
  '/checkout', '/profile',
];

bool _allowed(String role, String loc) => switch (role) {
      'factory' => loc.startsWith('/factory'),
      'admin' => loc.startsWith('/admin'),
      _ => _buyerPrefixes.any((p) => loc == p || loc.startsWith('$p/') || loc.startsWith('$p?')),
    };

/// iOS-style slide transition for pushed routes.
CupertinoPage<void> _slide(GoRouterState state, Widget child) =>
    CupertinoPage<void>(key: state.pageKey, child: child);

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
          final role = auth.user?.role ?? 'shop';
          final home = _roleHome(role);
          if (loc == '/splash' || loc == '/pending' || authRoutes.contains(loc)) {
            return home;
          }
          // Keep each role inside its own section.
          return _allowed(role, loc) ? null : home;
      }
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/language', builder: (_, __) => const LanguageScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/pending', builder: (_, __) => const PendingScreen()),

      // ---- Buyer pushed routes (iOS slide transitions) ----
      GoRoute(
        path: '/products',
        pageBuilder: (_, s) => _slide(
          s,
          CatalogScreen(
            initialCategoryId: int.tryParse(s.uri.queryParameters['category'] ?? ''),
            initialFactoryId: int.tryParse(s.uri.queryParameters['factory'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (_, s) =>
            _slide(s, ProductDetailScreen(productId: int.parse(s.pathParameters['id']!))),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (_, s) => _slide(s, const CheckoutScreen()),
      ),
      GoRoute(
        path: '/order/:id',
        pageBuilder: (_, s) =>
            _slide(s, OrderDetailScreen(orderId: int.parse(s.pathParameters['id']!))),
      ),

      // ---- Factory pushed routes ----
      GoRoute(
        path: '/factory/order/:id',
        pageBuilder: (_, s) =>
            _slide(s, FactoryOrderDetailScreen(orderId: int.parse(s.pathParameters['id']!))),
      ),
      GoRoute(
        path: '/factory/product/new',
        pageBuilder: (_, s) => _slide(s, const ProductFormScreen()),
      ),
      GoRoute(
        path: '/factory/product/:id/edit',
        pageBuilder: (_, s) =>
            _slide(s, ProductFormScreen(productId: int.parse(s.pathParameters['id']!))),
      ),

      // ---- Buyer shell ----
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => BuyerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, __) => const CartScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),

      // ---- Factory shell ----
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => FactoryShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/factory/orders', builder: (_, __) => const FactoryOrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/factory/products', builder: (_, __) => const FactoryProductsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/factory/stats', builder: (_, __) => const FactoryStatsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/factory/profile', builder: (_, __) => const ProfileScreen())]),
        ],
      ),

      // ---- Admin shell (web) ----
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/admin/registrations', builder: (_, __) => const AdminRegistrationsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/admin/products', builder: (_, __) => const AdminProductsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/admin/settings', builder: (_, __) => const AdminSettingsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/admin/reports', builder: (_, __) => const AdminReportsScreen())]),
        ],
      ),
    ],
  );
});

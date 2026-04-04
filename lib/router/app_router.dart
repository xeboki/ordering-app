import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/features/account/account_screen.dart';
import 'package:xeboki_ordering/features/appointments/appointments_screen.dart';
import 'package:xeboki_ordering/features/auth/login_screen.dart';
import 'package:xeboki_ordering/features/auth/register_screen.dart';
import 'package:xeboki_ordering/features/cart/cart_screen.dart';
import 'package:xeboki_ordering/features/catalog/catalog_screen.dart';
import 'package:xeboki_ordering/features/checkout/checkout_screen.dart';
import 'package:xeboki_ordering/features/home/home_screen.dart';
import 'package:xeboki_ordering/features/offers/offers_screen.dart';
import 'package:xeboki_ordering/features/order_tracking/order_tracking_screen.dart';
import 'package:xeboki_ordering/features/orders/order_detail_screen.dart';
import 'package:xeboki_ordering/features/orders/orders_screen.dart';
import 'package:xeboki_ordering/features/location/location_picker_screen.dart';
import 'package:xeboki_ordering/features/splash/splash_screen.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final isGuest = ref.watch(guestModeProvider);
  final brand = ref.watch(brandProvider);
  final requireAuth = brand.features.customerAuth;

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onAuthPage = loc == '/login' || loc == '/register';
      final onSplash = loc == '/splash' || loc == '/pick-location';

      if (onSplash) return null;
      if (requireAuth && !isLoggedIn && !isGuest && !onAuthPage) return '/login';
      if ((isLoggedIn || isGuest) && onAuthPage) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/pick-location',
        builder: (_, __) => const LocationPickerScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/cart',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootKey,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/track/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => OrderTrackingScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const CatalogScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (_, __) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/offers',
            builder: (_, __) => const OffersScreen(),
          ),
          GoRoute(
            path: '/account',
            builder: (_, __) => const AccountScreen(),
          ),
        ],
      ),
    ],
  );
});

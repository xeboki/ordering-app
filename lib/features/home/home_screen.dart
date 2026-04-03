import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';
import 'package:xeboki_ordering/providers/cart_providers.dart';

class HomeScreen extends ConsumerWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final brand = ref.watch(brandProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);

    final showAppointments = brand.features.appointments != 'false' &&
        (brand.features.appointments == 'true' ||
            brand.businessType == 'salon' ||
            brand.businessType == 'gym' ||
            brand.businessType == 'service');

    final showOffers = brand.features.loyalty || brand.features.discountCodes;

    final tabs = <_NavTab>[
      _NavTab(
          path: '/',
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront,
          label: l10n.navShop),
      _NavTab(
          path: '/orders',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long,
          label: l10n.navOrders),
      if (showOffers)
        _NavTab(
            path: '/offers',
            icon: Icons.local_offer_outlined,
            activeIcon: Icons.local_offer,
            label: 'Offers'),
      if (showAppointments && isLoggedIn)
        _NavTab(
            path: '/appointments',
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: l10n.navBookings),
      _NavTab(
          path: '/account',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: l10n.navAccount),
    ];

    int currentIndex = tabs.indexWhere((t) => t.path == location);
    if (currentIndex < 0) currentIndex = 0;

    return Scaffold(
      body: child,
      // Cart FAB — shown when items in cart and not on cart/checkout pages
      floatingActionButton: cartCount > 0 &&
              location != '/cart' &&
              location != '/checkout'
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              elevation: 4,
              extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 22),
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          cartCount > 9 ? '9+' : '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              label: Text(
                l10n.navViewCart,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(tabs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavTab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavTab({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

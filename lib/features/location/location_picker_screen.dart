import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/providers/app_providers.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';

/// Shown after splash validation when the subscriber has multiple
/// ordering-enabled branches. The customer picks once; the choice is
/// persisted and used on every subsequent API call.
class LocationPickerScreen extends ConsumerWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationsProvider);
    final brand = ref.watch(brandProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: locState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorBody(onRetry: () {
            ref.read(locationsProvider.notifier).load();
          }),
          data: (locations) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Choose a location',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select the branch you want to order from.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: locations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _LocationTile(
                    location: locations[i],
                    onTap: () => _select(context, ref, locations[i]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, WidgetRef ref, StoreLocation loc) {
    ref.read(selectedLocationIdProvider.notifier).select(loc.id);

    final brand = ref.read(brandProvider);
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (brand.features.customerAuth && !isLoggedIn) {
      context.go('/login');
    } else {
      context.go('/');
    }
  }
}

class _LocationTile extends StatelessWidget {
  final StoreLocation location;
  final VoidCallback onTap;

  const _LocationTile({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (location.address != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatAddress(location.address),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAddress(dynamic address) {
    if (address is String) return address;
    if (address is Map) {
      final parts = [
        address['street'],
        address['city'],
        address['state'],
      ].whereType<String>().where((s) => s.isNotEmpty).toList();
      return parts.join(', ');
    }
    return '';
  }
}

class _ErrorBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined,
                size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Could not load locations',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Check your connection and try again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

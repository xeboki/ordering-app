import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/providers/auth_providers.dart';
import 'package:xeboki_ordering/providers/orders_providers.dart';
import 'package:xeboki_ordering/widgets/error_view.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(ordersProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final theme = Theme.of(context);

    if (!isLoggedIn) {
      return _guestView(context, l10n, theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.ordersTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: l10n.ordersFailed,
          onRetry: () => ref.read(ordersProvider.notifier).refresh(),
        ),
        data: (orders) {
          final active =
              orders.where((o) => o.isActive).toList();
          final past =
              orders.where((o) => !o.isActive).toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _OrderList(
                orders: active,
                emptyIcon: Icons.hourglass_empty_outlined,
                emptyTitle: 'No active orders',
                emptySubtitle: 'Orders in progress will appear here',
                isActive: true,
                l10n: l10n,
                onRefresh: () =>
                    ref.read(ordersProvider.notifier).refresh(),
              ),
              _OrderList(
                orders: past,
                emptyIcon: Icons.receipt_long_outlined,
                emptyTitle: l10n.ordersEmpty,
                emptySubtitle: l10n.ordersEmptyHint,
                isActive: false,
                l10n: l10n,
                onRefresh: () =>
                    ref.read(ordersProvider.notifier).refresh(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _guestView(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.ordersTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 44, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(l10n.ordersSignInRequired,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Sign in to view your order history and track active orders',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.commonSignIn,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderingOrder> orders;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final bool isActive;
  final AppLocalizations l10n;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.isActive,
    required this.l10n,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon,
                    size: 38,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Text(emptyTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(emptySubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _OrderCard(order: orders[i], l10n: l10n, isActive: isActive),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderingOrder order;
  final AppLocalizations l10n;
  final bool isActive;
  const _OrderCard(
      {required this.order, required this.l10n, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final dateFmt = DateFormat('MMM d · h:mm a');

    return InkWell(
      onTap: () => context.push('/orders/${order.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant,
              width: isActive ? 1.5 : 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderNumber}',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFmt.format(order.createdAt.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: order.status, l10n: l10n),
                ],
              ),
              const SizedBox(height: 12),
              // Items preview
              Text(
                order.items
                    .map((i) => '${i.quantity}× ${i.productName}')
                    .join('  ·  '),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel(order.orderType, l10n),
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fmt.format(order.total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (order.isActive) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/track/${order.id}'),
                        icon: const Icon(Icons.my_location, size: 16),
                        label: Text(l10n.ordersTrack),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          side: BorderSide(
                              color: theme.colorScheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type, AppLocalizations l10n) => switch (type) {
        'pickup' => l10n.orderTypePickup,
        'delivery' => l10n.orderTypeDelivery,
        'dine_in' => l10n.orderTypeDineIn,
        'takeaway' => l10n.orderTypeTakeaway,
        _ => type,
      };
}

class _StatusChip extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _StatusChip({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'pending' => (l10n.statusPending, theme.colorScheme.secondary),
      'confirmed' => (l10n.statusConfirmed, Colors.blue),
      'processing' => (l10n.statusProcessing, Colors.orange),
      'ready' => (l10n.statusReady, const Color(0xFF27AE60)),
      'completed' => (l10n.statusCompleted, theme.colorScheme.primary),
      'cancelled' => (l10n.statusCancelled, theme.colorScheme.error),
      _ => (status, theme.colorScheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

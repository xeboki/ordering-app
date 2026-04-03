import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/core/services/firestore_service.dart';
import 'package:xeboki_ordering/core/types.dart';
import 'package:xeboki_ordering/features/order_tracking/widgets/delivery_map.dart';
import 'package:xeboki_ordering/providers/delivery_tracking_providers.dart';
import 'package:xeboki_ordering/providers/orders_providers.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  /// REST polling fallback — only active when Firestore stream is unavailable.
  Timer? _pollTimer;
  late final AnimationController _pulseCtrl;

  bool get _useFirestore => FirestoreService.instance.isInitialised;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Only poll when Firestore stream isn't available
    if (!_useFirestore) {
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        ref.invalidate(orderDetailProvider(widget.orderId));
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // ── Live Firestore path ──────────────────────────────────────────────────
    if (_useFirestore) {
      final liveAsync = ref.watch(orderLiveProvider(widget.orderId));

      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: _appBar(l10n, theme, onRefresh: null), // no manual refresh needed
        body: liveAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.orderDetailCouldNotLoad)),
          data: (order) {
            if (order == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _TrackingBody(
              order: order,
              l10n: l10n,
              pulseCtrl: _pulseCtrl,
            );
          },
        ),
      );
    }

    // ── REST polling fallback ────────────────────────────────────────────────
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _appBar(l10n, theme,
          onRefresh: () => ref.invalidate(orderDetailProvider(widget.orderId))),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.orderDetailCouldNotLoad)),
        data: (order) => _TrackingBody(
          order: order,
          l10n: l10n,
          pulseCtrl: _pulseCtrl,
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(
    AppLocalizations l10n,
    ThemeData theme, {
    required VoidCallback? onRefresh,
  }) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(l10n.trackingTitle,
          style: const TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
      ],
    );
  }
}

class _TrackingBody extends ConsumerWidget {
  final OrderingOrder order;
  final AppLocalizations l10n;
  final AnimationController pulseCtrl;

  const _TrackingBody({
    required this.order,
    required this.l10n,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('MMM d · h:mm a');

    // Nash tracking — only relevant for delivery orders
    final nashAsync = order.orderType == 'delivery'
        ? ref.watch(deliveryTrackingProvider(order.id))
        : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status hero ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _statusColor(order.status, theme).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                // Pulsing status icon
                AnimatedBuilder(
                  animation: pulseCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: order.isActive
                        ? 0.96 + pulseCtrl.value * 0.04
                        : 1.0,
                    child: child,
                  ),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: _statusColor(order.status, theme)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(order.status),
                      size: 44,
                      color: _statusColor(order.status, theme),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusLabel(order.status, l10n),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order #${order.orderNumber}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
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

          // ── Nash delivery map (delivery orders only) ──────────────────
          if (nashAsync != null)
            nashAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (tracking) {
                if (tracking == null || !tracking.isActive) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: DeliveryMap(tracking: tracking),
                );
              },
            ),

          // ── Progress timeline ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: order.isCancelled
                ? _CancelledBanner(theme: theme, l10n: l10n)
                : _StatusTimeline(order: order, l10n: l10n),
          ),
          const SizedBox(height: 24),

          // ── Order items ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.outlineVariant, width: 0.8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.trackingYourOrder,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${item.quantity}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(item.productName,
                                      style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── CTAs ─────────────────────────────────────────────────────────
          if (order.isCompleted || order.isCancelled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => context.go('/orders'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(l10n.trackingViewAll,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.go('/'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(l10n.trackingContinueShopping),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status, ThemeData theme) => switch (status) {
        'pending' => theme.colorScheme.secondary,
        'confirmed' => Colors.blue,
        'processing' => Colors.orange,
        'ready' => const Color(0xFF27AE60),
        'completed' => theme.colorScheme.primary,
        'cancelled' => theme.colorScheme.error,
        _ => theme.colorScheme.outline,
      };

  IconData _statusIcon(String status) => switch (status) {
        'pending' => Icons.access_time_outlined,
        'confirmed' => Icons.check_circle_outline,
        'processing' => Icons.restaurant_outlined,
        'ready' => Icons.done_all,
        'completed' => Icons.celebration_outlined,
        'cancelled' => Icons.cancel_outlined,
        _ => Icons.info_outline,
      };

  String _statusLabel(String status, AppLocalizations l10n) => switch (status) {
        'pending' => l10n.statusPending,
        'confirmed' => l10n.statusConfirmed,
        'processing' => l10n.statusProcessing,
        'ready' => l10n.statusReady,
        'completed' => l10n.statusCompleted,
        'cancelled' => l10n.statusCancelled,
        _ => status,
      };
}

class _CancelledBanner extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations l10n;
  const _CancelledBanner({required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined,
              color: theme.colorScheme.onErrorContainer, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.trackingCancelled,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final OrderingOrder order;
  final AppLocalizations l10n;
  const _StatusTimeline({required this.order, required this.l10n});

  int get _currentIdx {
    const statuses = [
      'pending',
      'confirmed',
      'processing',
      'ready',
      'completed'
    ];
    for (int i = statuses.length - 1; i >= 0; i--) {
      if (statuses[i] == order.status) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentIdx = _currentIdx;
    final steps = [
      (l10n.statusPending, Icons.receipt_outlined, 'Order placed'),
      (l10n.statusConfirmed, Icons.check_outlined, 'Confirmed'),
      (l10n.statusProcessing, Icons.restaurant_outlined, 'Being prepared'),
      (l10n.statusReady, Icons.done_all_outlined, 'Ready for pickup'),
      (l10n.statusCompleted, Icons.celebration_outlined, 'Delivered'),
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final (label, icon, subtitle) = steps[i];
        final isDone = i <= currentIdx;
        final isCurrent = i == currentIdx;
        final isLast = i == steps.length - 1;

        final nodeColor = isDone
            ? isCurrent
                ? theme.colorScheme.primary
                : const Color(0xFF27AE60)
            : theme.colorScheme.surfaceContainerHighest;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Node + connector
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nodeColor,
                      border: isDone
                          ? null
                          : Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 1.5),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isDone
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: i < currentIdx
                          ? const Color(0xFF27AE60)
                          : theme.colorScheme.outlineVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    top: 8, bottom: isLast ? 0 : 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isDone
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

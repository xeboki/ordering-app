import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xeboki_ordering/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xeboki_ordering/core/config/brand_config.dart';
import 'package:xeboki_ordering/providers/orders_providers.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final theme = Theme.of(context);
    final currency = BrandConfig.instance.store.currencySymbol;
    final fmt = NumberFormat.currency(symbol: currency, decimalDigits: 2);
    final dateFmt = DateFormat('MMMM d, y · h:mm a');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(l10n.orderDetailTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 56, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(l10n.orderDetailCouldNotLoad,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Receipt-style header ─────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant, width: 0.8),
                ),
                child: Column(
                  children: [
                    // Status banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status, theme)
                            .withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(_statusIcon(order.status),
                              size: 20,
                              color: _statusColor(order.status, theme)),
                          const SizedBox(width: 8),
                          Text(
                            _statusLabel(order.status, l10n),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _statusColor(order.status, theme),
                            ),
                          ),
                          const Spacer(),
                          _StatusBadge(status: order.status, l10n: l10n),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Order number — tappable to copy
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: order.orderNumber));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order number copied'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Text(
                                  '#${order.orderNumber}',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.copy_outlined,
                                    size: 14,
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFmt.format(order.createdAt.toLocal()),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _typeLabel(order.orderType, l10n),
                              style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Items receipt ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.orderDetailItems,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.w600)),
                                    if (item.modifierNames.isNotEmpty)
                                      Text(
                                        item.modifierNames.join(', '),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant),
                                      ),
                                    if (item.notes != null)
                                      Text(
                                        '📝 ${item.notes}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: theme.colorScheme
                                                    .onSurfaceVariant),
                                      ),
                                  ],
                                ),
                              ),
                              Text(fmt.format(item.totalPrice),
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(height: 16),
                    _TotalRow(
                        label: l10n.cartSubtotal,
                        value: fmt.format(order.subtotal),
                        theme: theme),
                    if (order.tax > 0) ...[
                      const SizedBox(height: 6),
                      _TotalRow(
                          label: BrandConfig.instance.store.taxLabel,
                          value: fmt.format(order.tax),
                          theme: theme),
                    ],
                    if (order.discount > 0) ...[
                      const SizedBox(height: 6),
                      _TotalRow(
                          label: l10n.cartDiscount,
                          value: '−${fmt.format(order.discount)}',
                          valueColor: const Color(0xFF27AE60),
                          theme: theme),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    _TotalRow(
                      label: l10n.cartTotal,
                      value: fmt.format(order.total),
                      bold: true,
                      theme: theme,
                    ),
                  ],
                ),
              ),

              // ── Notes ────────────────────────────────────────────────────
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant, width: 0.8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_outlined, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.orderDetailNotes,
                                style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text(order.notes!,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Track CTA ────────────────────────────────────────────────
              if (order.isActive) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.push('/track/${order.id}'),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(l10n.ordersTrack),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ],
          ),
        ),
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
        'processing' => Icons.restaurant_outlined,
        'ready' => Icons.done_all,
        'completed' => Icons.check_circle,
        'cancelled' => Icons.cancel_outlined,
        _ => Icons.receipt_outlined,
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

  String _typeLabel(String type, AppLocalizations l10n) => switch (type) {
        'pickup' => l10n.orderTypePickup,
        'delivery' => l10n.orderTypeDelivery,
        'dine_in' => l10n.orderTypeDineIn,
        'takeaway' => l10n.orderTypeTakeaway,
        _ => type,
      };
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final ThemeData theme;

  const _TotalRow({
    required this.label,
    required this.value,
    required this.theme,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value,
            style: style?.copyWith(
                color: bold
                    ? valueColor ?? theme.colorScheme.primary
                    : valueColor)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _StatusBadge({required this.status, required this.l10n});

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
        color: color.withValues(alpha: 0.15),
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
